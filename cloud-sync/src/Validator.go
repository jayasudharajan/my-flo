package main

import (
	"fmt"
	"reflect"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/go-playground/validator/v10"
)

//SEE: https://godoc.org/gopkg.in/go-playground/validator.v10
type Validator struct {
	val      *validator.Validate
	regExMap sync.Map
}

func CreateValidator() (valid *Validator, err error) {
	sv := Validator{
		val: validator.New(),
	}
	sv.val.RegisterTagNameFunc(func(fld reflect.StructField) string {
		arr := strings.SplitN(fld.Tag.Get("json"), ",", 2)
		if len(arr) == 0 {
			return ""
		}
		name := arr[0]
		if name == "-" {
			return ""
		}
		return name
	})

	es := make([]error, 0)
	e := sv.val.RegisterValidation("datetime", func(fl validator.FieldLevel) bool {
		//Re := regexp.MustCompile(`^\d{4}-(0[0-9]|1[1,2])-([0-2][0-9]|3[0,1])(|(T| )[0-5][0-9]:[0-5][0-9](|:[0-5][0-9]))`)
		val := fl.Field().String()
		if val == "<time.Time Value>" { //fix bug w/ validator when type is time.Time
			return true
		}
		ps := fl.Param()
		dt, err := time.Parse(ps, val)
		return err != nil && dt.After(time.Unix(0, 0))
	})
	if e != nil {
		es = append(es, e)
	}

	e = sv.val.RegisterValidation("regex", func(fl validator.FieldLevel) bool {
		ps := fl.Param()
		val := fl.Field().String()
		if rev, ok := sv.regExMap.Load(ps); ok {
			re := rev.(*regexp.Regexp)
			return re.MatchString(val)
		} else {
			re := regexp.MustCompile(ps)
			sv.regExMap.Store(ps, re)
			return re.MatchString(val)
		}
	})
	if e != nil {
		es = append(es, e)
	}
	return &sv, wrapErrors(es)
}

func (v *Validator) Struct(o interface{}) error {
	return v.wrapErr(v.val.Struct(o))
}

func (v *Validator) wrapErr(e error) error {
	if e != nil {
		if checks, ok := e.(validator.ValidationErrors); ok {
			msg := ""
			for _, ve := range checks {
				if ve == nil {
					continue
				}
				msg += fmt.Sprintf(`Field validation for '%s' failed on '%s' requirement.\n`, ve.Field(), ve.Tag())
			}
			if ml := len(msg); ml > 1 {
				return &HttpErr{Code: 400, Message: msg[0 : ml-1], IsJSON: false, Trace: e}
			}
		}
	}
	return e
}

func (v *Validator) Value(field interface{}, tag string) error {
	return v.wrapErr(v.val.Var(field, tag))
}
