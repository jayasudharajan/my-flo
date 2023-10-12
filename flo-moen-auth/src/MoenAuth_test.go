package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestCreateMoenAuthWithMoenVariables(t *testing.T) {
	auth := CreateMoenAuth(new(Logger), new(httpUtil), new(RedisConnection), new(Validator)).(*moenAuth)
	assert.NotNil(t, auth.moenVars)
	assert.Equal(t, 3, len(auth.moenVars))

	for v := range auth.moenVars {
		assert.NotEmpty(t, auth.moenVars[v].CogJwkUrl)
		assert.NotEmpty(t, auth.moenVars[v].Uri)
		assert.NotEmpty(t, auth.moenVars[v].CogClient)
		assert.NotEmpty(t, auth.moenVars[v].CogSecret)
		// assert.NotEmpty(t, auth.moenVars[v].HackUri)
	}
}

func TestDefaultToProdMoenVariables(t *testing.T) {
	auth := CreateMoenAuth(new(Logger), new(httpUtil), new(RedisConnection), new(Validator)).(*moenAuth)
	assert.NotNil(t, auth.moenVars)
	prodMoenVars := auth.getMoenVarsByIssuer("invalid issuer")
	assert.NotEmpty(t, prodMoenVars.CogJwkUrl)
	assert.NotEmpty(t, prodMoenVars.Uri)
	assert.NotEmpty(t, prodMoenVars.CogClient)
	assert.NotEmpty(t, prodMoenVars.CogSecret)
	// assert.NotEmpty(t, prodMoenVars.HackUri)
	assert.Contains(t, prodMoenVars.Uri, "east-2")
}

func TestGetMoenVariablesByValidIssuer(t *testing.T) {
	auth := CreateMoenAuth(new(Logger), new(httpUtil), new(RedisConnection), new(Validator)).(*moenAuth)
	assert.NotNil(t, auth.moenVars)
	prodMoenVars := auth.getMoenVarsByIssuer("https://cognito-idp.us-west-2.amazonaws.com/us-west-2_9MuzgHBuh")
	assert.NotEmpty(t, prodMoenVars.CogJwkUrl)
	assert.NotEmpty(t, prodMoenVars.Uri)
	assert.NotEmpty(t, prodMoenVars.CogClient)
	assert.NotEmpty(t, prodMoenVars.CogSecret)
	// assert.NotEmpty(t, prodMoenVars.HackUri)
	assert.Contains(t, prodMoenVars.Uri, "west-2")
}
