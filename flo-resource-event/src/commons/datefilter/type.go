package datefilter

// Type is an enum for the types of the DateFilter.
type Type string

const (
	// DateFilterTypeFrom is the enum option for FROM date filter type.
	DateFilterTypeFrom Type = "FROM"
	// DateFilterTypeTo is the enum option for TO date filter type.
	DateFilterTypeTo Type = "TO"
	// DateFilterTypeRange is the enum option for RANGE date filter type.
	DateFilterTypeRange Type = "RANGE"
	// DateFilterTypeDate is the enum option for DATE date filter type.
	DateFilterTypeDate Type = "DATE"
)
