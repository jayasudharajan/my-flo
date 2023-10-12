package main

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"strings"
)

type JwtHead struct {
	KeyId     string `json:"kid"`
	Algorithm string `json:"alg"`
}

type JwtDef struct {
	Head     JwtHead `json:"head"`
	Subject  string  `json:"sub"`
	Usage    string  `json:"token_use"`
	Scope    string  `json:"scope"`
	IssueAt  int64   `json:"iat"`
	Issuer   string  `json:"iss"`
	Expires  int64   `json:"exp"`
	TokenId  string  `json:"jti"`
	ClientId string  `json:"client_id"`
	UserId   string  `json:"user_id,omitempty"`
}

func JwtDefDecode(jwt string, log *Logger) (*JwtDef, error) {
	if log == nil {
		log = _log //use default logger
	}
	jwt = trimJwt(jwt)
	if parts := strings.Split(jwt, "."); len(parts) == 3 && len(parts[0]) > 16 && len(parts[1]) >= 32 && len(parts[2]) >= 32 {
		var (
			res    = JwtDef{Head: JwtHead{}}
			fixPad = func(s string) string {
				if m := len(s) % 4; m != 0 { //fix padding
					s += strings.Repeat("=", 4-m)
				}
				return s
			}
			head = fixPad(parts[0])
			enc  = fixPad(parts[1])
		)
		if buf, e := base64.StdEncoding.DecodeString(enc); e != nil {
			log.IfWarnF(e, "JwtDefDecode body failed: %v", CleanJwt(jwt))
		} else if e = json.Unmarshal(buf, &res); e != nil {
			log.IfWarnF(e, "JwtDefDecode deserialize body failed: %v", CleanJwt(jwt))
		} else {
			if buf, e = base64.StdEncoding.DecodeString(head); e != nil {
				log.IfWarnF(e, "JwtDefDecode head failed: %v", CleanJwt(jwt))
			} else if e = json.Unmarshal(buf, &res.Head); e != nil {
				log.IfWarnF(e, "JwtDefDecode deserialize head failed: %v", CleanJwt(jwt))
			}
			return &res, nil //success!!
		}
	} else {
		log.Warn("Bad JWT: %v", CleanJwt(jwt))
	}
	return nil, errors.New("bad JWT")
}
