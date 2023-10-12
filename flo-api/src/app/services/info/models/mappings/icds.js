export default {
    "icd":{
        "properties": {
            "device_id":{"type":"keyword"},
            "id":{"type":"keyword"},
            "is_paired":{"type":"boolean"},

            "owner_user_id":{"type":"keyword"},

            "users": {
                "type": "nested",
                "properties": {
                    "user_id": {"type":"keyword"},
                    "email": {"type":"keyword"},
                    "firstname": {"type":"keyword"},
                    "lastname": {"type":"keyword"}
                }
            },

            "account":{
                "type":"object",
                "properties":{
                    "account_id": {"type":"keyword"},
                    "group_id": {"type":"keyword"}
                }
            },
             
            "geo_location":{
                "type":"object",
                "properties":{
                    "location_id": {"type":"keyword"},
                    "country": {"type":"keyword"},
                    "state_or_province": {"type":"keyword"},
                    "city": {"type":"keyword"},
                    "postal_code": {"type":"keyword"},
                    "timezone": {"type":"keyword"}
                }
            },
            "onboarding": {
                "type": "nested",
                "properties": {
                    "created_at": {"type":"date"},
                    "event": {"type":"float"}
                }
            }
        }
    }
}