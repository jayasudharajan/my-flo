package enums

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestEnum_UnmarshalJSON(t *testing.T) {
	inputEnum := []struct {
		message      string
		testEnum     string
		expectedEnum Enum
	}{
		{
			"Uppercase enum Unmarshal test case",
			"CREATED",
			"created",
		},
		{
			"Lowercase enum Unmarshal test case",
			"created",
			"created",
		},
		{
			"Snakecase enum Unmarshal test case",
			"delete",
			"delete",
		},
		{
			"Enum with uppercase and lowercase letters Unmarshal test case",
			"OpeN",
			"open",
		},
		{
			"Kebabcase enum Unmarshal test case",
			"VALVE-CLOSE",
			"valve-close",
		},
		{
			"Kebab-case enum with uppercase and lowercase letters Unmarshal test case",
			"ValvE-ClosE",
			"valve-close",
		},
		{
			"enum with whitespaces and special characters Unmarshal test case",
			"User\ninvite\tc@ncell3d",
			"user\ninvite\tc@ncell3d",
		},
		{
			"Empty string enum Unmarshal test case",
			"",
			"",
		},
		{
			"Whitespace characters enum Unmarshal test case",
			" \t\n",
			" \t\n",
		},
	}
	for _, input := range inputEnum {
		t.Log(input.message)
		resultEventType := new(Enum)
		err := resultEventType.UnmarshalJSON([]byte(input.testEnum))

		assert.NoError(t, err)
		assert.Equal(t, input.expectedEnum, *resultEventType)
	}
}
