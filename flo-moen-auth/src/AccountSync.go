package main

import (
	"context"
	"fmt"
	"sort"
	"strings"
	"time"
)

// AccountSync high level service that orchestrate how to fetch and store account sync info
type AccountSync interface {
	IsSync(ctx context.Context, usr *MoenUser) (SyncState, error)
	GetFloUser(ctx context.Context, usr *MoenUser) (*AccountState, error)
	GetSyncData(ctx context.Context, look *SyncLookup) (*SyncDataRes, error)
	RegisterUser(ctx context.Context, usr *MoenUser, op *newUserOption) (*RegistrationResult, error)
	LinkUser(ctx context.Context, moen *MoenUser) (*FloUser, error)
	LinkAuthorized(ctx context.Context, moe *MoenUser, floEmail, floPwd string) (*FloUser, error)
	UnLinkUser(ctx context.Context, moe *MoenUser, forced bool, deleteFloAccount bool) error
	UserCacheClean(ev *LinkEvent)
	OnFloUserRemoved(ctx context.Context, usr *FloEntity) error
	OnFloLocRemoved(ctx context.Context, loc *FloEntity) error
	UnLinkLocation(ctx context.Context, match *getLocMatch) (rems []*SyncLoc, e error)
	LinkLocation(ctx context.Context, req *locLinkReq) error
	//DeleteFloUser(floId string) error //NOTE: don't expose this!!
}

type accountSync struct {
	log      *Logger
	valid    *Validator
	pubGW    PublicGateway
	accStore SyncStore
	locStore LocationStore
	cache    map[string]interface{} //local instance cache, not a singleton, no need to pop
	kafConn  *KafkaConnection
	kafTopic string
	onUnLink func(moe *MoenUser)

	skipUnlinkCheck bool
}

func CreateAccountSync(
	log *Logger,
	valid *Validator,
	pgw PublicGateway,
	accStore SyncStore,
	locStore LocationStore,
	kafConn *KafkaConnection,
	onUnLink func(moe *MoenUser)) AccountSync {

	return &accountSync{
		log:      log.CloneAsChild("sync"),
		valid:    valid,
		pubGW:    pgw,
		accStore: accStore,
		locStore: locStore,
		cache:    make(map[string]interface{}),
		onUnLink: onUnLink,
		kafConn:  kafConn,
		kafTopic: getEnvOrDefault("FLO_KAFKA_TOPIC_ACTIVITIES", TOPIC_ACTIVITIES),

		skipUnlinkCheck: !strings.EqualFold(getEnvOrDefault("FLO_SKIP_UNLINK_MULTI_USER_CHECK", ""), "false"),
	}
}

// Checks for Moen-Flo link record in database
func (a *accountSync) IsSync(ctx context.Context, usr *MoenUser) (SyncState, error) {
	a.log.PushScope("sync?")
	defer a.log.PopScope()

	if e := a.valid.Value(usr.Email, VALID_EMAIL); e != nil {
		return SYNC_ERROR, a.log.IfWarnF(e, "Invalid Email")
	} else if found, er := a.getMapWithRepair(ctx, usr.Id, usr.Issuer); found != nil && found.FloId != "" && found.Issuer != "" {
		return SYNC_EXISTS, nil // db link record exists
	} else if er == nil { //404 or 409
		var ok *FloEmailExists
		// Get status of isRegistered and isPending from flo-api register endpoint
		if ok, er = a.canRegister(ctx, usr); er != nil { //500
			return SYNC_ERROR, er
		} else if ok != nil && ok.Registered { //409
			// ok.Registered = Has User and UserDetail records
			// ok.Pending = Just means its a recent registration
			if !ok.Pending {
				a.log.Notice("Possible missing entry in cognito_user table")
			} else {
				if si, _ := a.matchFirstEmail(ctx, usr); si != nil && si.Id != "" {
					a.log.Notice("Pending userId %v, accountId %v, email: %v", si.Id, si.Account.AccountId, usr.Email)
				}
			}
			return SYNC_INCOMPLETE, nil //NOTE: Ignore Pending to repair cognito_user table
		} else { //404
			return SYNC_MISSING, nil
		}
	} else { //500 type errors
		return SYNC_ERROR, er
	}
}

