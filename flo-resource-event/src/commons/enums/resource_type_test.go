package enums

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
)

type resourceTypeTestStruct struct {
	ResourceType ResourceType `json:"resourceType"`
}

func TestResourceTypeEnum_UnmarshalJSON(t *testing.T) {
	const resourceTypeTestData = `{"resourceType":"ResOurce-TypE"}`
	unmarshaledStruct := new(resourceTypeTestStruct)
	err := json.Unmarshal([]byte(resourceTypeTestData), unmarshaledStruct)
	assert.NoError(t, err)
	assert.Equal(t, ResourceType("resource-type"), unmarshaledStruct.ResourceType)

	stringJSON, err := json.Marshal(unmarshaledStruct)
	assert.NoError(t, err)
	assert.Equal(t, []byte(`{"resourceType":"resource-type"}`), stringJSON)
}
