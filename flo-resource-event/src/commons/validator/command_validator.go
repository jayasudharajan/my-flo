package validator

import (
	"reflect"
	"regexp"
	"strings"
	"sync"
	"time"

	"flotechnologies.com/flo-resource-event/src/commons/utils"
	validator "github.com/go-playground/validator/v10"
)

//SEE: https://godoc.org/gopkg.in/go-playground/validator.v10
type Validator struct {
	val      *validator.Validate
	regExMap sync.Map
	log      *utils.Logger
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
	return &sv, utils.WrapErrors(es)
}

func (v *Validator) Struct(o interface{}) error {
	return v.val.Struct(o)
}

func (v *Validator) Value(field interface{}, tag string) error {
	return v.val.Var(field, tag)
}