func (a *accountSync) GetSyncData(ctx context.Context, look *SyncLookup) (*SyncDataRes, error) {
	if look == nil || (look.FloId == "" && look.MoenId == "") {
		return nil, &HttpErr{400, "moenId or floId is required", false, nil}
	} else {
		acc, e := a.accStore.GetMap(ctx, look.MoenId, look.FloId, look.Issuer)
		if e == nil && acc.NeedFloAccIdRepair() { //need flo accountId repaired
			go a.floAccIdRepair(ctx, acc)
		}
		return acc.AsSyncDataRes(), nil
	}
}

func (a *accountSync) floAccIdRepair(ctx context.Context, acc *AccountMap) {
	defer panicRecover(a.log, "floAccIdRepair: %v", acc)
	if acc != nil && acc.FloId != "" {
		k := "accIdRepair:" + acc.FloId
		if _, working := a.cache[k]; working {
			return //do nothing, repair kicked off in the same session already
		}
		a.cache[k] = true
		if usr, _ := a.pubGW.GetUser(ctx, acc.FloId, ""); usr != nil && usr.AccountId() != "" {
			cp := *acc
			cp.FloAccountId = usr.AccountId()
			if e := a.accStore.Save(ctx, &cp); e != nil {
				a.log.IfWarnF(e, "floAccIdRepair: %v", acc)
			} else {
				a.log.Info("floAccIdRepair: OK %v", acc)
			}
		}
	}
}

func (a *accountSync) getMapWithRepair(ctx context.Context, moenId, moenIssuer string) (res *AccountMap, e error) {
	if res, e = a.accStore.GetMap(ctx, moenId, "", moenIssuer); e == nil && res.NeedFloAccIdRepair() {
		go a.floAccIdRepair(ctx, res)
	}
	return
}

func (a *accountSync) canRegister(ctx context.Context, usr *MoenUser) (*FloEmailExists, error) {
	k := "chk:" + usr.Email
	if item, ok := a.cache[k]; ok { //cache found
		if item == nil {
			return nil, nil //return cached empty fetch
		}
		return item.(*FloEmailExists), nil //return from cache
	}
	ok, e := a.pubGW.RegistrationExists(ctx, usr.Email)
	a.cache[k] = ok //store in cache
	return ok, e
}

func (a *accountSync) searchScore(o *SearchItem) float64 {
	var s float64 = 0
	if o == nil || o.Id == "" || o.Email == "" {
		return s
	}
	if o.Phone != "" {
		s += 0.5
	}
	if o.IsActive {
		s += 2
	}
	if o.FirstName != "" {
		s += 0.25
	}
	if o.LastName != "" {
		s += 0.25
	}
	if ll := len(o.Locations); ll > 0 {
		s += float64(ll) * 0.5
	}
	if dl := len(o.Devices); dl > 0 {
		s += float64(dl) * 0.25
	}
	if o.Account.AccountId != "" {
		s += 1
	}
	return s
}

// match email with local cache
func (a *accountSync) matchFirstEmail(ctx context.Context, usr *MoenUser) (sr *SearchItem, er error) {
	k := "email:" + usr.Email
	if item, ok := a.cache[k]; ok { //cache found
		if item == nil {
			return nil, nil //return cached empty fetch
		}
		return item.(*SearchItem), nil //return from local cache
	}
	sc := SearchCriteria{Query: usr.Email, Size: 10} //fetch from store
	if res, e := a.pubGW.Search(ctx, sc.Normalize()); e != nil {
		er = e
	} else {
		if res.Total > 1 {
			idArr := make([]string, 0, res.Total)
			for _, item := range res.Items {
				idArr = append(idArr, item.Id)
			}
			a.log.Notice("matchFirstEmail: %v found %v | possible registration conflict %v", sc.Query, res.Total, idArr)

			sort.Slice(res.Items, func(i, j int) bool { //sort by completeness weight
				x, y := a.searchScore(res.Items[i]), a.searchScore(res.Items[j])
				return x > y //sort descending, higher score on top
			})
		}
		for _, item := range res.Items {
			if strings.EqualFold(strings.TrimSpace(item.Email), usr.Email) {
				sr = item
				break
			}
		}
	}
	a.cache[k] = sr //set local cache
	return
}

