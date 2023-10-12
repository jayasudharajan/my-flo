import argonaut._
import argonaut.Argonaut._
import com.flo.Models.KafkaMessages.V2.EmailFeatherMessageV3NightlyReport
val ss = """{
	"client_app_name": "Email-Report-Generator-Daemon",
	"time_stamp": "2017-11-02T22:59:42+0000",
	"email_meta_data": {
		"distribution": "Internal"
	},
	"recipients": [{
		"name": "Internal Reports",
		"email_address": "nightly-reports@flotechnologies.com",
		"data": {
			"template_id": "tem_4RhGYhY3dxFfBtvwj46KHCwV",
			"esp_account": "",
			"email_template_data": {
				"data": {
					"alerts": [{
						"alarm_id": 35,
						"system_mode": "AWAY",
						"name": "Valve Open",
						"total": 2,
						"total_pending": 0,
						"total_cleared": 2,
						"total_self_resolved": 0,
						"user_action_taken": null
					}, {
						"alarm_id": 36,
						"system_mode": "AWAY",
						"name": "Valve Close",
						"total": 2,
						"total_pending": 0,
						"total_cleared": 2,
						"total_self_resolved": 0,
						"user_action_taken": null
					}, {
						"alarm_id": 15,
						"system_mode": "AWAY",
						"name": "Low Water Pressure",
						"total": 1,
						"total_pending": 1,
						"total_cleared": 0,
						"total_self_resolved": 0,
						"user_action_taken": null
					}, {
						"alarm_id": 43,
						"system_mode": "MANUAL",
						"name": "Mode Change",
						"total": 1,
						"total_pending": 0,
						"total_cleared": 1,
						"total_self_resolved": 0,
						"user_action_taken": null
					}, {
						"alarm_id": 5,
						"system_mode": "HOME",
						"name": "Health Test Successful",
						"total": 1,
						"total_pending": 0,
						"total_cleared": 1,
						"total_self_resolved": 0,
						"user_action_taken": null
					}, {
						"alarm_id": 5,
						"system_mode": "AWAY",
						"name": "Health Test Successful",
						"total": 1,
						"total_pending": 0,
						"total_cleared": 1,
						"total_self_resolved": 0,
						"user_action_taken": null
					}],
					"counts": {
						"number_of_devices_installed": 0,
						"devices_paired_count": 0,
						"devices_not_sending_telemetry_count": 0,
						"automatic_health_test_passed_count": 2,
						"manual_health_test_passed_count": 0,
						"small_leak_detected_1": 0,
						"small_leak_detected_2": 0,
						"small_leak_detected_3": 0,
						"small_leak_detected_4": 0,
						"health_test_interrupted_by_water_usage": 0,
						"manual_health_test_interrupted_by_opening_the_valve_via_app": 0,
						"auto_health_test_interrupted_by_opening_the_valve_via_app": 0,
						"health_test_interrupted_by_opening_valve_manually": 0,
						"automatic_health_test_delayed_count": 0,
						"system_shutoff_count": 0,
						"email_notifications_sent_count": 1,
						"sms_notifications_sent_count": 1,
						"voice_calls_made_count": 1,
						"push_notifications_sent_count": 1,
						"filtered_notifications_count": 1
					}
				}
			}
		}
	}],
	"id": "1f07b0514091ee2e805cd6d8af1e000c",
	"web_hook": ""
}"""

val sss = Parse.decodeOption[EmailFeatherMessageV3NightlyReport](ss)

val ssss = sss.asJson