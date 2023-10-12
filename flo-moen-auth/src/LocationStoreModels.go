package main

import (
	"fmt"
	"strings"
)

type getLocMatch struct {
	FloId    string `json:"floId,omitempty" schema:"floId" url:"floId" validate:"omitempty,uuid4_rfc4122"`
	FloAccId string `json:"floAccountId,omitempty" schema:"floAccountId" url:"floAccountId" validate:"omitempty,uuid4_rfc4122"`
	MoenId   string `json:"moenId,omitempty" schema:"moenId" url:"moenId" validate:"omitempty,uuid4_rfc4122"`
}

func (lm getLocMatch) String() string {
	return fmt.Sprintf("(fId:%s,fAcc:%s,mId:%s)", lm.FloId, lm.FloAccId, lm.MoenId)
}

func (lm *getLocMatch) Validate(chk *Validator) error {
	if lm == nil {
		return &HttpErr{400, "location match is nil", false, nil}
	} else if lm.FloId == "" && lm.FloAccId == "" && lm.MoenId == "" {
		return &HttpErr{400, "At at least 1 field is required: floId, floAccountId, moenId", false, nil}
	} else {
		return chk.Struct(lm)
	}
}

type skipLimPage struct {
	SyncRead bool `json:"sync" schema:"sync" url:"sync"`
	Limit    int  `json:"limit" schema:"limit" url:"limit" validate:"omitempty,min=1,max=100"`
	Skip     int  `json:"skip" schema:"skip" url:"skip" validate:"omitempty,min=0"`
}

func (lm *skipLimPage) Normalize() *skipLimPage {
	if lm != nil {
		if lm.Limit == 0 {
			lm.Limit = 10 //default
		} else {
			lm.Limit = clampInt(lm.Limit, 1, 100)
		}
		if lm.Skip < 0 {
			lm.Skip = 0
		}
	}
	return lm
}

func (lm *skipLimPage) Validate(chk *Validator) error {
	if lm == nil {
		return &HttpErr{400, "pagination is required", false, nil}
	} else {
		return chk.Struct(lm)
	}
}

func (lm skipLimPage) String() string {
	return fmt.Sprintf("lim:%v,skp:%v", lm.Limit, lm.Skip) //omitting syncRead to provide more cache hits
}

type SyncLoc struct {
	FloId    string `json:"floId" validate:"uuid4_rfc4122"`
	FloAccId string `json:"floAccountId" validate:"uuid4_rfc4122"`
	MoenId   string `json:"moenId" validate:"uuid4_rfc4122"`
}

func (sl SyncLoc) String() string {
	k := fmt.Sprintf("f:%v,fA:%v,m:%v", sl.FloId, sl.FloAccId, sl.MoenId)
	return strings.ReplaceAll(k, "-", "") //shorter keys to save redis RAM
}