// get flo user with local cache
func (a *accountSync) getUser(ctx context.Context, floId, jwt string) (*FloUser, error) {
	k := "usr:" + floId
	if item, ok := a.cache[k]; ok { //found in cache
		if item == nil {
			return nil, nil //return cached empty resp
		}
		return item.(*FloUser), nil
	}
	usr, e := a.pubGW.GetUser(ctx, floId, jwt)
	a.cache[k] = usr //store in local cache
	return usr, e
}

func (a *accountSync) unLnkRepair(ctx context.Context, moe *MoenUser) {
	//TODO: ensure user & account delete is creating user deleted entity message in Kafka
	defer panicRecover(a.log, "unLnkRepair: %v", moe.Id)
	a.log.Notice("attempting unlink repair %v", moe.Id)
	a.UnLinkUser(ctx, moe, true, false)
}

func (a *accountSync) GetFloUser(ctx context.Context, usr *MoenUser) (*AccountState, error) {
	a.log.PushScope("GetUsr")
	defer a.log.PopScope()

	var (
		state, e = a.IsSync(ctx, usr)
		ar       = AccountState{State: state}
	)
	switch state {
	case SYNC_EXISTS: //pull by id
		var acc *AccountMap
		if acc, e = a.getMapWithRepair(ctx, usr.Id, usr.Issuer); e == nil {
			if acc.MoenId != "" && (acc.FloId == "" || acc.Issuer == "") {
				ar.State = SYNC_MISSING
				a.log.Warn("LEGACY_SYNC - account is pre issuer type, removing", acc)
				go a.unLnkRepair(ctx, usr)
				break
			}
			var res *FloUser
			if res, e = a.getUser(ctx, acc.FloId, ""); e != nil { //should never happen unless user is removed!
				switch et := e.(type) {
				case *HttpErr:
					if et.Code == 404 && et.Message == "Not found." { //user is synced but account is not found in pubGW :. assume user is removed
						ar.State = SYNC_MISSING
						go a.unLnkRepair(ctx, usr)
					}
				}
				a.log.IfWarnF(e, "LINK_CONFLICT - account is synced but getUser failed for %v", acc)
			} else {
				ar.User = res
			}
		}
	case SYNC_INCOMPLETE: //pull via search
		var item *SearchItem
		if item, e = a.matchFirstEmail(ctx, usr); e == nil && item != nil && item.Id != "" {
			ar.User = item.toFloUser() //search type adaptor
		}
	case SYNC_MISSING, SYNC_ERROR: //404 resp or 500
		//do nothing on purpose
	default: //500 unknown err
		ar.State = SYNC_UNKNOWN
		if e == nil {
			e = a.log.Error("Unknown Failure")
		}
	}
	return &ar, e
}

func (a *accountSync) registerUsr(ctx context.Context, reg *FloRegistration) error {
	if e := a.pubGW.RegisterUser(ctx, reg); e != nil {
		switch et := e.(type) {
		case *HttpErr:
			if msg := strings.ToLower(et.Message); strings.Contains(msg, "pending registration") {
				a.log.Info("registration resume")
				return nil //allow resume
			}
		}
		return e
	}
	return nil
}

func (a *accountSync) ensureSyncMissing(ctx context.Context, usr *MoenUser) error {
	if state, e := a.IsSync(ctx, usr); e != nil {
		return e
	} else {
		switch state {
		case SYNC_EXISTS: //200 -> 409 Conflict
			// Moen user already has a link record in db so return a 409 conflict
			a.log.Notice("Deny sync: Moen user already linked")
			return &HttpErr{409, "Account Already Sync", false, nil}
		case SYNC_INCOMPLETE: // OK allow continuing
			// Moen user has _no_ link record in db so it can be linked
			// A Flo user with same email as Moen user exists
			a.log.Notice("Allow sync: Flo user with same email exists")
			return nil //Moen user still open for linking
		case SYNC_MISSING: // OK allow continuing
			// Moen user has _no_ link record in db so it can be linked
			// No Flo user has the same email as Moen user
			a.log.Debug("Allow sync: No matches")
			return nil //OK!
		default: //unhandled errors
			return a.log.Error("Account Sync Error")
		}
	}
}

