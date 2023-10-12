export default {
    "icdalarmincidentregistrylog":{
            "properties":{
                 
            "created_at":{"type":"date"},
            "delivery_medium":{"type":"integer"},
            "icd_alarm_incident_registry_id":{"type":"keyword"},
            "id":{"type":"keyword"},
            "receipt_id":{"type":"keyword"},
            "status":{"type":"integer"},
            "user_id":{"type":"keyword"},

            "account": {
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
            }
        }
    }
}
