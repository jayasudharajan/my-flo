export default {
    "icdalarmincidentregistry":{
        "properties":{
                 
            "acknowledged_by_user":{"type":"integer"},
            "alarm_id":{"type":"integer"},
            "alarm_name":{"type":"text"},
            "created_at":{"type":"date"},
            "friendly_name":{"type":"text"},
            "friendly_description":{"type":"text"},
            "icd_data":{
                "type":"object",
                "properties":{
                    "device_id":{"type":"text"},
                    "id":{"type":"keyword"},
                    "local_time":{"type":"text"},
                    "location_id":{"type":"keyword"},
                    "system_mode":{"type":"integer"},
                    "timezone":{"type":"keyword"},
                    "zone_mode":{"type":"integer"}
                }
            },
            "id":{"type":"keyword"},
            "incident_time":{"type":"date"},
            "self_resolved":{"type":"integer"},
            "self_resolved_message":{"type":"keyword"},
             
            "severity":{"type":"integer"},
            "telemetry_data":{
                "type":"object",
                "properties": {
                    "f":{"type":"float"},
                    "fd":{"type":"integer"},   
                    "fdl":{"type":"integer"},
                    "ft":{"type":"float"},
                    "ftl":{"type":"float"},
                    "m":{"type":"integer"},
                    "mafr":{"type":"float"},
                    "o":{"type":"integer"},
                    "p":{"type":"float"},
                    "pef":{"type":"float"},
                    "pefl":{"type":"float"},
                    "pmax":{"type":"float"},
                    "pmin":{"type":"float"},
                    "sw1":{"type":"integer"},
                    "sw2":{"type":"integer"},
                    "t":{"type":"float"},
                    "tmax":{"type":"float"},
                    "tmin":{"type":"float"},
                    "wf":{"type":"float"}
                }
            },
            "user_action_taken":{
                "type":"object",
                "properties":{
                    "action_id": {"type":"integer"},
                    "user_id": {"type":"keyword"},
                    "app_used": {"type":"integer"},
                    "execution_time": {"type":"date"}
                }
            },
            "users":{
                "type":"nested",
                "properties":{
                    "delivery_preferences":{"type":"integer"},
                    "user_id":{"type":"keyword"}
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

            "account":{
                "type":"object",
                "properties":{
                    "account_id": {"type":"keyword"},
                    "group_id": {"type":"keyword"}
                }
            }
        }
    }
}