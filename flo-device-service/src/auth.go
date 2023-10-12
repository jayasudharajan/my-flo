package main

import (
	"context"

	"github.com/google/uuid"
	"github.com/labstack/gommon/log"
)

// GenerateFirestoreJwtWithIdsRule should match the firestore database rule:
// allow read: if request.auth.uid != null && (request.auth.token.device_ids == '*' || resource.data.deviceId in request.auth.token.ids.split(','));
func GenerateFirestoreJwtWithIdsRule(deviceIds string, locationIds string, userIds string) (string, error) {

	ctx := context.Background()

	client, err := FirebaseApp.Auth(ctx)
	if err != nil {
		log.Errorf("error getting Auth client: %v", err)
		return EmptyString, err
	}

	firestoreJwtUuid := uuid.New().String()

	claims := map[string]interface{}{
		"device_ids":   deviceIds,
		"location_ids": locationIds,
		"user_ids":     userIds,
	}
	token, err := client.CustomTokenWithClaims(ctx, firestoreJwtUuid, claims)
	if err != nil {
		log.Errorf("error creating custom jwt with public claim field deviceIds %s: %v", deviceIds, err)
		return EmptyString, err
	}

	return token, nil
}
