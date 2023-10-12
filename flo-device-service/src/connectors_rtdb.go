package main

import (
	"context"
	"os"

	firebase "firebase.google.com/go"
	"google.golang.org/api/option"
)

// FirebaseApp is the reference to firebase application
var FirebaseApp *firebase.App

// RtdbCtx is the real time database context
var RtdbCtx = context.Background()

// InitFirestore is the function to initialize firestore client
func InitFirestore() error {

	var err error
	logDebug("InitFirestore: Loading Firestore Credentials from '%v'", GoogleAppCreds)

	if _, err = os.Stat(GoogleAppCreds); os.IsNotExist(err) {
		conf := &firebase.Config{ProjectID: GoogleProjectID}
		FirebaseApp, err = firebase.NewApp(RtdbCtx, conf)
	} else {
		serviceAccountCreds := option.WithCredentialsFile(GoogleAppCreds)
		FirebaseApp, err = firebase.NewApp(RtdbCtx, nil, serviceAccountCreds)
	}
	if err != nil {
		return err
	}

	return nil
}
