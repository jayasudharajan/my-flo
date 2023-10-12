package enums

import "strings"

// Enum is a general type that it is used for all particular enums
type Enum string

// UnmarshalJSON parse JSON value to enum and set the value to receiver.
func (enum *Enum) UnmarshalJSON(b []byte) error {
	s := string(b)
	s = strings.Trim(s, "\"")
	s = strings.ToLower(s)
	*enum = Enum(s)
	return nil
}
