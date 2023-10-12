package main

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

// OAuthRequest Flo PubGW Model
type OAuthRequest struct {
	ClientId     string `json:"client_id"`
	ClientSecret string `json:"client_secret"`
	GrantType    string `json:"grant_type"`
	RefreshToken string `json:"refresh_token,omitempty"`
	Code         string `json:"code,omitempty"`
	RedirectUri  string `json:"redirect_uri,omitempty"`
}

// OAuthResponse Flo PubGW Model
type OAuthResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresIn    int    `json:"expires_in"`
	TokenType    string `json:"token_type"`
	UserId       string `json:"user_id"`
}

// AuthRequestPayload Ring request model for: code grant & refresh
type AuthRequestPayload struct {
	ClientId          string `json:"clientId"`
	ClientSecret      string `json:"clientSecret"`
	RefreshToken      string `json:"refreshToken"`
	ResponseType      string `json:"responseType"`
	AuthorizationCode string `json:"authorizationCode"`
	RedirectUri       string `json:"redirectUri"`
}

// AuthResponsePayload Ring response model for: code grant & refresh
type AuthResponsePayload struct {
	Status            string `json:"status"`
	AccessToken       string `json:"accessToken"`
	ExpiresIn         int    `json:"expiresIn"`
	RefreshToken      string `json:"refreshToken"`
	AccountIdentifier string `json:"accountIdentifier,omitempty"`
}

// RevokeRequestPayload Ring model
type RevokeRequestPayload struct {
	ClientId     string `json:"clientId"`
	ClientSecret string `json:"clientSecret"`
	AccessToken  string `json:"accessToken"`
}

type GetProfileResponse struct {
	Email    string `json:"email"`
	FullName string `json:"fullName"`
	UserId   string `json:"userId"`
}

type accountSync struct {
	logger    *Logger
	pubGW     PublicGateway
	store     EntityStore
	ringEvt   RingQueue
	awsApiKey string
	devDisco  DeviceDiscovery
}

type AccountSync interface {
	AuthorizationCodeGrant(ctx context.Context, req *DirectiveMessage) (*EventMessage, error)
	RefreshToken(ctx context.Context, req *DirectiveMessage) (*EventMessage, error)
	RevokeAccess(ctx context.Context, req *DirectiveMessage) (*EventMessage, error)
	LinkUser(ctx context.Context, userId string) (*LinkOpsRes, error)
	UnLinkUser(ctx context.Context, userId, jwt string) (*LinkOpsRes, error)
	GetUserProfile(ctx context.Context, user *User, req *DirectiveMessage) *EventMessage
}

func CreateAccountSync(
	logger *Logger,
	pubGW PublicGateway,
	awsApiKey string,
	ringEvt RingQueue,
	store EntityStore,
	devDisco DeviceDiscovery) AccountSync {

	l := logger.CloneAsChild("accountSync")
	return &accountSync{
		logger:    l,
		pubGW:     pubGW,
		awsApiKey: awsApiKey,
		store:     store,
		ringEvt:   ringEvt,
		devDisco:  devDisco,
	}
}

func (a *accountSync) AuthorizationCodeGrant(ctx context.Context, req *DirectiveMessage) (*EventMessage, error) {
	var (
		res        *OAuthResponse
		reqPayload AuthRequestPayload
		err        = jsonMap(req.Directive.Payload, &reqPayload)
	)
	if err != nil {
		return nil, err
	}

	authGrantReq := OAuthRequest{
		ClientId:     reqPayload.ClientId,
		ClientSecret: reqPayload.ClientSecret,
		GrantType:    "authorization_code",
		Code:         reqPayload.AuthorizationCode,
		RedirectUri:  reqPayload.RedirectUri,
	}
	if res, err = a.pubGW.OAuth2(&authGrantReq); err != nil {
		return nil, err
	} else if err = a.store.StoreUser(ctx, res.UserId); err != nil {
		return nil, err
	}

	p := &AuthResponsePayload{
		Status:            "Success",
		AccessToken:       res.AccessToken,
		ExpiresIn:         res.ExpiresIn,
		RefreshToken:      res.RefreshToken,
		AccountIdentifier: res.UserId,
	}
	evt := req.toEvent(p)
	a.logger.Debug("AuthorizationCodeGrant: OK for userId %v", res.UserId)
	return evt, nil
}

