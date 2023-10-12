package enums

import "strings"

// ResourceType is an enum that defines the resource types.
type ResourceType Enum

const (
	ResourceTypeDevice   ResourceType = "device"
	ResourceTypeLocation ResourceType = "location"
	ResourceTypeAccount  ResourceType = "account"
	ResourceTypeUser     ResourceType = "user"
)

func (enum *ResourceType) UnmarshalJSON(b []byte) error {
	s := string(b)
	s = strings.Trim(s, "\"")
	s = strings.ToLower(s)
	*enum = ResourceType(s)
	return nil
}
