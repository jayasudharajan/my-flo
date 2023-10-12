package main

import "errors"

// invoker interfaces

type InvokeCtx interface {
	Req() *intentReq
	UserId() string
	AuthHeader() string
	Jwt() *JwtPayload
	Log() Log
}

type IntentInvoker interface {
	Invoke(ctx InvokeCtx) (interface{}, error)
}

////////////
/* inputs */

type intentReq struct {
	RequestId string         `json:"requestId" validate:"min=1,max=64,required"`
	Inputs    []*intentInput `json:"inputs" validate:"min=1,max=16,required,dive"`
}

func (ir *intentReq) WhereInputs(predicate func(input *intentInput) bool) []*intentInput {
	if ir == nil {
		return nil
	}
	res := make([]*intentInput, 0)
	for _, input := range ir.Inputs {
		if predicate(input) {
			res = append(res, input)
		}
	}
	return res
}

type intentInput struct {
	Intent  string                 `json:"intent" validate:"min=8,max=64,required,contains=."`
	Payload map[string]interface{} `json:"payload,omitempty"`
}

// PayloadAs casts input payload into o type reference, validator is optional
func (ip *intentInput) PayloadAs(o interface{}, valid Validator) (e error) {
	if ip == nil {
		e = errors.New("intentInput receiver is nil")
	} else if e = jsonMap(ip.Payload, o); e == nil && valid != nil {
		e = valid.Struct(o)
	}
	return
}