func (a *accountSync) LinkUser(ctx context.Context, userId string) (*LinkOpsRes, error) {
	var (
		locs []*Location
		err  error
	)
	if locs, err = a.pubGW.UserLocations(userId, ""); err != nil {
		return nil, a.logger.IfErrorF(err, "UserLocations: %v", userId)
	} else if err = a.store.StoreUser(ctx, userId); err != nil {
		return nil, a.logger.IfErrorF(err, "StoreUser: %v", userId)
	}

	var (
		res     = LinkOpsRes{userId, make([]string, 0)}
		devices = make([]*Device, 0)
	)
	for _, l := range locs {
		for _, d := range l.Devices {
			if isDeviceTypeDiscoverable(d.DeviceType) {
				devices = append(devices, d)
				res.DeviceIds = append(res.DeviceIds, d.Id)
			}
		}
	}
	if err = a.store.StoreDevices(ctx, devices...); err != nil {
		return nil, a.logger.IfErrorF(err, "StoreDevices: for user %v", userId)
	}
	return &res, nil
}

type JwtRefresh struct {
	ClientId  string      `json:"client_id"`
	UserId    string      `json:"user_id"`
	IssuedAt  int64       `json:"iat"`
	ExpiresAt int64       `json:"exp"`
	Version   interface{} `json:"v"`
	TokenId   string      `json:"jti"`
}

func (rf *JwtRefresh) Expires() time.Time {
	return time.Unix(rf.ExpiresAt, 0).UTC()
}

func (rf *JwtRefresh) Issued() time.Time {
	return time.Unix(rf.IssuedAt, 0).UTC()
}

func (rf *JwtRefresh) VersionString() string {
	return fmt.Sprint(rf.Version)
}

func (a *accountSync) decodeRefreshToken(jwt string) (res *JwtRefresh, e error) {
	var tk *JwtDef
	if tk, e = JwtDecode(jwt); tk != nil && len(tk.Body) != 0 {
		rf := JwtRefresh{}
		if e = jsonMap(tk.Body, &rf); e == nil {
			res = &rf
		}
	}
	return
}

func (a *accountSync) RefreshToken(ctx context.Context, req *DirectiveMessage) (*EventMessage, error) {
	var (
		res        *OAuthResponse
		reqPayload AuthRequestPayload
	)
	err := jsonMap(req.Directive.Payload, &reqPayload)
	if err != nil {
		return nil, err
	}

	refreshTokenReq := OAuthRequest{
		ClientId:     reqPayload.ClientId,
		ClientSecret: reqPayload.ClientSecret,
		GrantType:    "refresh_token",
		RefreshToken: reqPayload.RefreshToken,
	}
	if res, err = a.pubGW.OAuth2(&refreshTokenReq); err != nil {
		if rf, tkErr := a.decodeRefreshToken(reqPayload.RefreshToken); tkErr != nil {
			a.logger.IfErrorF(err, "RefreshToken: decode failure %v", tkErr)
		} else if rf != nil && rf.UserId != "" { //log user id on err
			var (
				note   = "failed"
				exp    = rf.Expires()
				errMsg = strings.ToLower(err.Error())
			)
			if exp.After(time.Now().UTC()) && strings.Contains(errMsg, "token expired") {
				note = "BUG4561" //SEE: https://flotechnologies-jira.atlassian.net/browse/CLOUD-4561
			}
			a.logger.IfWarnF(err, "RefreshToken: %v for userId %v | jti %v | exp %v", note, rf.UserId, rf.TokenId, exp)
		}
		return nil, err
	}
	var (
		p = &AuthResponsePayload{
			Status:       "Success",
			AccessToken:  res.AccessToken,
			ExpiresIn:    res.ExpiresIn,
			RefreshToken: res.RefreshToken,
		}
		evt = req.toEvent(p)
		jti string
	)
	if rf, _ := a.decodeRefreshToken(reqPayload.RefreshToken); rf != nil {
		jti = rf.TokenId
	}
	a.logger.Debug("RefreshToken: OK for userId %v | jti %v", res.UserId, jti)
	return evt, nil
}

func (a *accountSync) RevokeAccess(ctx context.Context, req *DirectiveMessage) (*EventMessage, error) {
	var (
		payload RevokeRequestPayload
		err     = jsonMap(req.Directive.Payload, &payload)
		jwt     = payload.AccessToken
		usr     *User
	)
	if err != nil {
		return nil, err
	}
	if strings.Index(jwt, "Bearer") != 0 {
		jwt = "Bearer " + jwt
	}

	if usr, err = a.pubGW.GetUserFromToken(jwt); err != nil {
		return nil, err
	} else if _, err = a.UnLinkUser(ctx, usr.Id, jwt); err != nil {
		return nil, err
	} else if err = a.pubGW.LogoutFromToken(jwt); err != nil {
		return nil, err
	} else { //TODO: validate client_id & client_secret from input
		var (
			res = map[string]interface{}{"status": "Success"}
			evt = req.toEvent(res)
		)
		a.logger.Notice("RevokeAccess: OK for user %v | msgId %v", usr.Id, req.Directive.Header.MessageId)
		return evt, nil
	}
}

