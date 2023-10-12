package att

// https://developer.cisco.com/docs/control-center/

type ATTMobileDevice struct {
	DeviceID      string `json:"deviceID"` //	Optional identifier that an account or customer can give to a device.
	ICCID         string `json:"iccid"`    // Integrated Circuit Card Identifier
	IMEI          string `json:"imei"`
	IMSI          string `json:"imsi"`
	MSISDN        string `json:"msisdn"`
	Status        string `json:"status"`
	Customer      string `json:"customer"`      //The name of the customer (generally an enterprise or business unit), if any, associated with this device.
	EndConsumerID string `json:"endConsumerId"` //	The ID of the person, if any, associated with this device.
	AccountID     string `json:"accountId"`     //	The ID of the enterprise account associated with the device.
}

type ATTMobileCustomer struct {
	CustomerID        string             `json:"customerId,omitempty"`
	Name              string             `json:"name,omitempty"`
	AccountName       string             `json:"accountName,omitempty"`
	Contacts          []ATTMobileContact `json:"contacts,omitempty"`
	ShipToBillAddress bool               `json:"shipToBillAddress"` //If true, the customer's billing address is the same as the shipping address.
	BillingAddress    *LTEAddress        `json:"billingAddress,omitempty"`
	ShippingAddress   *LTEAddress        `json:"shippingAddress,omitempty"`
}

type ATTMobileContact struct {
	Name   string `json:"name"`
	Title  string `json:"title,omitempty"`
	Phone  string `json:"phone,omitempty"`
	Mobile string `json:"mobile"`
	Email  string `json:"email"`
}

type LTEAddress struct {
	AddressLine1 string `json:"addressLine1"`
	AddressLine2 string `json:"addressLine2,omitempty"`
	City         string `json:"city"`
	StateProv    string `json:"state"`
	PostalCode   string `json:"postalCode,omitempty"`
}
