package main

import (
	"fmt"
	va "github.com/go-playground/validator/v10"
	"reflect"
	"regexp"
	"strings"
	"sync"
)

type Validator interface {
	Struct(o interface{}) error
	Value(field interface{}, tag, name string) error
}

// SEE: https://godoc.org/gopkg.in/go-playground/validator.v10
type validator struct {
	val      *va.Validate
	regExMap sync.Map
	sbp      SbPool
}

// CreateValidator contains wrapped logic with predefined validators
// SEE: https://pkg.go.dev/github.com/go-playground/validator/v10#section-readme
func CreateValidator(sbp SbPool) (valid Validator, err error) {
	sv := validator{val: va.New(), sbp: sbp}
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
	e := sv.val.RegisterValidation("regex", func(fl va.FieldLevel) bool {
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

// Struct check the whole obj recursively
// SEE: https://pkg.go.dev/github.com/go-playground/validator/v10#section-readme
func (v *validator) Struct(o interface{}) error {
	if _, ok := o.(*map[string]interface{}); ok {
		return nil
	}
	return v.wrapErr(v.val.Struct(o), "")
}

func (v *validator) wrapErr(e error, name string) error {
	if e != nil {
		if checks, ok := e.(va.ValidationErrors); ok {
			sb := v.sbp.Get()
			defer v.sbp.Put(sb)

			for _, ve := range checks {
				if ve == nil {
					continue
				}

				if name != "" {
					sb.WriteString(fmt.Sprintf("Validation failed for '%s' ", name))
				} else if field := ve.Field(); field != "" {
					sb.WriteString(fmt.Sprintf("Field validation failed for '%s' ", field))
				} else {
					sb.WriteString("Validation failed ")
				}

				sb.WriteString(fmt.Sprintf("on '%s' requirement", ve.Tag()))

				if val := ve.Param(); val != "" {
					sb.WriteString(fmt.Sprintf(" of param: '%s'.\n", val))
				} else if val = fmt.Sprint(ve.Value()); val != "" && val != "nil" {
					sb.WriteString(fmt.Sprintf(" of value: '%s'.\n", val))
				} else {
					sb.WriteString(".\n")
				}
			}
			if ml := sb.Len(); ml > 1 {
				return &HttpErr{Code: 400, Message: sb.String()[:ml-1], Trace: e}
			}
		}
	}
	return e
}

// Value check a single field
// SEE: https://pkg.go.dev/github.com/go-playground/validator/v10#section-readme
func (v *validator) Value(field interface{}, tag, name string) error {
	return v.wrapErr(v.val.Var(field, tag), name)
}
