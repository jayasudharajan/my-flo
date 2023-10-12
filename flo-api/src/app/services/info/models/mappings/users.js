export default {
    "user": {
        "properties": {
            "email":{"type":"keyword"},
            "id":{"type":"keyword"},
            "is_active": {"type":"boolean"},
            "is_system_user":{"type":"boolean"},
         
            "firstname":{"type":"keyword"},
            "lastname":{"type":"keyword"},
            "middlename":{"type":"keyword"},
            "phone_mobile":{"type":"text"}, 
            "prefixname":{"type":"text"},
            "suffixname":{"type":"text"},
            
            "account": {
                "type":"object",
                "properties": {
                    "account_id": { "type": "keyword" },
                    "group_id": { "type": "keyword" }
                }
            },

            "geo_locations":{
                "type":"nested",
                "properties":{
                    "country": {"type":"keyword"},
                    "state_or_province": {"type":"keyword"},
                    "city": {"type":"keyword"},
                    "postal_code": {"type":"keyword"},
                    "location_id": { "type": "keyword" },
                    "timezone": {"type":"keyword"}
                }
            },

            "devices": {
                "type": "nested",
                "properties": {
                    "id": {"type": "keyword"},
                    "device_id": {"type": "keyword"},
                    "location_id": {"type": "keyword"},
                    "is_paired": {"type": "boolean"},
                    "is_test_device": {"type": "boolean"}
                }
            }
        }
    }
}