func (a *accountSync) RegisterUser(ctx context.Context, usr *MoenUser, op *newUserOption) (res *RegistrationResult, er error) {
	a.log.PushScope("RegUsr", usr.Email)
	defer a.log.PopScope()
	// Ensure Moen user is not already linked
	if e := a.ensureSyncMissing(ctx, usr); e != nil {
		return nil, e
	}
	var (
		reg   = op.toFloRegistration(usr).Normalize().SetRandomPassword()
		token = ""      //single use registration validation token
		tk    *FloToken //flo JWT
		fu    *FloUser
	)
	if e := a.valid.Struct(reg); e != nil {
		a.log.IfWarnF(e, "validate %v", reg)
		er = &HttpErr{400, e.Error(), false, e}
	} else if er = a.registerUsr(ctx, reg); er != nil { //use our own version of reg to allow resume
		a.log.IfErrorF(er, "register %v", reg)
	} else if token, er = a.pubGW.RegistrationToken(ctx, reg.Email); er != nil {
		a.log.IfErrorF(er, "registration token %v", reg)
	} else if tk, er = a.pubGW.RegistrationConfirm(ctx, token); er != nil {
		a.log.IfErrorF(er, "confirm %v", reg)
	} else if fu, er = a.getUser(ctx, tk.UserId, tk.Bearer().AccessTokenValue()); er != nil {
		a.log.IfErrorF(er, "fetch uid=%s %v", tk.UserId, reg)
	} else if er = a.accStore.Save(ctx, usr.asAccountMap(fu)); er != nil {
		a.log.IfErrorF(er, "store %v", reg)
	} else {
		a.log.Info("Sync OK %v", usr)
		res = &RegistrationResult{fu, tk}
		go a.notifyAccAction(ctx, usr, "linked", fu.Id) //publish user unlinked action to Kafka topic entity-activity-v1
	}
	return
}

func (a *accountSync) LinkUser(ctx context.Context, moe *MoenUser) (*FloUser, error) {
	a.log.PushScope("LnkUsr", moe.Email, moe.Id)
	defer a.log.PopScope()

	if acc, e := a.GetFloUser(ctx, moe); e != nil {
		return nil, e
	} else {
		switch acc.State {
		case SYNC_INCOMPLETE: //not yet sync, do the work
			ac := moe.asAccountMap(acc.User)
			if e = a.accStore.Save(ctx, ac); e != nil {
				a.log.IfErrorF(e, "Save Failed")
				return nil, e //sync failed!
			} else {
				go a.notifyAccAction(ctx, moe, "linked", acc.User.Id) //publish user linked action to Kafka topic entity-activity-v1
				return acc.User, nil                                  //sync OK
			}
		case SYNC_EXISTS: //no err, already sync
			return acc.User, nil
		case SYNC_MISSING: //user doesn't exist, throw
			return nil, &HttpErr{404, "Email Not Found", false, nil}
		default: //unknown states, throw
			a.log.Error("Unknown State %v", acc.State)
			return nil, &HttpErr{500, "Unknown State", false, nil}
		}
	}
}

func (a *accountSync) LinkAuthorized(ctx context.Context, moe *MoenUser, floEmail, floPwd string) (*FloUser, error) {
	a.log.PushScope("LnkAuth", moe.Email, floEmail)
	defer a.log.PopScope()

	if strings.EqualFold(moe.Email, floEmail) {
		return nil, &HttpErr{400, "authorization email should not match token bearer", false, nil}
	}
	//SEE: TRIT-4344. Per my conversation with Alex L. We are removing the patch from TRIT-3788 since the original behavior was more correct
	//diffEmailSync := false //SEE: TRIT-3788 comments by Huy Nguyen
	// Ensure Moen user is not already linked
	if e := a.ensureSyncMissing(ctx, moe); e != nil {
		//if he, _ := e.(*HttpErr); he != nil && he.Code == 409 && strings.Contains(he.Message, "Account Already Exists") {
		//	//allow this case to reduce support call: user has multiple Flo accounts,
		//	//one of which with a Moen email that matches a Flo account; however,
		//	//user decides to link it to a different Flo account!
		//	diffEmailSync = true
		//} else {
		//	return nil, e
		//}
		return nil, e
	}

	var flo *FloUser
	if tk, e := a.pubGW.Login(ctx, floEmail, floPwd); e != nil {
		switch et := e.(type) {
		case *HttpErr:
			if et.Code < 500 {
				if et.Code == 400 && strings.Contains(strings.ToLower(et.Message), "invalid username/password") {
					et.Code = 401 //fix response per doc: https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/1360691201/Flo-Moen+OAuth+Cloud+Integration+Phase+I#401-Unauthorized.1
				}
				return nil, et
			}
		}
		a.log.IfErrorF(e, "Login failed")
		return nil, httpErrWrap(e, 500)
		//} else if e = a.canLinkUnmatchedEmail(!diffEmailSync, tk); e != nil {
	} else if e = a.canLinkUnmatchedEmail(ctx, false, tk, moe); e != nil { //SEE: TRIT-4344 notes above
		a.log.IfWarnF(e, "Link Unmatched Email Check Failed")
		return nil, e
	} else if flo, e = a.pubGW.GetUser(ctx, tk.UserId, tk.AccessTokenValue()); e != nil {
		a.log.IfWarnF(e, "Fetch user failed")
		return nil, e
	} else if e = a.accStore.Save(ctx, moe.asAccountMap(flo)); e != nil {
		a.log.IfErrorF(e, "Save Failed")
		return nil, e //sync failed!
	} else {
		go a.notifyAccAction(ctx, moe, "linked", flo.Id) //publish user unlinked action to Kafka topic entity-activity-v1
		return flo, nil                                  //sync OK
	}
}

