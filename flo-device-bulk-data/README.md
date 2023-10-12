# serverless device bulk data service

This project hosts a set of serverless endpoints to ingest bulk data sent from devices, mainly telemetry.

## Test your service

Code to sign message: https://play.golang.org/p/sEGZi_JGkVP

### Docker

Run `make run` to start docker composer. It will host an endpoint running a lambda simulator on port 3000, you need to provide it with AWS credentials thru environment variables AWS_ACCOUNT_ID, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY and ACCOUNT_ID

```
curl --location --request POST 'http://localhost:3000/dev/bulk/v1/telemetry' \
--header 'x-data-startdate: 2019-08-24T03:34:05Z' \
--header 'x-flo-device-id: f87aef01052e' \
--header 'x-flo-signature: ad3ef0f9120bae417a459c10bcd32ad179f08427a7e5de0344702a1fbcbc4cac' \
--header 'x-flo-signature-type: HMAC-SHA256' \
--header 'x-data-version:  8.hf.csv.gz' \
--header 'Content-Type: text/plain' \
--data-raw 'H4sIAAAAAAAA/4zXMaptRRBA0dyxnOB0VVdV93T8F8FAEP/D8YupIG/lO1rZ/vz+eb5+Pj//eP5+vp4/n9/++qV//MjZn8/Ur/tZHe86sd73Vj3xrOecZ573f6pFVVCVVG2qiqqmaqg6VF2pFtkvsl9kv8h+kf0i+0X2i+wX2S+yD7IPsg+yD7IPsg+yD7IPsg+yD7JPsk+yT7JPsk+yT7JPsk+yT7JPst9kv8l+k/0m+032m+w32W+y32S/yb7Ivsi+yL7Ivsi+yL7Ivsi+yL7Ivsm+yb7Jvsm+yb7Jvsm+yb7Jvsl+yH7Ifsh+yH7Ifsh+yH7Ifsh+yP6Q/SH7Q/Ynb/X31aaqqGqqhqpD1ZXqvlQtqoIqsr9kf8n+kv0l+0v2V+zjFft4xT5esY9X7OMV+3jFPl6xj1fs4xX7eMl+kf0i+0X2i+wX2S+yX2S/yH6R/SL7IPsg+yD7IPsg+yD7IPsg+yD7IPsk+yT7JPsk+yT7JPsk+yT7JPsk+032m+w32W+y32S/yX6T/Sb7Tfab7Ivsi+yL7Ivsi+yL7Ivsi+yL7Ivsm+yb7Jvsm+yb7Jvsm+yb7Jvsm+yH7Ifsh+yH7Ifsh+yH7Ifsh+yH7A/ZH7I/ZE9fG/S1QV8b9LVBXxv0tUFfG/S1QV8b9LVBXxv0tUFfG/S1QV8b9LVBX5v0tUlfm/S1SV+b9LVJX5v0tUlfm/S1SV+b/37tfF8tqoKqpGpTVVQ1VUPVoepKFWQfZB9kH2QfZB9kH2QfZB9kH2SfZJ9kn2SfZJ9kn2SfZJ9kn2SfZL/JfpP9JvtN9pvsN9lvst9kv8l+k32RfZF9kX2RfZF9kX2RfZF9kX2RfZN9k32TfZN9k32TfZN9k32TfZP9kP2Q/ZD9kP2Q/ZD9kP2Q/ZD9kP0h+0P2h+wP2R+yP2R/yP6Q/SH7Q/aX7C/ZX7K/ZH/J/pL9JftL9pfs73/t/wEAAP//AQAA//9jAqa8mywAAA=='
```
