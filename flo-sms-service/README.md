# flo-sms-service
Service to send text messages

## Configuring the Twilio account

To make the service work you need to set up the account access. For that, you should set some
environment variables.

For production you need to set the variables TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN

For testing you need to set the variables TWILIO_TEST_ACCOUNT_SID and TWILIO_TEST_AUTH_TOKEN

The last step to make it work in production is to set up in main/resources/application.conf the
setting twilio.fromNumber with a purchased phone number from Twilio dashboard account.

##### Kafka Contract

```javascript
{
    "id": "e7c551bd-79c6-4fbb-9bc8-bc5c1a18e4f8",
    "text": "This is an alarm",
    "phone": "+5491158898021",
    "delivery_callback": "https://api-dev.flocloud.co/api/v1/hooks/sms/efafacc1b3e977580ebf/:icd_alarm_incident_registry_id/:user_id",
    "post_delivery_callback": "https://api-dev.flocloud.co/api/v1/hooks/sms/twilio/4e3193eaa0670968e9e6/status/:icd_alarm_incident_registry_id/:user_id",   // for twilio
}
```
