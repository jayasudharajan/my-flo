package enums

import "strings"

// ResourceAction is an enum that defines the resource types.

type ResourceAction Enum

/*
	create, update, delete, invite (user)
	paired, unpaired (device)
	create, delete (location)
	login (account)
	open, close (valve)
*/

const (
	ResourceActionPaired   ResourceAction = "paired"
	ResourceActionUnpaired ResourceAction = "unpaired"
	ResourceActionLogin    ResourceAction = "login"
	ResourceActionCreate   ResourceAction = "created"
	ResourceActionUpdate   ResourceAction = "updated"
	ResourceActionDelete   ResourceAction = "deleted"
	ResourceActionInvite   ResourceAction = "invited"
	ResourceActionOpen     ResourceAction = "open"
	ResourceActionClose    ResourceAction = "close"
)

func (enum *ResourceAction) UnmarshalJSON(b []byte) error {
	s := string(b)
	s = strings.Trim(s, "\"")
	s = strings.ToLower(s)
	*enum = ResourceAction(s)
	return nil
}