func (a *accountSync) canLinkUnmatchedEmail(ctx context.Context, skip bool, tk *FloToken, moe *MoenUser) error {
	if !skip && tk != nil && tk.UserId != "" {
		if acc, e := a.accStore.GetMap(ctx, "", tk.UserId, ""); e != nil {
			return e
		} else if acc != nil && strings.EqualFold(acc.Issuer, moe.Issuer) && !strings.EqualFold(acc.MoenId, moe.Id) { //diff iss == diff env
			return &HttpErr{409, "Target Account Already Linked", false, nil}
		}
	}
	return nil //OK to link!
}

func (a *accountSync) canUnlink(moe *MoenUser, forced bool, accMap *AccountMap) bool {
	if moe == nil || moe.Id == "" || accMap == nil || accMap.MoenId == "" {
		return false
	}
	if !strings.EqualFold(accMap.MoenId, moe.Id) {
		return false
	}
	if forced {
		return true
	}
	return accMap.FloId != ""
}

func (a *accountSync) UnLinkUser(ctx context.Context, moe *MoenUser, forced bool, deleteFloAccount bool) error {
	a.log.PushScope("UnLinkUser", moe.Email, moe.Id)
	defer a.log.PopScope()

	if accMap, e := a.accStore.GetMap(ctx, moe.Id, "", moe.Issuer); e != nil { //no need to check Flo api
		return e
	} else if !a.canUnlink(moe, forced, accMap) { //409
		return &HttpErr{409, "Account Not Sync", false, nil}
	} else { //unlink
		moenId := accMap.MoenId
		if forced && moenId == "" {
			moenId = moe.Id
		}
		if e = a.accStore.Remove(ctx, moenId, accMap.FloId); e != nil { //point of no return if succeed
			a.log.IfErrorF(e, "Account Link Delete Failed")
		} else {
			a.log.Info("Account Link Delete OK")
			if accMap.MoenAccountId != "" || accMap.FloAccountId != "" {
				e = a.locCleanup(ctx, accMap, forced) //continue even if there's an error here
			} else {
				a.log.Notice("Can't locCleanup, no Flo or Moen account id!")
			}
			if a.onUnLink != nil { //execute if trigger is wired
				go func(u *MoenUser) {
					defer panicRecover(a.log, "onUnLink: %s", u.Email)
					a.onUnLink(u)
				}(moe)
			}
			if accMap.FloId != "" {
				go a.afterUnlink(ctx, moe, accMap.FloId, deleteFloAccount)
			}
		}
		return e
	}
}

