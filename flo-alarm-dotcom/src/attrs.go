package main

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
)

func CreateAttrs(o interface{}) (*Attrs, error) {
	if o == nil {
		return nil, errors.New("nil input")
	}
	if m, ok := o.(map[string]interface{}); ok {
		attr := Attrs(m)
		return &attr, nil
	} else if js, e := json.Marshal(o); e != nil {
		return nil, e
	} else if len(js) >= 2 && js[0] == '{' {
		r := Attrs{}
		if e = json.Unmarshal(js, &r); e != nil {
			return nil, e
		} else {
			return &r, nil
		}
	} else {
		return nil, errors.New("input is not of type map")
	}
}

//Attrs type maps to Postgres JSON & JSONB, will also serialize/deserialize to JSON nicely
type Attrs map[string]interface{}

func (a Attrs) Value() (driver.Value, error) {
	return json.Marshal(a)
}

func (a *Attrs) Scan(value interface{}) error {
	if *a == nil {
		*a = Attrs{}
	}
	b, ok := value.([]byte)
	if !ok {
		return errors.New("type assertion to []byte failed")
	}
	return json.Unmarshal(b, a)
}

func (a *Attrs) Map(out interface{}) error {
	if a == nil {
		return nil
	}
	if js, e := json.Marshal(a); e != nil {
		return e
	} else if e = json.Unmarshal(js, out); e != nil {
		return e
	} else {
		return nil
	}
}

func (a *Attrs) Key(k string) (v interface{}, ok bool) {
	if a == nil {
		return nil, false
	}
	v, ok = (*a)[k]
	return v, ok
}

func (a Attrs) String() string {
	return tryToJson(a)
}

func (a Attrs) UnmarshalJSON(data []byte) error {
	refMap := make(map[string]interface{})
	if e := json.Unmarshal(data, &refMap); e != nil {
		return e
	}
	for k, v := range refMap {
		a[k] = v
	}
	return nil
}
