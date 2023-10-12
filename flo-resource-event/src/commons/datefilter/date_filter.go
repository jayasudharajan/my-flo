package datefilter

import "time"

// DateFilter is an struct to contains the custom type DateFilter.
type DateFilter struct {
	From time.Time
	To   time.Time
	Date time.Time
	Type Type
}

// IsZero is a function that indicates when the DateFilter has a value.
func (dateFilter DateFilter) IsZero() bool {
	return dateFilter.From.IsZero() &&
		dateFilter.To.IsZero() &&
		dateFilter.Date.IsZero()
}