func (a *accountSync) locCleanup(ctx context.Context, accMap *AccountMap, forced bool) (e error) {
	defer panicRecover(a.log, "locCleanup: %v forced=%v", accMap, forced)
	a.log.PushScope("locCleanup")
	defer a.log.PopScope()
	var (
		others []*AccountMap
		rems   []*SyncLoc
	)
	if !forced && !a.skipUnlinkCheck {
		if others, e = a.accStore.GetByAccount(ctx, accMap.MoenAccountId, accMap.FloAccountId, true); e != nil {
			a.log.IfWarnF(e, "GetByAccount Siblings Failed: moeAcc=%v floAcc=%v", accMap.MoenAccountId, accMap.FloAccountId)
			return
		} else if len(others) != 0 {
			return
		}
	}

	//remove all location attached to this account bc no other linked user attached to account
	if rems, e = a.locStore.Remove(ctx, &getLocMatch{FloAccId: accMap.FloAccountId}); e != nil {
		a.log.IfWarnF(e, "Remove Link Locations FAILED floAcc=%v", accMap.FloAccountId)
	} else {
		remLocs := make([]string, 0)
		for _, r := range rems {
			if r != nil {
				remLocs = append(remLocs, fmt.Sprintf("{flo:%q,moen:%q}", r.FloId, r.MoenId))
			}
		}
		a.log.Info("Remove Link Locations OK floAcc=%v count=%v | locs= %v", accMap.FloAccountId, len(rems), remLocs)
	}
	return
}

func (a *accountSync) afterUnlink(ctx context.Context, moe *MoenUser, floId string, deleteFloAccount bool) {
	defer panicRecover(a.log, "afterUnlink: [moe=%v flo=%v]", moe.Id, floId)

	a.notifyAccAction(ctx, moe, "unlinked", floId) //publish user unlinked action to Kafka topic entity-activity-v1
	if deleteFloAccount {
		if e := a.DeleteFloUser(ctx, floId); e != nil {
			a.log.IfErrorF(e, "afterUnlink: Delete User Failed")
		} else {
			a.log.Info("afterUnlink: DeleteFloUser: OK %v", floId)
		}
	}
}

func (a *accountSync) notifyAccAction(ctx context.Context, moe *MoenUser, action, floId string) { //unlink trigger used to pop in-mem cache
	defer panicRecover(a.log, "notifyAccAction: %v %v %v", action, moe.Id, floId)
	a.log.PushScope("notifyAccAction", action, moe.Email)
	defer a.log.PopScope()

	var floUser interface{} = FloEntity{Id: floId}
	if usr, e := a.getUser(ctx, floId, ""); e != nil { //use system jwt to fetch
		notFound := strings.Contains(strings.ToLower(e.Error()), "not found")
		if !notFound {
			switch et := e.(type) {
			case *HttpErr:
				notFound = et.Code == 404
			}
		}
		if notFound {
			a.log.Notice("getUser %s | %v", floId, e) //NOTE: flo user possibly removed, it's OK
		} else {
			a.log.IfWarnF(e, "getUser %s", floId)
		}
	} else if usr != nil && strings.EqualFold(usr.Id, floId) {
		floUser = *usr //swap local ref
	}
	evt := EntityEventEnvelope{
		Date:   PubGwTime(time.Now().UTC()),
		Type:   "user",
		Action: strings.ToLower(action),
		Item: LinkEvent{
			User: floUser,
			External: ExternalEntity{
				Vendor: "moen",
				Type:   "user",
				Id:     moe.Id,
				Entity: *moe,
			},
		},
	}

	if e := a.kafConn.Publish(ctx, a.kafTopic, evt, []byte(floId)); e != nil {
		a.log.IfWarnF(e, "publish FAILED to %v | %v", a.kafTopic, evt)
	} else {
		switch fu := floUser.(type) { //only if we are able to fetch the user
		case FloUser:
			a.notifyUserUpdated(ctx, &fu) //also publish standard user updated action to Kafka topic entity-activity-v1
		}
		a.log.Debug("publish OK to %v", a.kafTopic)
	}
}

func (a *accountSync) UserCacheClean(ev *LinkEvent) {
	if ev == nil {
		return
	}
	if cache, ok := a.accStore.(*syncStoreRam); ok && cache != nil {
		defer panicRecover(a.log, "UserCacheClean")
		var (
			moenId = ev.External.Id
			floId  string
		)
		if !strings.EqualFold(ev.External.Vendor, "moen") && !strings.EqualFold(ev.External.Type, "user") {
			moenId = ""
		}
		if ev.User != nil {
			ent := FloEntity{}
			if e := jsonMap(ev.User, &ent); e != nil {
				a.log.IfWarnF(e, "UserCacheClean: %v", tryToJson(ev))
				return
			} else {
				floId = ent.Id
			}
		}
		cache.Invalidate(moenId, floId)
		a.log.Debug("UserCacheClean: moe=%v flo=%v", moenId, floId)
	}
}

