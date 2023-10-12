package main

type MoenUserModel struct {
	Email            string `json:"email,omitempty"`
	FirstName        string `json:"firstName,omitempty"`
	LastName         string `json:"lastName,omitempty"`
	FederatedId      string `json:"federatedId,omitempty"`
	IdentityProvider string `json:"identityProvider,omitempty"`
	Language         string `json:"language,omitempty"`
	Phone            string `json:"phone,omitempty"`
}

type MoenEntityAlarmSettingsModel struct {
	FederatedId string               `json:"federatedId,omitempty"`
	Email       string               `json:"email,omitempty"`
	Items       []*MoenAlarmSettings `json:"items"`
}

type MoenAlarmSettings struct {
	DeviceId string                    `json:"deviceId"`
	Settings []*MoenAlarmSettingsCodec `json:"settings"`
}

type MoenAlarmSettingsCodec struct {
	AlarmId      int  `json:"alarmId"`
	EmailEnabled bool `json:"emailEnabled"`
	PushEnabled  bool `json:"pushEnabled"`
	CallEnabled  bool `json:"callEnabled"`
	SmsEnabled   bool `json:"smsEnabled"`
}

type MoenLocationModel struct {
	Id       string `json:"id"`
	Name     string `json:"name"`
	Timezone string `json:"timezone"`
}

type MoenDeviceModel struct {
	Id       string `json:"duid"`
	Name     string `json:"name"`
	Model    string `json:"model"`
	Location string `json:"location"`
	Email    string `json:"email"`
}

func (m *MoenUserModel) ToPublicGatewayModel() *PublicGatewayUserModel {
	return &PublicGatewayUserModel{
		Email:       m.Email,
		FirstName:   m.FirstName,
		LastName:    m.LastName,
		Locale:      m.Language,
		PhoneMobile: m.Phone,
	}
}
