package main

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/labstack/echo/v4"
	"github.com/labstack/gommon/log"
)

// GenerateCustomJwtHandler godoc
// @Summary generates custom JWT token to authenticate clients with Firestore
// @Description generates custom JWT token to authenticate clients with Firestore limiting access to specified asset ids
// @Description it is achieved by passing the ids of customer's asset such as devices in the request body which is going to be baked in as a custom claim "ids" into the jwt
// @Tags devices, firestore
// @Accept  json
// @Produce  json
// @Param firestoreAuth body FirestoreAuth true "specifies the devices ids client has access to"
// @Success 200 {object} FirestoreToken
// @Failure 400 {object} ErrorResponse "parameter ids has to be a string" "parameter ids can not be empty"
// @Failure 500 {object} ErrorResponse "failed to generate firestore jwt"
// @Router /firestore/auth [POST]
func (dsh DeviceServiceHandler) GenerateCustomJwtHandler(c echo.Context) error {
	var err error

	bindErrorMsg := "failed to bind request body with FirestoreAuth struct"
	firestoreAuth := FirestoreAuth{
		Devices:   []string{},
		Locations: []string{},
		Users:     []string{},
	}

	err = c.Bind(&firestoreAuth)
	if err != nil {
		log.Errorf("%s, err: %v", bindErrorMsg, err)
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    bindErrorMsg,
		})
	}

	for _, deviceId := range firestoreAuth.Devices {
		if !isValidDeviceMac(deviceId) {
			return c.JSON(http.StatusBadRequest, ErrorResponse{
				StatusCode: http.StatusBadRequest,
				Message:    fmt.Sprintf(errMsgDeviceIdBadRequest, deviceId),
			})
		}
	}
	//TODO: we might have firestoreAuth.Pucks or such, the list of deviceIds (comma separated) might grow, change the way
	// deviceIds are assembled if expansion is needed

	deviceIds := strings.Join(firestoreAuth.Devices, ",")
	locationIds := strings.Join(firestoreAuth.Locations, ",")
	userIds := strings.Join(firestoreAuth.Users, ",")

	token, err := GenerateFirestoreJwtWithIdsRule(deviceIds, locationIds, userIds)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    fmt.Sprintf("failed to generate firestore jwt"),
		})
	}

	firestoreToken := FirestoreToken{
		Token: token,
	}

	return c.JSON(http.StatusOK, firestoreToken)
}