func (a *accountSync) notifyUserUpdated(ctx context.Context, flo *FloUser) {
	mod := EntityEventEnvelope{
		Date:   PubGwTime(time.Now().UTC()),
		Type:   "user",
		Action: "updated",
		Item:   *flo,
	}
	if e := a.kafConn.Publish(ctx, a.kafTopic, mod, []byte(flo.Id)); e != nil {
		a.log.IfWarnF(e, "notifyUserUpdated: %s", flo.Id)
	}
}

func (a *accountSync) DeleteFloUser(ctx context.Context, floId string) (e error) { //NOTE: don't expose this!!
	var usr *FloUser
	if usr, e = a.getUser(ctx, floId, ""); e != nil { //use system jwt to fetch
		notFound := strings.Contains(strings.ToLower(e.Error()), "not found")
		if !notFound {
			switch et := e.(type) {
			case *HttpErr:
				notFound = et.Code == 404
			}
		}
		if notFound {
			a.log.Notice("DeleteFloUser: getUser %s | %v", floId, e) //NOTE: flo user possibly removed, it's OK
		} else {
			a.log.IfWarnF(e, "DeleteFloUser: getUser %s", floId)
		}
		return e
	} else if usr != nil && strings.EqualFold(usr.Id, floId) {
		unpairs := make([]string, 0, 0)
		if lc := len(usr.Locations); lc > 0 {
			for _, l := range usr.Locations {
				for _, d := range l.Devices {
					if e = a.pubGW.UnpairDevice(ctx, d.Id); e != nil {
						a.log.IfWarnF(e, "DeleteFloUser: couldn't unpair device with id %s", d.Id)
					} else {
						unpairs = append(unpairs, d.Id)
						a.log.Info("DeleteFloUser: unpair device %v OK", d.Id)
					}
				}
			}
		}

		if usr.AccountId() == "" { //ensure account not nil
			a.UserCacheClean(&LinkEvent{User: usr}) //pop cache & fetch again
			if usr, e = a.getUser(ctx, usr.Id, ""); e != nil {
				return a.log.IfWarnF(e, "DeleteFloUser: getUser again %v", floId)
			} else if usr == nil || usr.Id == "" || usr.AccountId() == "" {
				return a.log.Error("DeleteFloUser: getUser not found or bad result %v", floId)
			}
		}
		if e = a.pubGW.DeleteAccount(ctx, usr.AccountId()); e != nil {
			a.log.IfWarnF(e, "couldn't delete user with id %s", usr.Id)
			return e
		} else {
			a.log.Notice("DeleteFloUser: %v OK, unpaired %v devices %v", floId, len(unpairs), unpairs)
		}
	}
	return nil
}

// OnFloUserRemoved handles kafka trigger from entity-activity-v1 topic for user delete
// code funnel call to UnLinkUser
func (a *accountSync) OnFloUserRemoved(ctx context.Context, flo *FloEntity) (e error) {
	if flo == nil || flo.Id == "" {
		return
	}
	var (
		am  *AccountMap
		moe *MoenUser //mock moen user for unlinking
	)
	if am, e = a.accStore.GetMap(ctx, "", flo.Id, ""); e != nil {
		a.log.IfWarnF(e, "OnFloUserRemoved: GetMap floId=%v FAIL", flo.Id)
	} else if am != nil && am.MoenId != "" {
		moe = &MoenUser{
			Id:        am.MoenId,
			AccountId: am.MoenAccountId,
			Verified:  "true",
		}
		if e = a.UnLinkUser(ctx, moe, true, false); e != nil {
			if he, ok := e.(*HttpErr); ok && he.Code >= 400 && he.Code < 500 {
				a.log.IfWarnF(e, "OnFloUserRemoved: UnLink UN_SUCCESSFUL floId=%v", flo.Id)
			} else {
				a.log.IfErrorF(e, "OnFloUserRemoved: UnLink ERROR floId=%v", flo.Id)
			}
		} else {
			a.log.Info("OnFloUserRemoved: OK floId=%v", flo.Id)
		}
	} else {
		a.log.Notice("OnFloUserRemoved: GetMap floId=%v EMPTY (already removed by another process?)", flo.Id)
	}
	return
}