func (a *accountSync) GetUserProfile(ctx context.Context, user *User, req *DirectiveMessage) *EventMessage {
	p := GetProfileResponse{
		UserId:   user.Email,
		Email:    user.Email,
		FullName: user.FirstName + " " + user.LastName,
	}
	return req.toEvent(p)
}

type LinkOpsRes struct {
	UserId    string   `json:"userId"`
	DeviceIds []string `json:"deviceIds"`
}

func (ul LinkOpsRes) String() string {
	return tryToJson(ul)
}

func (a *accountSync) isAnyUserIntegratedWithRing(ctx context.Context, users []*User, exceptId string) bool {
	for _, u := range users {
		if strings.EqualFold(exceptId, u.Id) {
			continue
		} else if exists, err := a.store.UserExists(ctx, u.Id); err != nil {
			a.logger.Warn("isAnyUserIntegratedWithRing: error checking user %s - %v", u.Id, err)
		} else if exists {
			return true
		}
	}
	return false
}

func (a *accountSync) canUnlinkRmLoc(l *Location, userId string) bool {
	uLen := len(l.Users)
	return uLen == 0 ||
		(uLen == 1 && strings.EqualFold(l.Users[0].Id, userId))
}

func (a *accountSync) canUnlinkRmLocDevices(ctx context.Context, l *Location, userId string) bool {
	return a.canUnlinkRmLoc(l, userId) || !a.isAnyUserIntegratedWithRing(ctx, l.Users, userId)
}

func (a *accountSync) UnLinkUser(ctx context.Context, userId, jwt string) (*LinkOpsRes, error) {
	a.logger.PushScope("UnLinkUser", userId)
	defer a.logger.PopScope()

	if len(userId) != 36 {
		return nil, &HttpErr{400, "userId is invalid or missing", nil}
	} else if locs, e := a.pubGW.UserLocations(userId, jwt); e != nil {
		a.logger.IfErrorF(e, "pubGW.UserLocations")
		return nil, e
	} else if e := a.store.DeleteUser(ctx, userId); e != nil {
		a.logger.IfErrorF(e, "DeleteUser")
		return nil, e
	} else {
		defer a.notifyUsrUnLink(ctx, userId) //do this last
		var (
			es  = make([]error, 0)
			res = LinkOpsRes{UserId: userId, DeviceIds: make([]string, 0)}
		)
		for _, l := range locs {
			if a.canUnlinkRmLocDevices(ctx, l, userId) {
				for _, d := range l.Devices {
					if !isDeviceTypeDiscoverable(d.DeviceType) {
						continue
					} else if msg, err := a.devDisco.BuildDeleteReportForDevice(ctx, d); err != nil {
						a.logger.IfWarnF(e, "BuildDeleteReportForDevice: %v", d.Id)
						es = append(es, e)
					} else if msg != nil {
						res.DeviceIds = append(res.DeviceIds, d.Id)
						a.logger.Debug("QUEUED rm userId %v device %v", userId, d.Id)
						a.ringEvt.Put(ctx, msg)
					}
				}
			}
		}
		//NOTE: at this point, we're still going to send the done signal anyway, can't back out
		if len(es) != 0 {
			a.logger.Error("Done with Errors. Removed devices %v | %v", res.DeviceIds, wrapErrors(es))
		} else {
			a.logger.Notice("Done. Removed %v", res)
		}
		return &res, nil
	}
}

func (a *accountSync) notifyUsrUnLink(ctx context.Context, userId string) {
	defer panicRecover(a.logger, "notifyUsrUnLink: uid %v devices %v", userId)
	em := EventMessage{
		Event: Event{
			Header: Header{
				MessageId:      strings.ReplaceAll(uuid.New().String(), "-", ""),
				Namespace:      "Alexa.Authorization",
				Name:           "DeregistrationReport",
				PayloadVersion: "3",
			},
			Payload: DeregistrationReport{
				AccountId: userId,
				Scope:     Scope{Type: "ApiKey", ApiKey: a.awsApiKey},
			},
		},
	}
	a.logger.Debug("notifyUsrUnLink: QUEUED userId %v", userId)
	a.ringEvt.Put(ctx, &em)
}

type DeregistrationReport struct {
	AccountId string `json:"accountIdentifier"`
	Scope     Scope  `json:"scope"`
}
