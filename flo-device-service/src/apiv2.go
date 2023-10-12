package main

import (
	"database/sql/driver"
	"encoding/json"
	"time"

	"github.com/pkg/errors"
)

type SystemModeReconciliation struct {
	Icd        string           `json:"-"`
	Mac        string           `json:"mac"`
	LocationId string           `json:"locationId,omitempty"`
	Device     SystemModeDevice `json:"device,omitempty"`
	Location   SystemModeBase   `json:"location,omitempty"`
	reason     string           `json:"-"`
}

type SystemModeBase struct {
	Target            string `json:"target"`
	RevertScheduledAt string `json:"revertScheduledAt"`
	RevertMode        string `json:"revertMode"`
}

func (s *SystemModeBase) RevertTime() time.Time {
	return extractDt(s.RevertScheduledAt)
}

func (s *SystemModeBase) HasRevertTime() bool {
	return s.RevertTime().Year() > 2000
}

type SystemModeDevice struct {
	SystemModeBase
	IsLocked      bool   `json:"isLocked"`
	ShouldInherit bool   `json:"shouldInherit"`
	LastKnown     string `json:"lastKnown,omitempty"`
}

// Make the Attrs struct implement the driver.Valuer interface. This method
// simply returns the JSON-encoded representation of the struct.
func (a SystemModeReconciliation) Value() (driver.Value, error) {
	return json.Marshal(a)
}

// Make the Attrs struct implement the sql.Scanner interface. This method
// simply decodes a JSON-encoded value into the struct fields.
func (a *SystemModeReconciliation) Scan(value interface{}) error {
	if value == nil {
		return nil
	}
	b, ok := value.([]byte)
	if !ok {
		return errors.New("type assertion to []byte failed")
	}
	return json.Unmarshal(b, &a)
}

type SetConnectionMethod string

const (
	SetConnectionMethod_Unknown SetConnectionMethod = "unknown"
)

type SetConnectionMethodModel struct {
	Method SetConnectionMethod `json:"method"`
}
