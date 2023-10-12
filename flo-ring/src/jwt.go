package main

import (
	"encoding/base64"
	"encoding/json"
	"github.com/pkg/errors"
	"strings"
)

type JwtHead struct {
	KeyId     string `json:"kid,omitempty"`
	Algorithm string `json:"alg,omitempty"`
	Type      string `json:"typ,omitempty"`
}

type JwtDef struct {
	Head JwtHead                `json:"head"`
	Body map[string]interface{} `json:"body"`
	Sig  string                 `json:"sig"`
}

func JwtDecode(jwt string) (*JwtDef, error) {
	jwt = JwtTrim(jwt)
	var err error
	if parts := strings.Split(jwt, "."); len(parts) == 3 && len(parts[0]) > 16 && len(parts[1]) >= 32 && len(parts[2]) >= 32 {
		var (
			res    = JwtDef{Body: make(map[string]interface{}), Sig: parts[2]}
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
			err = errors.Wrapf(e, "Decode body failed: %v", JwtScrub(jwt))
		} else if e = json.Unmarshal(buf, &res.Body); e != nil {
			err = errors.Wrapf(e, "Deserialize body failed: %v", JwtScrub(jwt))
		} else {
			if buf, e = base64.StdEncoding.DecodeString(head); e != nil {
				err = errors.Wrapf(e, "Decode head failed: %v", JwtScrub(jwt))
			} else if e = json.Unmarshal(buf, &res.Head); e != nil {
				err = errors.Wrapf(e, "Deserialize head failed: %v", JwtScrub(jwt))
			} else {
				return &res, nil //success!!
			}
		}
	} else {
		err = errors.Errorf("Bad JWT: %v", JwtScrub(jwt))
	}
	return nil, err
}

func JwtTrim(jwt string) string {
	if ix := strings.LastIndex(jwt, " "); ix >= 0 {
		jwt = jwt[ix+1:] //remove Bearer
	}
	return strings.TrimSpace(jwt)
}

const STARS = "*****"

func JwtScrub(tk string) string {
	if arr := strings.Split(tk, "."); len(arr) == 3 {
		return strings.Join(append(arr[:2], STARS), ".")
	} else {
		return STARS
	}
}