const VALID_UUID = "required,uuid4_rfc4122"

func (a *accountSync) LinkLocation(ctx context.Context, req *locLinkReq) (e error) {
	a.log.PushScope("LinkLocation", req)
	defer a.log.PopScope()

	var (
		ls = SyncLoc{MoenId: req.MoenId, FloId: req.FloId}
		fl *FloLocation
	)
	if fl, e = a.pubGW.GetLocation(ctx, req.FloId, ""); e != nil {
		a.log.IfErrorF(e, "pubGW.GetLocation")
	} else if fl != nil && strings.EqualFold(fl.Id, req.FloId) && fl.AccountId() != "" {
		ls.FloAccId = fl.AccountId()
		if e = a.locStore.Save(ctx, &ls); e != nil {
			a.log.IfErrorF(e, "Repo.Save: FAILED %v", &ls)
		} else {
			go a.notifyLocAction(ctx, &ls, "linked")
			a.log.Info("OK %v", &ls)
		}
	} else {
		e = a.log.IfWarn(&HttpErr{404, "Flo Location Not Found: " + req.FloId, false, nil})
	}
	return
}

func (a *accountSync) OnFloLocRemoved(ctx context.Context, loc *FloEntity) (e error) {
	if loc == nil || loc.Id == "" {
		return
	}
	_, e = a.UnLinkLocation(ctx, &getLocMatch{FloId: loc.Id})
	return
}

func (a *accountSync) UnLinkLocation(ctx context.Context, match *getLocMatch) (rems []*SyncLoc, e error) {
	if e = a.valid.Struct(match); e != nil {
		a.log.IfWarnF(e, "UnLinkLocation: bad input | %v", match)
		return
	}
	if rems, e = a.locStore.Remove(ctx, match); e != nil { //point of no return if succeed
		a.log.IfErrorF(e, "UnLinkLocation: %v", match)
	} else if rl := len(rems); rl != 0 { //trigger unlink
		go a.notifyLocDeleted(ctx, rems)
		ids := make([]string, 0)
		for _, r := range rems {
			ids = append(ids, r.FloId)
		}
		a.log.Info("UnLinkLocation: %v OK | removed %v", match, ids)
	}
	return
}

func (a *accountSync) notifyLocDeleted(ctx context.Context, rems []*SyncLoc) {
	defer panicRecover(a.log, "notifyLocDeleted")
	a.log.Debug("notifyLocDeleted: begin count=%v", len(rems))
	for _, r := range rems {
		a.notifyLocAction(ctx, r, "unlinked")
	}
}

func (a *accountSync) notifyLocAction(ctx context.Context, loc *SyncLoc, action string) {
	defer panicRecover(a.log, "notifyLocAction: %v %v", loc, action)
	a.log.PushScope("notifyLocAction", action, loc.FloId)
	defer a.log.PopScope()

	var (
		fl  = &FloLocation{Id: loc.FloId}
		lnk = LinkEvent{
			Location: fl,
			External: ExternalEntity{
				Vendor: "moen",
				Type:   "location",
				Id:     loc.MoenId,
				Entity: &MoenEntity{Id: loc.MoenId}, //keep the 2 system decoupled, we are not fetching Moen loc here
			},
		}
	)
	if loc.FloAccId != "" {
		fl.Account = &FloEntity{Id: loc.FloAccId}
	}
	if action != "unlinked" && action != "deleted" {
		if fullLoc, e := a.pubGW.GetLocation(ctx, loc.FloId, ""); e != nil {
			a.log.IfErrorF(e, "Flo location not found!")
			return
		} else {
			lnk.Location = fullLoc
		}
	}
	evt := EntityEventEnvelope{
		Date:   PubGwTime(time.Now().UTC()),
		Type:   "location",
		Action: strings.ToLower(action),
		Item:   &lnk,
	}
	if e := a.kafConn.Publish(ctx, a.kafTopic, evt, []byte(loc.FloId)); e != nil {
		a.log.IfWarnF(e, "publish FAILED to %v | %v", a.kafTopic, evt)
	} else {
		a.log.Debug("publish OK to %v", a.kafTopic)
	}
}
