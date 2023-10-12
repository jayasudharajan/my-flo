package com.flotechnologies

import io.reactivex.Maybe
import io.reactivex.Observable
import io.reactivex.Single
import kotlinx.serialization.DeserializationStrategy
import kotlinx.serialization.SerialName
import okhttp3.RequestBody
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.*
import java.util.*
import java.util.Collections.emptyList
import java.util.concurrent.TimeUnit
import kotlinx.serialization.Serializable
import kotlinx.serialization.Optional
import kotlinx.serialization.json.Json


/**
 * TODO default content-type and persist authentication token
 */
interface Flo {
    @Headers("Content-Type: application/json")
    @POST("users/auth")
    fun auth(@Body body: RequestBody): Observable<Credential>

    /**
     * <pre>
     * val auth = HashMap<String, String>() // retrofit-conventer usually cannot convert ArrayMap into json
     * auth.put("username", "floteam2015+dev@gmail.com")
     * auth.put("password", "Abcd1234")
     * </pre>
     */
    @Headers("Content-Type: application/json")
    @POST("users/auth")
    fun auth(@Body body: Map<String, String>): Observable<Credential>

    @Headers("Content-Type: application/json")
    @POST("oauth2/token")
    fun oauth(@Body body: Oauth): Observable<OauthToken>

    @Headers("Content-Type: application/json")
    @GET("faq/android")
    fun faq(@Header("Authorization") authorization: String): Observable<Faq>

    @Headers("Content-Type: application/json")
    @GET("waterflow/me/dailygoal")
    /** @Deprecated */
    fun dailyGoal(@Header("Authorization") authorization: String): Observable<Goal>

    @Headers("Content-Type: application/json")
    @GET("waterflow/today/total")

    /**
     * @Deprecated
     * Sum the today() usage instead
     */
    fun usageDaily(@Header("Authorization") authorization: String): Observable<Usage>

    @Headers("Content-Type: application/json")
    @GET("waterflow/monthlyusage/{dev}")
    fun usageMonthly(@Header("Authorization") authorization: String, @Path("dev") dev: String): Observable<Usage>

    @Headers("Content-Type: application/json")
    @GET("waterflow/today/{dev}")
    fun today(@Header("Authorization") authorization: String, @Path("dev") dev: String): Observable<List<String>>

    @Headers("Content-Type: application/json") @GET("faq/ios")
    fun faqIos(@Header("Authorization") authorization: String): Observable<Faq>

    @Headers("Content-Type: application/json") @GET("icds/me")
    fun icds(@Header("Authorization") authorization: String): Observable<FloDevice>

    @Headers("Content-Type: application/json") @POST("icds/me") // "{dev.json}"
    fun icds(@Header("Authorization") authorization: String, @Body dev: FloDevice): Observable<FloDevice>

    /** @Deprecated */
    @Headers("Content-Type: application/json") @GET("icds/me/alarms")
    fun alarms(@Header("Authorization") authorization: String): Observable<List<AlarmNotification>>

    /**
     * `/notifications/icd/:icd_id/pending?page=:page&size=:size`
     * By the way `total / size` will give you the number of total pages of data. Also for cleared alarms it i  the same scheme, just change pending to cleared
     *
     * @param total total number of alerts found
     * @param items Page of data within items
     * @param is_cleared Is alert cleared? (Pending alerts are `false` obviously)
     *
     * @param severity Alarm severity
     * @param updated_at Last time alert was updated.
     * @param incident_id UUID, Id of alarm in the `ICDAlarmIncidentRegistry`
     * @param alarm_id Id of the alarm
     * @param alarm_id_system_mode
     * @param icd_id
     * @param incident_time
     * @param status `AlarmNotificationDeliveryFilter` (pending will almost always be `3` which menas `Unresolved`)
     * @param system_mode
     * @param friendly_name
     * @param user_actions
     * @param ICDAlarmNotificationDeliveryRule
     *
     * <pre>
     * {"total":0,"items":[]}
     * </pre>
     */
    @Headers("Content-Type: application/json")
    @GET("notifications/icd/{icd_id}/pending")
    fun notifications(@Header("Authorization") authorization: String,
                      @Path("icd_id") icdId: String,
                      @Query("page") page: Int = 1,
                      @Query("size") size: Int = 125): Observable<Notifications>

    @Headers("Content-Type: application/json")
    @GET("notifications/icd/{icd_id}/pending/severity")
    fun severityNotifications(@Header("Authorization") authorization: String,
                              @Path("icd_id") icdId: String,
                              @Query("page") page: Int = 1,
                              @Query("size") size: Int = 125): Observable<SeverityNotifications>

    @Headers("Content-Type: application/json")
    @GET("alerts/icd/{icd_id}/alarmid")
    fun alertsGroupByAlarmId(@Header("Authorization") authorization: String,
                             @Path("icd_id") icdId: String,
                             @Query("page") page: Int = 1,
                             @Query("size") size: Int = 125): Observable<AlarmIdAggregation>

    @Headers("Content-Type: application/json")
    @GET("alerts/icd/{icd_id}/pending/severity/alarmid")
    fun pendingSeverityAlertsGroupByAlarmId(@Header("Authorization") authorization: String,
                                            @Path("icd_id") icdId: String,
                                            @Query("page") page: Int = 1,
                                            @Query("size") size: Int = 125): Observable<PendingAlarmIdAggregations>

    @Headers("Content-Type: application/json")
    @GET("alerts/icd/{icd_id}/pending/severity")
    fun alerts(@Header("Authorization") authorization: String,
               @Path("icd_id") icdId: String,
               @Query("page") page: Int = 1,
               @Query("size") size: Int = 999): Observable<SeverityNotifications>

    @Headers("Content-Type: application/json")
    @POST("alerts/icd/{icd_id}/clear")
    fun clearAlerts(@Header("Authorization") authorization: String,
                    @Path("icd_id") icdId: String,
                    @Body data: AlarmData): Observable<ResponseBody>

    @Headers("Content-Type: application/json")
    @GET("alerts/icd/{icd_id}/cleared")
    fun clearedAlerts(@Header("Authorization") authorization: String,
                      @Path("icd_id") icdId: String,
                      @Query("page") page: Int = 1,
                      @Query("size") size: Int = 999): Observable<Notifications>

    @Headers("Content-Type: application/json")
    @POST("alerts/icd/{icd_id}/pending")
    fun filterPendingAlerts(@Header("Authorization") authorization: String,
                      @Path("icd_id") icdId: String,
                      @Query("page") page: Int = 1,
                      @Query("size") size: Int = 125,
                      @Body filter: AlertFilter): Observable<Notifications>


    @Headers("Content-Type: application/json")
    @GET("alerts/icd/{icd_id}")
    fun alertsLog(@Header("Authorization") authorization: String,
                      @Path("icd_id") icdId: String,
                      @Query("page") page: Int = 1,
                      @Query("size") size: Int = 999): Observable<Notifications>

    //@Headers("Content-Type: application/json")
    //@GET("notifications/icd/{icd_id}/pending")
    //fun notifications(@Header("Authorization") authorization: String,
    //           @Path("icd_id") icdId: String): Observable<List<AlarmNotification>>

    @Headers("Content-Type: application/json") @POST("icds/me/alarms/clear") //	""
    fun clearAlarms(@Header("Authorization") authorization: String): Observable<String>

    /**
     * @param total total number of alerts found
     * @param items Page of data within items
     * @param is_cleared Is alert cleared? (Pending alerts are `false` obviously)
     * @param severity Alarm severity
     * @param updated_at Last time alert was updated.
     * @param incident_id UUID, Id of alarm in the `ICDAlarmIncidentRegistry`
     * @param alarm_id Id of the alarm
     * @param alarm_id_system_mode
     * @param icd_id
     * @param incident_time
     * @param status `AlarmNotificationDeliveryFilter`
     *               (pending will almost always be `3` which menas `Unresolved`)
     * @param system_mode
     * @param friendly_name
     * @param user_actions
     * @param ICDAlarmNotificationDeliveryRule
     *
     */
    @Headers("Content-Type: application/json")
    @GET("notifications/icd/{icd_id}/cleared")
    fun clearedNotifications(@Header("Authorization") authorization: String,
                             @Path("icd_id") icdId: String,
                             @Query("page") page: Int = 1,
                             @Query("size") size: Int = 25
    ): Observable<Notifications>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/display/FLO/Severity+Endpoint+Discussion
     * ref. https://flotechnologies.atlassian.net/wiki/display/FLO/Rules+For+Alarm+Conditions
     */
    @Headers("Content-Type: application/json") @GET("icds/me/alarms/severe")
    fun severeAlarms(@Header("Authorization") authorization: String): Observable<SevereAlarm>

    @Headers("Content-Type: application/json") @POST("icds/me/alarms/useraction") // "{alarm-action.json}"
    fun action(@Header("Authorization") authorization: String, @Body action: AlarmAction): Observable<ResponseBody>

    @Headers("Content-Type: application/json") @GET("locations/me")
    fun locations(@Header("Authorization") authorization: String): Observable<HomeProfile>

    /** @Deprecated */
    @Headers("Content-Type: application/json") @PUT("locations/me") // "{home-profile.json}"
    fun locations(@Header("Authorization") authorization: String, @Body action: HomeProfile): Observable<HomeAttributes>

    @Headers("Content-Type: application/json") @PUT("locations/{account_id}/{location_id}") // "{home-profile.json}"
    fun locations(@Header("Authorization") authorization: String,
                  @Path("account_id") accountId: String,
                  @Path("location_id") locationId: String,
                  @Body homeProfile: HomeProfile): Observable<HomeAttributes>

    @Headers("Content-Type: application/json") @POST("mqtt/client/powerreset/{device-id}") // "{?}"
    fun powerreset(@Header("Authorization") authorization: String, @Path("device-id") dev: String): Observable<ResponseBody>
    //@Headers("Content-Type: application/json") @POST("mqtt/client/powerreset/{d}")	"{}"

    @Headers("Content-Type: application/json") @POST("mqtt/client/setsystemmode/{device-id}") // "{system-mode.json}"
    fun systemMode(@Header("Authorization") authorization: String, @Path("device-id") dev: String, @Body mode: SystemMode): Single<ResponseBody>

    @Headers("Content-Type: application/json") @POST("mqtt/client/sleep/{device-id}") // "{sleep-mode.json}"
    fun sleep(@Header("Authorization") authorization: String, @Path("device-id") dev: String, @Body mode: SleepMode): Observable<ResponseBody>

    @Headers("Content-Type: application/json") @POST("icds/device/{device-id}/togglevalve/open/12") // "{?}"
    fun openValve(@Header("Authorization") authorization: String, @Path("device-id") dev: String): Observable<ResponseBody>

    @Headers("Content-Type: application/json") @POST("icds/device/{device-id}/togglevalve/close/9") // "{?}"
    fun closeValve(@Header("Authorization") authorization: String, @Path("device-id") dev: String): Observable<ResponseBody>

    @Headers("Content-Type: application/json") @POST("icds/device/{device-id}/togglevalve/open/11") // "{?}"
    fun openValveByAlarm(@Header("Authorization") authorization: String, @Path("device-id") dev: String): Observable<ResponseBody>

    @Headers("Content-Type: application/json") @POST("icds/device/{device-id}/togglevalve/close/8") // "{?}"
    fun closeValveByAlarm(@Header("Authorization") authorization: String, @Path("device-id") dev: String): Observable<ResponseBody>

    //@Headers("Content-Type: application/json") @POST("mqtt/client/togglevalve/{d}/close")	"{?}"
    //@Headers("Content-Type: application/json") @POST("mqtt/client/togglevalve/{d}/open")	"{?}"

    @Headers("Content-Type: application/json") @POST("mqtt/client/zittest/{device-id}") // "{}"
    fun testZi(@Header("Authorization") authorization: String, @Path("device-id") dev: String): Observable<ResponseBody>

    @Headers("Content-Type: application/json") @POST("notificationtokens/me/addtoken") // "{token}"
    fun addToken(@Header("Authorization") authorization: String, @Body token: UserToken): Observable<ResponseBody>

    /**
     * QrCode - scan - Purchase - Cert
     * devId - QrCode - scan - Purchase - Cert
     */
    @Headers("Content-Type: application/json")
    @POST("stockicds/qrcode") // "{purchase-icd.json}"
    fun certificate(@Header("Authorization") authorization: String,
                    @Body icd: Purchase): Observable<Certificate>

    @Headers("Content-Type: application/json")
    @POST("stockicds/qrcode") // "{purchase-icd.json}"
    fun certificate(@Header("Authorization") authorization: String,
                    @Body icd: PurchaseV1): Observable<Certificate>

    @Headers("Content-Type: application/json")
    @POST("stockicds/qrcode") // "{purchase-icd.json}"
    fun certificate(@Header("Authorization") authorization: String,
                    @Body icd: PurchaseV2): Observable<Certificate>

    @Headers("Content-Type: application/json")
    @POST("pairing/qrcode") // "{purchase-icd.json}"
    fun certificate2(@Header("Authorization") authorization: String,
                     @Body icd: Purchase): Observable<Certificate>

    /**
     * Remove a Flo device pairing
     *
     * @param icd_id	UUID (String)	ICD ID of the device
     *
     * Response Body
     *
     * true
     *
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/560824321/Pairing+Endpoints
     */
    @Headers("Content-Type: application/json")
    @POST("pairing/unpair/{icd_id}")
    fun unpair(@Header("Authorization") authorization: String,
               @Path("icd_id") icdId: String): Observable<ResponseBody>

    /**
     * Retrieves the same data as scanning a QR code for an already paired device. To be used when reconnecting an already paired Flo device to WiFi or reinitializing an already paired Flo device after a factory reset.
     * URL Params
     *
     * @param icd_id	UUID (String)	ICD ID of the device
     *
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/560824321/Pairing+Endpoints
     */
    @Headers("Content-Type: application/json")
    @GET("pairing/qr/icd/{icd_id}")
    fun certificate(@Header("Authorization") authorization: String,
                    @Path("icd_id") icdId: String): Observable<Certificate>

    /**
     * /api/v1/stockicds/device/8cc7aa027800/qrcode
     */
    @Headers("Content-Type: application/json") @GET("stockicds/device/{device-id}/qrcode")
    fun qrcode(@Header("Authorization") authorization: String, @Path("device-id") dev: String): Observable<QrCode>

    @Headers("Content-Type: application/json") @GET("/icds/device/{device-id}")
    fun device(@Header("Authorization") authorization: String, @Path("device-id") dev: String): Observable<FloDevice>

    @Headers("Content-Type: application/json") @GET("timezones/active")
    fun timezones(@Header("Authorization") authorization: String): Observable<List<TimeZone>>

    @Headers("Content-Type: application/json")
    @GET("userdetails/me")
    fun userDetails(@Header("Authorization") authorization: String): Observable<UserProfile>

    @Headers("Content-Type: application/json")
    @GET("users/me")
    fun me(@Header("Authorization") authorization: String): Observable<UserProfile>

    @Headers("Content-Type: application/json")
    @PUT("userdetails/me") // "{user-profile.json}"
    fun userDetails(@Header("Authorization") authorization: String, @Body profile: UserProfile): Observable<UserAttributes>

    @Headers("Content-Type: application/json")
    @POST("users/auth") // "{user.json}"
    fun auth(@Body login: Login): Observable<Credential>

    /**
     * ref. https://github.com/FloTechnologies/flo-ios-app/blob/21e9b16/Flo/Flo/LeftMenuViewController.swift#L147
     */
    @Headers("Content-Type: application/json") @POST("users/logout") // "{user-logout.json}"
    fun logout(@Header("Authorization") authorization: String, @Body logout: Logout): Observable<ResponseBody>

    @Headers("Content-Type: application/json") @POST("logout/")
    fun logout2(@Header("Authorization") authorization: String, @Body logout: Logout2): Observable<ResponseBody>

    @Headers("Content-Type: application/json") @POST("logout/")
    fun logout2(@Header("Authorization") authorization: String, @Body logout: Logout3): Observable<ResponseBody>

    /**
     * mobile_device_id	String	Unique identifier for the mobile device. iOS devices should use identifierForVendor (https://developer.apple.com/documentation/uikit/uidevice/1620059-identifierforvendor) and Android devices should use instance ID
     * token	String	The push notification token to be associated with the mobile device
     *
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/67862547/Notification+Tokens+v2
     */
    @Headers("Content-Type: application/json")
    @POST("pushnotificationtokens/android")
    fun addPushNotificationToken(@Header("Authorization") authorization: String,
                                 @Body token: PushNotificationToken): Single<ResponseBody>

    /**
     * @return {
     *   mobile_device_id: String,
     *   client_id: UUID,
     *   user_id: UUID,
     *   token: String,
     *   client_type: Integer,
     *   created_at: Date,
     *   updated_at: Date,
     *   is_disabled: Optional<Integer>
     * }
     *
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/67862547/Notification+Tokens+v2
     */
    @Headers("Content-Type: application/json")
    @GET("pushnotificationtokens/user/{user_id}")
    fun getPushNotificationTokenList(@Header("Authorization") authorization: String,
                                  @Path("user_id") userId: String): Observable<List<PushNotificationToken>>

    @Headers("Content-Type: application/json") @POST("users/register") // "{register.json}"
    fun register(@Body register: Register): Observable<Credential>

    @Headers("Content-Type: application/json") @GET("users/register/{token1}/{token2}")
    fun register(@Path("token1") token1: String, @Path("token2") token2: String): Observable<Register>

    @Headers("Content-Type: application/json") @POST("users/requestreset/user") // "{forgot-password.json}"
    fun resetUser(@Body forgotPassword: ForgotPassword): Observable<Message>

    // Flo/Flo/AppDelegate.swift
    @Headers("Content-Type: application/json") @GET("icdalarmnotificationdeliveryrules/{alarm-id}/{system-mode}")
    fun icdAlarmNotificationDeliveryRules(@Header("Authorization") authorization: String,
                                          @Path("alarm-id") alarmId: Int,
                                          @Path("system-mode") systemMode: Int): Observable<ResponseBody>

    // AlarmProfileViewController.swift
    @Headers("Content-Type: application/json") @GET("alarmnotificationdeliveryfilters/{device-id}/{alarm-id}/{system-mode}")
    fun alarmNotificationDeliveryFilters(@Header("Authorization") authorization: String,
                                         @Path("device-id") dev: String,
                                         @Path("alarm-id") alarmId: Int,
                                         @Path("system-mode") systemMode: Int): Observable<SevereAlarm>


    /**
     * {
     *     "icd_id": "e786919c-fe1c-44e9-9745-f90442ca9d33",
     *     "event": 3,
     *     "created_at": "2017-11-02T18:12:56.887Z"
     * }
     *
     * Legend for "event":
     * 1 = Paired
     * 2 = Installed
     * 3 = Force sleep removed
     *
     * ref. https://goo.gl/b8njLs
     */
    @Headers("Content-Type: application/json") @GET("onboarding/icd/{icd-id}/current")
    fun onboarding(@Header("Authorization") authorization: String,
                   @Path("icd-id") dev: String): Observable<Icd>

    /**
     * Required permission
     * 403/Forbidden
     */
    @Headers("Content-Type: application/json")
    @GET("notificationtokens/{user-id}")
    @Permission(["admin"])
    fun notificationTokens(@Header("Authorization") authorization: String,
                           @Path("user-id") userId: String): Observable<NotificationTokens>

    //@Headers("Content-Type: application/json") @GET("waterflow/me/dailygoal")

    //@Headers("Content-Type: application/json") @GET("waterflow/monthlyusage/{device-id}")
    //@Headers("Content-Type: application/json") @GET("waterflow/today/{device-id}")


    @Headers("Content-Type: application/json")
    @GET("stockicds/device/{device_id}/token")
    @Permission(["admin"])
    fun websocketToken(@Header("Authorization") authorization: String, @Path("device_id") dev: String): Observable<WebsocketToken>

    /**
     * NOTICE: v2
     *
     * /api/v2/notificationtokens/:user_id/:mobile_device_id
     *
     * <pre>
     * {
     *   token: String
     * }
     * </pre>
     *
     * @param userId UUID, User's ID. Note: this can be replaced with me
     *               (e.g. /notificationtokens/me/:mobile_device_id) where me will be automatically
     *               replaced by the User ID associated with the authentication token provided
     *               in the Authorization header.
     * @param appId ID of the mobile device associated with the notification token
     * ref. https://flotechnologies.atlassian.net/wiki/display/FLO/Notification+Tokens+v2
     */
    @Headers("Content-Type: application/json")
    @POST("notificationtokens/{user-id}/{device-type}/{mobile-device-id}")
    fun notificationTokens(@Header("Authorization") authorization: String,
                           @Path("user-id") userId: String,
                           @Path("mobile-device-id") appId: String,
                           @Path("device-type") deviceType: String,
                           @Body body: Map<String, String>): Observable<ResponseBody>

    /**
     * NOTICE: v2
     *
     * /api/v2/notificationtokens/:user_id/:mobile_device_id
     *
     * @param userId UUID, User's ID. Note: this can be replaced with me
     *               (e.g. /notificationtokens/me/:mobile_device_id) where me will be automatically
     *               replaced by the User ID associated with the authentication token provided
     *               in the Authorization header.
     * @param appId ID of the mobile device associated with the notification token
     *
     * ref. https://flotechnologies.atlassian.net/wiki/display/FLO/Notification+Tokens+v2
     */
    @Headers("Content-Type: application/json")
    @DELETE("notificationtokens/{user-id}/{device-type}/{mobile-device-id}")
    fun deleteNotificationTokens(@Header("Authorization") authorization: String,
                                 @Path("user-id") userId: String,
                                 @Path("device-type") deviceType: String,
                                 @Path("mobile-device-id") appId: String): Observable<ResponseBody>

    /**
     * NOTICE: v2
     *
     * ref. https://flotechnologies.atlassian.net/wiki/display/FLO/Notification+Tokens+v2
     */
    @Headers("Content-Type: application/json")
    @DELETE("notificationtokens/{user-id}/{device-type}/active")
    fun activeNotificationTokens(@Header("Authorization") authorization: String,
                                 @Path("user-id") userId: String,
                                 @Path("device-type") deviceType: String): Observable<NotificationTokens>

    /**
     * NOTICE: v2
     *
     * /api/v2/notificationtokens/:user_id/:mobile_device_id
     *
     * <pre>
     * {
     *   token: String
     * }
     * </pre>
     *
     * @param userId UUID, User's ID. Note: this can be replaced with me
     *               (e.g. /notificationtokens/me/:mobile_device_id) where me will be automatically
     *               replaced by the User ID associated with the authentication token provided
     *               in the Authorization header.
     * @param appId ID of the mobile device associated with the notification token
     * ref. https://flotechnologies.atlassian.net/wiki/display/FLO/Notification+Tokens+v2
     */
    @Headers("Content-Type: application/json")
    @POST("notificationtokens/{user-id}/{mobile-device-id}")
    fun notificationTokens(@Header("Authorization") authorization: String,
                           @Path("user-id") userId: String,
                           @Path("mobile-device-id") appId: String,
                           @Body body: Map<String, String>): Observable<ResponseBody>

    /**
     * NOTICE: v2
     *
     * /api/v2/notificationtokens/:user_id/:mobile_device_id
     *
     * @param userId UUID, User's ID. Note: this can be replaced with me
     *               (e.g. /notificationtokens/me/:mobile_device_id) where me will be automatically
     *               replaced by the User ID associated with the authentication token provided
     *               in the Authorization header.
     * @param appId ID of the mobile device associated with the notification token
     *
     * ref. https://flotechnologies.atlassian.net/wiki/display/FLO/Notification+Tokens+v2
     */
    @Headers("Content-Type: application/json")
    @DELETE("notificationtokens/{user-id}/{mobile-device-id}")
    fun deleteNotificationTokens(@Header("Authorization") authorization: String,
                                 @Path("user-id") userId: String,
                                 @Path("mobile-device-id") appId: String): Observable<ResponseBody>

    /**
     * NOTICE: v2
     *
     * ref. https://flotechnologies.atlassian.net/wiki/display/FLO/Notification+Tokens+v2
     */
    @Headers("Content-Type: application/json")
    @DELETE("notificationtokens/{user-id}/active")
    fun activeNotificationTokens(@Header("Authorization") authorization: String,
                                 @Path("user-id") userId: String): Observable<NotificationTokens>

    /**
     */
    @Headers("Content-Type: application/json")
    @GET("countrystateprovinces/{country}")
    fun stateProvinces(@Header("Authorization") authorization: String,
                       @Path("country") country: String): Observable<List<String>>

    /**
     */
    @Headers("Content-Type: application/json")
    @GET("countrystateprovinces/{country}")
    fun stateProvinces(@Path("country") country: String): Observable<List<String>>

    /**
     * Sign Up with Email
     * Make sure email is registered or not
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/84639748/In-App+User+Registration
     */
    @Headers("Content-Type: application/json")
    @POST("userregistration")
    fun registration(@Body registration: Register): Observable<Response<String>>

    /**
     * 2.
     * Populate non-activate account profile
     * POST /api/v1/userregistration/:session_id?nonce=:nonce
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/84639748/In-App+User+Registration
     */
    @Headers("Content-Type: application/json")
    @POST("userregistration/{session-id}")
    fun registration(@Path("session-id") sessionId: String,
                     @Query("nonce") nonce: String,
                     @Body registration: Register): Observable<Session>

    /**
     * {
     *   "token": RegistrationToken
     * }
     */
    @Headers("Content-Type: application/json")
    @POST("userregistration/verify/oauth2")
    fun verifyRegistrationOauth(@Body body: Oauth): Observable<OauthToken>

    /**
     * This begins the passwordless magic link flow by sending the user an email containing
     * a magic link.
     * This link is good for one hour from the time sent and is single use only.
     * 201 Created	Success	If the email exists, then the magic link has been sent
     * 401 Unauthorized	Error	Invalid client_id/client_secret
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/125272169/Passwordless+Magic+Link
     */
    @Headers("Content-Type: application/json")
    @POST("passwordless/start")
    fun passwordlessSend(@Body oauth: Oauth): Observable<ResponseBody>


    /**
     * When the user opens their email, they will be presented with a link that will redirect them
     * to a deep link into the app.
     * The app deep link is formatted as {{app name}}://login/:user_id/:passwordless_token/:single_use_token.
     * Match these / separated fields to the params of the URL in the next step
     *
     * 302 Found	Success	Redirect to app deep link
     * 400 Bad Request	Error	Token is invalid, expired, or has already been used
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/125272169/Passwordless+Magic+Link
     */
    @Headers("Content-Type: application/json")
    @GET("passwordless/{user_id}/{passwordless_token}")
    fun passwordlessDeepLink(@Path("user_id") userId: String,
                             @Path("passwordless_token") token: String,
                             @Query("t") singleUseToken: String): Observable<ResponseBody>

    /**
     * The app will POST the URI parameters included in the app deep link in order to
     * retrieve an OAuth2 access and refresh token.
     * 200 OK	Success	See response below
     * 400 Bad Request	Error	Token is invalid, expired, or has already been used
     * 401 Unauthorized	Error	Invalid client_id/client_secret
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/125272169/Passwordless+Magic+Link
     */
    @Headers("Content-Type: application/json")
    @POST("passwordless/{user_id}/{passwordless_token}")
    fun passwordlessOauth(@Path("user_id") userId: String,
                          @Path("passwordless_token") token: String,
                          @Query("t") singleUseToken: String,
                          @Body oauth: Oauth): Observable<OauthToken>

    /**
     * 3.
     * Terms?
     * POST /api/v1/userregistration/:session_id?nonce=:nonce
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/84639748/In-App+User+Registration
     */
    @Headers("Content-Type: application/json")
    @POST("userregistration/{session-id}")
    fun sendEmailVerification(@Path("session-id") sessionId: String,
                          @Query("nonce") nonce: String): Observable<ResponseBody>
    //@Body body: RequestBody): Observable<ResponseBody>

    /**
     * 404
     * Registration not found
     * There is no pending registration confirmation to resend. Either there is no registration,
     * email is already confirmed, or registration has expired
     *
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/84639748/In-App+User+Registration
     */
    @Headers("Content-Type: application/json")
    @POST("userregistration/resend")
    fun resendEmailVerification(@Body email: Email): Observable<ResponseBody>


    /**
     * 5.
     * getToken
     * POST /api/v1/userregistration/:session_id?nonce=:nonce
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/84639748/In-App+User+Registration
     */
    @Headers("Content-Type: application/json")
    @POST("userregistration/{session-id}")
    fun registrationToken(@Path("session-id") sessionId: String,
                          @Query("nonce") nonce: String): Observable<Credential>

    /**
     * getToken
     * GET /api/v1/userregistration/:session_id
     * 200	true	The session is still in progress
     * 400	Session terminated.	Session was completed by the user
     * 400	Session expired.	Session has expired before it could be completed
     * 404	Session not found.	No such session exists
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/84639748/In-App+User+Registration
     */
    @Deprecated(
            "use Flo.emailStatus for oauth",
            replaceWith = ReplaceWith(
                    "emailStatus()",
                    "com.flotechnologies.Flo"))
    @Headers("Content-Type: application/json")
    @POST("userregistration/{session-id}")
    fun sessionStatus(@Path("session-id") sessionId: String): Observable<Response<String>>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/85786625/Locales
     */
    @Headers("Content-Type: application/json")
    @GET("locales")
    fun locales(): Observable<Locales>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/85786625/Locales
     */
    @Headers("Content-Type: application/json")
    @GET("locales/{locale}")
    fun locale(@Path("locale") locale: String): Observable<Locale>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/84639748/In-App+User+Registration
     */
    @Headers("Content-Type: application/json")
    @POST("userregistration/verify")
    fun registrationToken(@Body registrationToken: RegistrationToken): Observable<Credential>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/84639748/In-App+User+Registration
     */
    @Headers("Content-Type: application/json")
    @POST("userregistration/email")
    fun emailStatus(@Body email: Email): Observable<EmailStatus>

    /**
     * /waterflow/measurement/icd/e786919c-fe1c-44e9-9745-f90442ca9d33/last_week
     * Your response should be as such:
     * [
     * {
     *     "average_flowrate": 0,
     *     "average_temperature": 0,
     *     "average_pressure": 0,
     *     "total_flow": 0,
     *     "did": "f87aef01019c",
     *     "time": "2017-11-04T08:00:00.000Z"
     * },
     * {
     *     "average_flowrate": 0,
     *     "average_pressure": 49.15863210148876,
     *     "average_temperature": 76,
     *     "did": "f87aef01019c",
     *     "total_flow": 0,
     *     "time": "2017-11-05T07:00:00.000Z"
     * },
     * {
     *     "average_flowrate": 0,
     *     "average_pressure": 44.602536531569264,
     *     "average_temperature": 75,
     *     "did": "f87aef01019c",
     *     "total_flow": 0,
     *     "time": "2017-11-06T08:00:00.000Z"
     * },
     * {
     *     "average_flowrate": 0,
     *     "average_pressure": 58.058491604734485,
     *     "average_temperature": 76,
     *     "did": "f87aef01019c",
     *     "total_flow": 0.6140854999999998,
     *     "time": "2017-11-07T08:00:00.000Z"
     * },
     * {
     *     "average_flowrate": 0,
     *     "average_pressure": 58.0247797356839,
     *     "average_temperature": 75.60820484581498,
     *     "did": "f87aef01019c",
     *     "total_flow": 0,
     *     "time": "2017-11-08T08:00:00.000Z"
     * },
     * {
     *     "average_flowrate": 0,
     *     "average_pressure": 59.968529735682786,
     *     "average_temperature": 77,
     *     "did": "f87aef01019c",
     *     "total_flow": 0,
     *     "time": "2017-11-09T08:00:00.000Z"
     * }
     * ]
     * The bars in the bar graph should be used from value "total_flow"
     * ref. https://flotechnologies-jira.atlassian.net/projects/AND/issues/AND-84
     */
    @Headers("Content-Type: application/json")
    @GET("waterflow/measurement/icd/{icd-id}/last_week")
    fun lastWeekWaterConsumption(@Header("Authorization") authorization: String,
                                 @Path("icd-id") dev: String): Observable<List<Consumption>>

    @Headers("Content-Type: application/json")
    @GET("waterflow/measurement/icd/{icd-id}/this_week")
    fun thisWeekWaterConsumption(@Header("Authorization") authorization: String,
                                 @Path("icd-id") dev: String): Observable<List<Consumption>>

    @Headers("Content-Type: application/json")
    @GET("icds/group/{device-id}")
    fun groupOfDevice(@Header("Authorization") authorization: String,
                      @Path("device-id") deviceId: String): Observable<String>

    @Headers("Content-Type: application/json")
    @GET("mqtt/perms")
    fun mqttTopicPermissions(@Header("Authorization") authorization: String): Observable<List<MqttTopicPermission>>

    /**
     * /api/v1/fixtures/detection/run/:device_id
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     */
    @Headers("Content-Type: application/json")
    @POST("fixtures/detection/run/{device-id}")
    fun runFixturesDetection(@Header("Authorization") authorization: String,
                             @Path("device-id") dev: String,
                             @Body duration: Duration): Observable<KafkaRequest>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     */
    @Headers("Content-Type: application/json")
    @POST("fixtures/detection/{device-id}")
    fun logFixtureDetection(@Header("Authorization") authorization: String,
                            @Path("device-id") dev: String,
                            @Body request: KafkaRequest): Observable<KafkaRequest>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     */
    @Headers("Content-Type: application/json")
    @GET("fixtures/detection/results/{device-id}/{request-id}")
    fun retrieveFixtureDetection(@Header("Authorization") authorization: String,
                                 @Path("device-id") dev: String,
                                 @Path("request-id") requestId: String): Observable<KafkaRequest>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     */
    @Headers("Content-Type: application/json")
    @GET("fixtures/detection/results/{device-id}/{start-date}/{end-date}")
    fun retrieveFixtureDetectionWithDuration(@Header("Authorization") authorization: String,
                                             @Path("device-id") deviceId: String,
                                             @Path("start-date") startDate: String,
                                             @Path("end-date") endDate: String): Observable<KafkaRequest>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     */
    @Headers("Content-Type: application/json")
    @GET("fixtures/detection/latest/{request-id}")
    fun retrieveLatestFixtureDetection(@Header("Authorization") authorization: String,
                                       @Path("request-id") requestId: String): Observable<KafkaRequest>


    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/302317581/HomeProtect+Mobile+Changes
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/255197185/Account+Subscriptions
     */
    @Headers("Content-Type: application/json")
    @GET("subscriptions/user/{user_id}")
    fun subscriptionWithUserId(@Header("Authorization") authorization: String,
                               @Path("user_id") userId: String): Observable<FloSubscription>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/302317581/HomeProtect+Mobile+Changes
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/255197185/Account+Subscriptions
     */
    @Headers("Content-Type: application/json")
    @GET("subscriptions/{account_id}")
    fun subscriptionWithAccountId(@Header("Authorization") authorization: String,
                                  @Path("account_id") accountId: String): Observable<FloSubscription>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/255197185/Account+Subscriptions
     */
    @Headers("Content-Type: application/json")
    @GET("subscriptions/plan/{plan_id}")
    fun plan(@Header("Authorization") authorization: String,
             @Path("plan_id") planId: String): Observable<FloPlan>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/255197185/Account+Subscriptions
     */
    @Headers("Content-Type: application/json")
    @POST("subscriptions/user/{user_id}/payment/stripe")
    fun paymentWithUserId(@Header("Authorization") authorization: String,
                          @Path("user_id") userId: String,
                          @Body body: FloPayment): Observable<ResponseBody>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/326697008/Mobile+Notification+Changes
     */
    @Headers("Content-Type: application/json")
    @GET("useralarmnotificationdeliveryrules/userlocation/{user_id}/{location_id}")
    fun userNotificationPreferences(@Header("Authorization") authorization: String,
                                    @Path("user_id") userId: String,
                                    @Path("location_id") locationId: String): Observable<List<AlarmPreference>>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/326697008/Mobile+Notification+Changes
     */
    @Headers("Content-Type: application/json")
    @GET("icdalarmnotificationdeliveryrules/scan")
    fun icdNotificationPreferences(@Header("Authorization") authorization: String): Observable<AlarmPreferences>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/326697008/Mobile+Notification+Changes
     */
    @Headers("Content-Type: application/json")
    @POST("useralarmnotificationdeliveryrules/")
    fun userAlarmPreference(@Header("Authorization") authorization: String,
                            @Body preference: AlarmPreference): Observable<ResponseBody>

    /**
     * Log executed computations for a device
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
     */
    @Headers("Content-Type: application/json")
    @POST("flodetect/{device_id}")
    fun addFloDetect(@Header("Authorization") authorization: String,
                     @Path("device_id") userId: String,
                     @Body floDetect: FloDetect): Observable<ResponseBody>

    /**
     * retrieve the latest executed computation of a specific duration.
     *
     * Legacy version of this endpoint will return a 404 for computations whose status is not executed or feedback_submitted
     *
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
     */
    @Headers("Content-Type: application/json")
    @GET("flodetect/computations/latest/{device_id}/{duration}")
    fun getFloDetect(@Header("Authorization") authorization: String,
                     @Path("device_id") deviceId: String,
                     @Path("duration") seconds: Long): Observable<FloDetect>


    /**
     * retrieve the latest executed computation of a specific duration
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
     */
    @Headers("Content-Type: application/json")
    @GET("flodetect/averages/latest/{device_id}/{duration}")
    fun getFloDetectAverages(@Header("Authorization") authorization: String,
                     @Path("device_id") deviceId: String,
                     @Path("duration") seconds: Long): Observable<FloDetectAverages>

    /**
     * retrieve the latest executed computation of a specific duration
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
     */
    @Headers("Content-Type: application/json")
    @GET("flodetect/latest/{device_id}/{duration}")
    fun getFloDetectWithTimeZone(@Header("Authorization") authorization: String,
                                 @Path("device_id") deviceId: String,
                                 @Query("tz") timeZone: String): Observable<FloDetect>
    /**
     * submit feedback on the accuracy of a computation. The status of the record will change to "feedback_submitted"
     * @param start ISO 8601 Date
     * @param end ISO 8601 Date
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
     */
    @Headers("Content-Type: application/json")
    @POST("feedback/{device_id}/{start_date}/{end_date}")
    fun feedback(@Header("Authorization") authorization: String,
                 @Path("device_id") deviceId: String,
                 @Path("start_date") start: String,
                 @Path("end_date") end: String,
                 @Body feedbacks: FloDetectFeedbacks): Observable<FlowEvent>

    /**
     * retrieve the latest computation within a specific time range. This is useful to retrieve computations that for midnight-to-midnight periods, for example.
     * Legacy version of this endpoint will return a 404 for computations whose status is not executed or feedback_submitted
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
     */
    @Headers("Content-Type: application/json")
    @GET("flodetect/computations/latest/{device_id}/{duration}/range/{range_start}/{range_end}")
    fun getFloDetectRange(@Header("Authorization") authorization: String,
                          @Path("device_id") deviceId: String,
                          @Path("duration") seconds: Long,
                          @Path("range_start") start: String,
                          @Path("range_end") end: String): Observable<FloDetect>

    /**
     * retrieve the latest computation within a specific time range.
     * This is useful to retrieve computations that for midnight-to-midnightperiods,
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
     */
    @Headers("Content-Type: application/json")
    @GET("flodetect/latest/{device_id}/{duration}/range/{range_start}/{range_end}")
    fun getFloDetectRangeWithTimeZone(@Header("Authorization") authorization: String,
                                      @Path("device_id") deviceId: String,
                                      @Path("duration") seconds: Long,
                                      @Path("range_start") start: String,
                                      @Path("range_end") end: String,
                                      @Query("tz") timeZone: String): Observable<FloDetect>

    /**
     * Batch insertion of flow events related to a Flo Detect Generator computation specified by device ID and request ID.
     * It's recommend to keep thebatch size under 150 events at a time
     *
     * device_id
     * Device Id (String)
     * Device ID of the device for which the computation was performed
     * request_id
     * UUID (String)
     * Unique ID of the computation request
     *
     * <pre>
     * {"event_chronology": [FlowEvent]}
     * </pre>
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
     */
    @Headers("Content-Type: application/json")
    @POST("flodetect/event/{device_id}/{request_id}")
    fun addFloDetect(@Header("Authorization") authorization: String,
                     @Path("device_id") deviceId: String,
                     @Path("request_id") requestId: String,
                     @Body flodetect: FloDetect): Observable<ResponseBody>

    /**
     * Retrieves a page of flow events for a given device id and computation request ID.
     * Results are returned in either descending (by default) orascending order according to the  property of the FlowEvent object.
     * Retrieve the next page by providing the  property value of thestartstartlast object in the response array to the ?start querystring parameter.
     *
     * @param device_id Device ID of the device for which the computation was performed
     * @param request_id Unique ID of the computation request
     * @param start Date from which to start the next page. This date is exclusive, so all records will be guaranteed AFTER (for
    ascending order) or BEFORE (for descending order) this date. Leave undefined to retrieve the first page.
     * @param size Number of records to return in page. Recommended < 100.
     * @param desc Should results be returned in descending date or not. NOTE: This is true by default.
     * @return The response body is a JSON array of FlowEvent objects
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
     */
    @Headers("Content-Type: application/json")
    @GET("flodetect/event/{device_id}/{request_id}")
    fun getFlowEventsPaged(@Header("Authorization") authorization: String,
                           @Path("device_id") deviceId: String,
                           @Path("request_id") requestId: String,
                           @Query("start") start: String,
                           @Query("size") size: Int,
                           @Query("desc") descending: Boolean): Observable<List<FlowEvent>>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
     */
    @Headers("Content-Type: application/json")
    @GET("flodetect/event/{device_id}/{request_id}")
    fun getFlowEventsPaged(@Header("Authorization") authorization: String,
                           @Path("device_id") deviceId: String,
                           @Path("request_id") requestId: String,
                           @Query("start") start: String,
                           @Query("size") size: Int): Observable<List<FlowEvent>>

    @Headers("Content-Type: application/json")
    @GET("flodetect/event/{device_id}/{request_id}")
    fun getFlowEventsPaged(@Header("Authorization") authorization: String,
                           @Path("device_id") deviceId: String,
                           @Path("request_id") requestId: String,
                           @Query("size") size: Int): Observable<List<FlowEvent>>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
     */
    @Headers("Content-Type: application/json")
    @GET("flodetect/event/{device_id}/{request_id}")
    fun getFlowEventsPaged(@Header("Authorization") authorization: String,
                           @Path("device_id") deviceId: String,
                           @Path("request_id") requestId: String): Observable<List<FlowEvent>>

    /**
     * Submit feedback for a specific FlowEvent
     *
     * @param device_id Device ID of the device for which the computation was performed
     * @param request_id Unique ID of the computation request
     * @param start property of FlowEvent record to be modified as URI encoded string
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
     */
    @Headers("Content-Type: application/json")
    @POST("flodetect/event/{device_id}/{request_id}/{start}/feedback")
    fun feedback(@Header("Authorization") authorization: String,
                 @Path("device_id") deviceId: String,
                 @Path("request_id") requestId: String,
                 @Path("start") start: String,
                 @Body feedback: FlowFeedback): Observable<FlowEvent>


    @Headers("Content-Type: application/json")
    @POST("directives/icd/{icd_id}/getversion")
    fun getVersion(@Header("Authorization") authorization: String,
                   @Path("icd_id") icdId: String): Observable<ResponseBody>

    /**
     * @Deprecated
     */
    @Headers("Content-Type: application/json")
    @POST("mqtt/client/version/{device_id}")
    fun getVersion2(@Header("Authorization") authorization: String,
                    @Path("device_id") deviceId: String): Observable<ResponseBody>

    /**
     * GET /api/v1/locales/units/systems
     * ref.  https://flotechnologies.atlassian.net/wiki/pages/diffpagesbyversion.action?pageId=85786625&selectedPageVersions=4&selectedPageVersions=3
     * {
     *    "systems": [
     *    {
     *    "id": String,
     *    "name": String,
     *    "units": {
     *    "temperature": {
     *    "abbrev": String,
     *    "name": String
     *    },
     *    "pressure": {
     *    "abbrev": String,
     *    "name": String
     *    },
     *    "volume": {
     *    "abbrev": String,
     *    "name": String
     *    }
     *    }
     *    }
     *    ]
     * }
     */
    @Headers("Content-Type: application/json")
    @GET("locales/units/systems")
    fun getLocaleUnitSystems(@Header("Authorization") authorization: String): Observable<LocaleUnitSystems>

    /**
     * GET /api/v1/locales/units/systems/:system_id
     *
     * system_id	String	Identifier of the unit system. Can use default to retrieve the default system.
     *
     * {
     *    "id": String,
     *    "name": String,
     *    "units": {
     *    "temperature": {
     *    "abbrev": String,
     *    "name": String
     *    },
     *    "pressure": {
     *    "abbrev": String,
     *    "name": String
     *    },
     *    "volume": {
     *    "abbrev": String,
     *    "name": String
     *    }
     * }
     * ref.  https://flotechnologies.atlassian.net/wiki/pages/diffpagesbyversion.action?pageId=85786625&selectedPageVersions=4&selectedPageVersions=3
     */
    @Headers("Content-Type: application/json")
    @GET("locales/units/systems/{system_id}")
    fun getLocaleUnitSystem(@Header("Authorization") authorization: String,
                            @Path("system_id") id: String): Observable<UnitSystem>

    /**
     * GET /api/v1/locales/units/systems/default
     *
     * system_id	String	Identifier of the unit system. Can use default to retrieve the default system.
     *
     * {
     *    "id": String,
     *    "name": String,
     *    "units": {
     *    "temperature": {
     *    "abbrev": String,
     *    "name": String
     *    },
     *    "pressure": {
     *    "abbrev": String,
     *    "name": String
     *    },
     *    "volume": {
     *    "abbrev": String,
     *    "name": String
     *    }
     * }
     * ref.  https://flotechnologies.atlassian.net/wiki/pages/diffpagesbyversion.action?pageId=85786625&selectedPageVersions=4&selectedPageVersions=3
     */
    @Headers("Content-Type: application/json")
    @GET("locales/units/systems/default")
    fun getLocaleUnitSystem(@Header("Authorization") authorization: String): Observable<UnitSystem>

    /**
     * getting group id
     *
     * Response:
     * ```
     * {
     *   // ... Other data ...
     *   account: {
     *     group_id: "... GROUP ID ...",
     *     // ... Other data ...
     *   },
     *   // ... Other data ...
     * }
     * ```
     *
     * {
     *     "total": 1,
     *     "items": [
     *     {
     *         "firstname": "Andrew",
     *         "lastname": "Chen",
     *         "phone_mobile": "+886000000000",
     *         "geo_locations": [
     *         {
     *             "state_or_province": null,
     *             "country": "us",
     *             "address": null,
     *             "address2": null,
     *             "city": null,
     *             "timezone": null,
     *             "postal_code": null,
     *             "location_id": "ffffffff-ffff-ffff-ffff-ffffffffffff"
     *         }
     *         ],
     *         "is_active": true,
     *         "is_system_user": false,
     *         "id": "ffffffff-ffff-ffff-ffff-ffffffffffff",
     *         "source": "mobile",
     *         "email": "andrew@example.com",
     *         "account": {
     *             "account_id": "ffffffff-ffff-ffff-ffff-ffffffffffff",
     *             "group_id": null
     *         }
     *     }
     *     ]
     * }
    ```
    */
    @Headers("Content-Type: application/json")
    @GET("info/users/{user_id}")
    fun getUserInfo(@Header("Authorization") authorization: String,
                    @Path("user_id") userId: String): Observable<UserInfos>


    /**
     * getting group id
     *
     * Response:
     * ```
     * {
     *   account_id: "... ACCOUNT ID ...",
     *   group_id: "... GROUP ID ...",
     *   // ... Other data ...
     * }
     * ```
     */
    @Headers("Content-Type: application/json")
    @GET("accounts/me")
    fun getMyAccount(@Header("Authorization") authorization: String): Observable<ResponseBody>

    @Headers("Content-Type: application/json")
    @GET("accounts/{account_id}")
    fun getAccount(@Header("Authorization") authorization: String,
                   @Path("account_id") accountId: String): Observable<ResponseBody>


    /**
     * Retrieves a computed irrigation schedule for the device
     *
     * @param icdId	UUID (String)	Unique pairing ID of the device
     * @return Response Body
     *
     * ```
     * {
     *   "device_id": DeviceId,
     *   "times": [[HourMinuteSeconds]],
     *   "status": ComputationStatus
     * }
     * ```
     *
     * times	Optional<List<List<HourMinuteSeconds>>> (Optional<List<List<<String>>>)
     * A list of paired start and end times of irrigation events. May be null, undefined, or empty.
     *
     * Example:
     *
     * ```
     * [
     *   [
     *     "0:48:19",
     *     "1:49:20"
     *   ],
     *   [
     *     "11:08:09",
     *     "11:35:12"
     *   ]
     * ]
     * ```
     *
     * device_id	DeviceId (String)	Physical ID of the device
     * status	ComputationStatus (String)
     * Status of the irrigation schedule computation. Value is one of the following:
     *
     *  - schedule_found
     *  - schedule_not_found
     *  - no_irrigation_in_home
     *  - learning
     *  - internal_error
     *
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/692486293/Away+Mode+Endpoints
     */
    @Headers("Content-Type: application/json")
    @GET("awaymode/icd/{icd_id}/irrigation")
    fun irrigation(@Header("Authorization") authorization: String,
                   @Path("icd_id") icdId: String): Single<Irrigation>

    /**
     * Applies the irrigation schedule for away mode to the device.
     * @param icdId	UUID (String)	Unique pairing ID of the device
     * @param durations Request Body
     *
     * ```
     * {
     *   "times": [[HourMinuteSeconds}],
     * }
     * ```
     *
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/692486293/Away+Mode+Endpoints
     */
    @Headers("Content-Type: application/json")
    @POST("awaymode/icd/{icd_id}/enable")
    fun enableIrrigation(@Header("Authorization") authorization: String,
                         @Path("icd_id") icdId: String,
                         @Body durations: Durations): Single<ResponseBody>

    /**
     * Removes the irrigation schedule for away mode from the device.
     * @param icdId	UUID (String)	Unique pairing ID of the device
     * @return {"created_at":"2019-01-15T04:06:46.693Z","icd_id":"7eb8ad78-e80c-4e00-9539-ce82321e5cd3","is_enabled":false,"times":null}
     *
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/692486293/Away+Mode+Endpoints
     */
    @Headers("Content-Type: application/json")
    @POST("awaymode/icd/{icd_id}/disable")
    fun disableIrrigation(@Header("Authorization") authorization: String,
                          @Path("icd_id") icdId: String): Single<ResponseBody>

    /**
     * Retrieves whether or not the irrigation schedule is currently being used by the device. The times returned by this endpoint are for internal auditing purposes only. Only times retrieved from the device or from the /irrigation endpoint should be trusted.
     * @param icdId UUID (String)	Unique pairing ID of the device
     *
     * @return AwayMode
     *
     * ```
     * {
     *  "icd_id": UUID,
     *  "created_at": ISO8601Date
     *  "is_enabled": Boolean,
     *  "times": [[HourMinuteSeconds}],
     * }
     * ```
     *
     * ```
     * icd_id	UUID (String)	Unique pairing ID of the device
     * created_at	ISO8601 Date (String)	Time at which the state was changed
     * is_enabled	Boolean	Whether the device is using irrigation schedule during away mode or not
     * times	Optional<List<List<HourMinuteSeconds>>> (Optional<List<List<<String>>>)
     * ```
     *
     * A list of paired start and end times of irrigation events that were applied to the device. May be null, undefined, or empty.
     *
     * Example:
     *
     * ```
     * [
     *   [
     *     "0:48:19",
     *     "1:49:20"
     *   ],
     *   [
     *     "11:08:09",
     *     "11:35:12"
     *   ]
     * ]
     * ```
     *
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/692486293/Away+Mode+Endpoints
     */
    @Headers("Content-Type: application/json")
    @GET("awaymode/icd/{icd_id}")
    fun awayMode(@Header("Authorization") authorization: String,
                 @Path("icd_id") icdId: String): Single<AwayMode>

    /**
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/696516609/Firmware+features
     */
    @Headers("Content-Type: application/json")
    @GET("firmware/features/{version}")
    fun firmwareFeatures(@Header("Authorization") authorization: String,
                         @Path("version") version: String): Single<Features>


    /**
     * Submit feedback for a specific alert
     *
     * ```
     * {
     *   "icd_id": UUID,
     *   "incident_id": UUID,
     *   "alarm_id": Integer,
     *   "system_mode": Integer,
     *   "should_accept_as_normal": Boolean
     *   "cause": CauseEnum,
     *   "plumbing_failure": Optional<PlumbingFailureEnum>
     * }
     * ```
     *
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/704479328/Alert+Feedback
     */
    @Headers("Content-Type: application/json")
    @POST("alertfeedback/")
    fun alertFeedback(@Header("Authorization") authorization: String,
                      @Body feedback: AlertFeedback): Single<ResponseBody>

    /**
     * Retrieve submitted feedback for a specific alert
     *
     * @param icdId         Unique pairing ID of the Flo device
     * @param incidentId	UUID (String)	Yes	Unique incident ID of the alert
     * @return The response will be empty if no feedback has been submitted for this alert. Otherwise this object will be returned:
     *
     * ```
     * {
     *   "icd_id": UUID,
     *   "incident_id": UUID,
     *   "alarm_id": Integer,
     *   "system_mode": Integer,
     *   "should_accept_as_normal": Boolean
     *   "cause": CauseEnum,
     *   "plumbing_failure": Optional<PlumbingFailureEnum>,
     *   "created_at": ISO8601Date,
     *   "updated_at": ISO8601Date
     * }
     * ```
     *
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/704479328/Alert+Feedback
     */
    @Headers("Content-Type: application/json")
    @GET("alertfeedback/{icd_id}/{incident_id}")
    fun getAlertFeedback(@Header("Authorization") authorization: String,
                         @Path("icd_id") icdId: String,
                         @Path("incident_id") incidentId: String): Single<AlertFeedback>

    /**
     * Retrieve the structure for displaying the feedback flow
     *
     * @param alarmId	    Integer	Alarm ID for which the feedback flow is defined
     * @param systemMode	Integer	System Mode ID for which the feedback flow is defined
     *
     * @return  The response will be empty if no feedback flow is defined for the alarm_id/system_mode pair. Otherwise, this object will be returned
     *
     * ```
     * {
     *   "alarm_id": Integer,
     *   "system_mode": Integer,
     *   "options": List<FeedbackStep({
     *   "display_text": String,
     *   "sort_order": Integer,
     *   "property": String,
     *   "value": Integer | String | Boolean,
     *   "type": String,
     *   "options": Optional<List<FeedbackStep>>
     *   })>
     * }
     * ```
     *
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/704479328/Alert+Feedback
     */
    @Headers("Content-Type: application/json")
    @GET("alertfeedback/flow/{alarm_id}/{system_mode}")
    fun getAlertFeedbackFlow(@Header("Authorization") authorization: String,
                             @Path("alarm_id") alarmId: Int,
                             @Path("system_mode") systemMode: Int): Single<AlertFeedbackFlow>
}

/**
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
 */
fun Flo.getFloDetect(authorization: String,
                     deviceId: String,
                     duration: Long,
                     unit: TimeUnit): Observable<FloDetect> {
    return getFloDetect(authorization=authorization,deviceId=deviceId, seconds=unit.toSeconds(duration))
}

/**
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
 */
fun Flo.getFlowEventsPaged(authorization: String,
                          deviceId: String,
                          duration: Long,
                          unit: TimeUnit): Observable<FlowEvent> {
    return getFloDetect(authorization=authorization,deviceId=deviceId, duration=duration,unit=unit)
            .flatMap {
                getFlowEventsPages(authorization=authorization,deviceId=deviceId, requestId=it.request_id!!)
            }
}

/**
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
 */
fun Flo.getFlowEventsPages(authorization: String,
                          deviceId: String,
                          requestId: String,
                          size: Int = 100): Observable<FlowEvent> {
    return getFlowEventsPaged(authorization=authorization,deviceId=deviceId,requestId = requestId, size = size)
            .filter { it.isNotEmpty() }
            .flatMap { events ->
                val lastEvent = events.get(events.size - 1)
                Observable.concat(Observable.just(events) , if (events.size < size) Observable.empty() else getFlowEventsPages(authorization = authorization, deviceId = deviceId, requestId = requestId, start = lastEvent.start!!, size = size))
            }
            .flatMap { Observable.fromIterable(it) }
}

/**
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
 */
fun Flo.getFlowEventsPages(authorization: String,
                          deviceId: String,
                          requestId: String,
                          start: String,
                          size: Int = 100): Observable<List<FlowEvent>> {
    return getFlowEventsPaged(authorization = authorization, deviceId = deviceId, requestId = requestId, start = start, size = size)
            .filter { it.isNotEmpty() }
            .flatMap { events: List<FlowEvent> ->
                val lastEvent = events.get(events.size - 1)
                Observable.concat(Observable.just(events) , if (events.size < size) Observable.empty() else getFlowEventsPages(authorization = authorization, deviceId = deviceId, requestId = requestId, start = lastEvent.start!!, size = size))
            }
}

fun Flo.getPushNotificationTokenList(token: String): Observable<List<PushNotificationToken>> {
    return userId(token).flatMap { userId -> getPushNotificationTokenList(token, userId) }
}

fun Flo.getPushNotificationTokens(token: String, userId: String): Observable<PushNotificationToken> {
    return getPushNotificationTokenList(token, userId).flatMap { Observable.fromIterable(it) }
}

fun Flo.getPushNotificationTokens(token: String): Observable<PushNotificationToken> {
    return getPushNotificationTokenList(token).flatMap { Observable.fromIterable(it) }
}

//@Serializable
//class VersionDirective()

@Serializable
class Features (
    @Optional
    @SerialName("features")
    var features: List<Feature>? = null
)

/**
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/696516609/Firmware+features
 */
@Serializable
class Feature (
    @Optional
    @SerialName("name")
    var name: String? = null,
    @Optional
    @SerialName("version")
    var version: String? = null
)

/**
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/84639748/In-App+User+Registration
 */
@Serializable
class Email (
    @Optional
    @SerialName("email")
    var email: String? = null
)

@Serializable
class FlowLabel (
    @Optional
    @SerialName("all")
    var all: List<Int>? = null,
    @Optional
    @SerialName("individual")
    var individual: String? = null
)

@Serializable
class FlowFeedback (
    @Optional
    @SerialName("case")
    var cases: Int? = null,
    @Optional
    @SerialName("correct_fixture")
    var correctFixture: String? = null
)

/**
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/84639748/In-App+User+Registration
 */
@Serializable
class EmailStatus (
    @Optional
    @SerialName("is_registered")
    var registered: Boolean? = null,
    @Optional
    @SerialName("is_pending")
    var pending: Boolean? = null
)

/**
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/84639748/In-App+User+Registration
 */
@Serializable
class RegistrationToken (
    @Optional
    @SerialName("token")
    var token: String? = null
)

/**
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/85786625/Locales
 */
@Serializable
class Locales (
    @Optional
    @SerialName("locales")
    var locales: List<Locale>? = null
)

/**
 * "regions": [
 *    {
 *      "abbrev": String,
 *      "name": String,
 *      "timezones: [
 *         {
 *           "tz": String,
 *           "display": String
 *         }
 *      ]
 *    }
 * ],
 * "timezones": [{
 *    tz: String,
 *    display: String
 * }]
 *
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/85786625/Locales
 */
@Serializable
class Locale (
    @Optional
    @SerialName("locale")
    var locale: String? = null,
    @Optional
    @SerialName("name")
    var name: String? = null,
    @Optional
    @SerialName("regions")
    var regions: List<Region>? = null,
    @Optional
    @SerialName("timezones")
    var timezones: List<TimeZone>? = null
)

/**
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/85786625/Locales
 */
@Serializable
class Region (
    @Optional
    @SerialName("abbrev")
    var abbrev: String? = null,
    @Optional
    @SerialName("name")
    var name: String? = null,
    @Optional
    @SerialName("timezones")
    var timezones: List<TimeZone>? = null
)

@Serializable
class Session (
    /**
     * UUID
     */
    @Optional
    @SerialName("session_id")
    var id: String? = null,
    /**
     * UUID
     */
    @Optional
    @SerialName("nonce")
    var nonce: String? = null,
    /**
     * Timestamp
     */
    @Optional
    @SerialName("expires_at")
    var expiresAt: Long? = null
)

@Serializable
class Goal (
    @Optional
    @SerialName("goal")
    var goal: Long? = null
)

/**
 * <pre>
 * {
 *     "is_paired": true,
 *     "device_id": "8cc7aa0277c0",
 *     "id": "f37339a6-e9e6-4629-8fc8-58aa7c5bbb09",
 *     "location_id": "800a8b9b-1e56-43ea-86b2-98cdefda4d30",
 *     "_isFromCache": true
 * }
 * </pre>
 */
@Serializable
class FloDevice (
    @Optional
    @SerialName("device_id")
    var deviceId: String? = null,
    // @Deprecated?
    @Optional
    @SerialName("id")
    var data: String? = null,
    @Optional
    @SerialName("is_paired")
    var paired: Boolean? = null,
    @Optional
    @SerialName("location_id")
    var locationId: String? = null,
    @Optional
    @SerialName("_isFromCache")
    var fromCache: Boolean? = null
)

@Serializable
class AlarmAction (
    @Optional
    @SerialName("incident_id")
    var incidentId: String? = null,
    @Optional
    @SerialName("action_id")
    var actionId: Long? = null,
    @Optional
    @SerialName("icd_id")
    var icdId: String? = null,
    @Optional
    @SerialName("system_mode")
    var systemMode: Long? = null,
    @Optional
    @SerialName("alarm_id")
    var alarmId: Long? = null
)

/**
 * <pre>
 * {
 *     "expansion_tank": 1,
 *     "stories": 4,
 *     "location_type": "Single Family Home",
 *     "occupants": 6,
 *     "bathroom_amenities": [
 *         "Bathtub",
 *         "Hot tub",
 *         "Spa"
 *     ],
 *     "address": "1 sesame st",
 *     "outdoor_amenities": [
 *         "Swimming Pool",
 *         "Jacuzzi",
 *         "Spa",
 *         "Sprinklers",
 *         "Fountains"
 *     ],
 *     "postalcode": "90017",
 *     "account_id": "47c6bfa0-3e16-4f9d-8d50-5796716b87df",
 *     "country": "USA",
 *     "state": "CA",
 *     "city": "Los Angeles ",
 *     "location_name": "Home",
 *     "tankless": 1,
 *     "location_size_category": 4,
 *     "timezone": "America/Los_Angeles",
 *     "location_id": "908b7277-9ad7-4e18-93e6-dd4389bdaacf",
 *     "kitchen_amenities": [
 *         "Washer / Dryer",
 *         "Dishwasher",
 *         "Fridge with Ice Maker"
 *     ]
 * }
 * </pre>
 *
 * ref. https://flotechnologies.atlassian.net/wiki/display/FLO/Location
 */
@Serializable
class HomeProfile(
    /**
     * 0: false
     * 1: true
     * 2: not sure
     *
     * [0|1|2]
     * [{@link #STATE_TRUE}|{@link #STATE_FALSE}|{@link #STATE_NOT_SURE}]
     */
    @Optional
    @SerialName("expansion_tank")
    var expansionTank: Long? = null,
    @Optional
    @SerialName("stories")
    var stories: Long? = null,
    /**
     * sfh: "Single Family Home"
     * apt: "Apartment"
     * condo: "Condo"
     *
     * [{@link #TYPE_APARTMENT}|{@link #TYPE_SINGLE_FAMILY_HOME}|{@link #TYPE_CONDO}]
     */
    @Optional
    @SerialName("location_type")
    var locationType: String? = null,
    @Optional
    @SerialName("occupants")
    var occupants: Long? = null,
    @Optional
    @SerialName("bathroom_amenities")
    var bathroomAmenities: List<String>? = null,
    @Optional
    @SerialName("address")
    var address: String? = null,
    @Optional
    @SerialName("address2")
    var address2: String? = null,
    @Optional
    @SerialName("outdoor_amenities")
    var outdoorAmenities: List<String>? = null,
    @Optional
    @SerialName("postalcode")
    var postalcode: String? = null,
    @Optional
    @SerialName("account_id")
    var accountId: String? = null,
    @Optional
    @SerialName("country")
    var country: String? = null,
    @Optional
    @SerialName("state")
    var state: String? = null,
    @Optional
    @SerialName("city")
    var city: String? = null,
    @Optional
    @SerialName("location_name")
    var locationName: String? = null,
    /**
     * 0: false
     * 1: true
     * 2: not sure
     *
     * [0|1|2]
     * [{@link #STATE_TRUE}|{@link #STATE_FALSE}|{@link #STATE_NOT_SURE}]
     */
    @Optional
    @SerialName("tankless")
    var tankless: Long? = null,
    @Optional
    @SerialName("water_shutoff_known")
    var waterShutoffKnown: Long? = null,
    @Optional
    @SerialName("galvanized_plumbing")
    var galvanizedPlumbing: Long? = null,
    @Optional
    @SerialName("water_filtering_system")
    var waterFilteringSystem: Long? = null,
    @Optional
    @SerialName("location_size_category")
    var locationSizeCategory: Long? = null,
    @Optional
    @SerialName("timezone")
    var timezone: String? = null,
    @Optional
    @SerialName("location_id")
    var locationId: String? = null,
    @Optional
    @SerialName("kitchen_amenities") // ?
    var kitchenAmenities: List<String>? = null,
    @Optional
    @SerialName("bathrooms") // ?
    var bathrooms: Long? = null,

    @Optional
    @SerialName("gallons_per_day_goal") // ?
    var dailyGoalInGallons: Double? = null,
    @Optional
    @SerialName("well_system")
    var wellSystem: Long? = null,
    /**
     * 0: false
     * 1: true
     * 2: not sure
     *
     * [0|1|2]
     * [{@link #STATE_TRUE}|{@link #STATE_FALSE}|{@link #STATE_NOT_SURE}]
     */
    @Optional
    @SerialName("water_softener")
    var waterSoftener: Long? = null,

    @Optional
    @SerialName("is_profile_complete")
    var profileComplete: Boolean? = null
    ) {

    companion object {
        val TYPE_APARTMENT = "apt"
        val TYPE_SINGLE_FAMILY_HOME = "sfh"
        val TYPE_CONDO = "condo"

        val STATE_FALSE = 0L
        val STATE_TRUE = 1L
        val STATE_NOT_SURE = 2L
    }
}

@Serializable
data class SystemMode (
    @SerialName("systemmodeid")
    val id: Int
)

@Serializable
data class SleepMode (
    @SerialName("systemmodeid")
    val id: Int,
    @SerialName("sleep_minutes")
    val minutes: Long
)

@Serializable
class UserProfile (
    @Optional
    @SerialName("firstname")
    var firstName: String? = null,
    @Optional
    @SerialName("lastname")
    var lastName: String? = null,
    @Optional
    @SerialName("phone_mobile")
    var phoneMobile: String? = null,
    @Optional
    @SerialName("email")
    var email: String? = null,
    @Optional
    @SerialName("user_id")
    var userId: String? = null,
    @Optional
    @SerialName("prefixname")
    var prefixName: String? = null,
    /**
     * ref. https://flotechnologies.slack.com/messages/C0FQC5NH3/convo/G727SP8H3-1534279401.000100/
     * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/85786625/Locales
     *
     * helmut:
     * For the user
     * ```PUT /api/v1/userdetails/me
     * {
     *   "unit_system": SYSTEM_ID
     * }```
     * ```GET /api/v1/userdetails/me```
     * ^^^ That will retrieve
     */
    @Optional
    @SerialName("unit_system")
    var unitSystem: String? = null,

    /**
     *         "geo_locations": [
     *         {
     *             "state_or_province": null,
     *             "country": "us",
     *             "address": null,
     *             "address2": null,
     *             "city": null,
     *             "timezone": null,
     *             "postal_code": null,
     *             "location_id": "ffffffff-ffff-ffff-ffff-ffffffffffff"
     *         }
     *         ],
     */
    @Optional
    @SerialName("geo_locations")
    var geoLocations: List<GeoLocation>? = null,
    @Optional
    @SerialName("is_active")
    var active: Boolean? = null,
    @Optional
    @SerialName("is_system_user")
    var system_user: Boolean? = null,
    @Optional
    @SerialName("id")
    var id: Boolean? = null,
    @Optional
    @SerialName("source")
    var source: String? = null,
    @Optional
    @SerialName("account")
    var account: Account? = null
)

/**
 *         "geo_locations": [
 *         {
 *             "state_or_province": null,
 *             "country": "us",
 *             "address": null,
 *             "address2": null,
 *             "city": null,
 *             "timezone": null,
 *             "postal_code": null,
 *             "location_id": "ffffffff-ffff-ffff-ffff-ffffffffffff"
 *         }
 *         ],
 */
@Serializable
class GeoLocation (
    @Optional
    @SerialName("account_id")
    var id: String? = null,
    @Optional
    @SerialName("state_or_province")
    var stateOrProvince: String? = null,
    @Optional
    @SerialName("country")
    var country: String? = null,
    @Optional
    @SerialName("address")
    var address: String? = null,
    @Optional
    @SerialName("address2")
    var address2: String? = null,
    @Optional
    @SerialName("city")
    var city: String? = null,
    @Optional
    @SerialName("timezone")
    var timezone: String? = null,
    @Optional
    @SerialName("postal_code")
    var postalCode: String? = null,
    @Optional
    @SerialName("location_id")
    var locationId: String? = null
)

/**
 *         "account": {
 *             "account_id": "ffffffff-ffff-ffff-ffff-ffffffffffff",
 *             "group_id": null
 *         }
 */
@Serializable
class Account (
    @Optional
    @SerialName("account_id")
    var id: String? = null,
    @Optional
    @SerialName("group_id")
    var group_id: String? = null
)

@Serializable
class Register (
    @Optional
    @SerialName("firstname")
    var firstName: String? = null,
    @Optional
    @SerialName("lastname")
    var lastName: String? = null,
    @Optional
    @SerialName("email")
    var email: String? = null,
    @Optional
    @SerialName("password")
    var password: String? = null,
    @Optional
    @SerialName("phone_mobile")
    var phoneMobile: String? = null,
    @Optional
    @SerialName("address")
    var address: String? = null,
    @Optional
    @SerialName("address2")
    var address2: String? = null,
    @Optional
    @SerialName("city")
    var city: String? = null,
    @Optional
    @SerialName("state")
    var state: String? = null,
    @Optional
    @SerialName("postalcode")
    var postalCode: String? = null,
    @Optional
    @SerialName("timezone")
    var timeZone: String? = null,
    @Optional
    @SerialName("token1")
    var token1: String? = null,
    @Optional
    @SerialName("token2")
    var token2: String? = null,
    @Optional
    @SerialName("country")
    var country: String? = null,
    @Optional
    @SerialName("password_conf")
    var passwordConfirm: String? = null
)

@Serializable
class ForgotPassword (
    @Optional
    @SerialName("email")
    var email: String? = null
)

/**
 * ref. https://github.com/FloTechnologies/flo-ios-app/blob/21e9b16352afb3fd81592d4dad52725521bdcf3c/Flo/Flo/UserLogoutModel.swift
 */
@Serializable
class Logout (
    @Optional
    @SerialName("notification_token")
    var notificationToken: String? = null
)

/**
 * https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/67862547/Notification+Tokens+v2
 */
@Serializable
class Logout2 (
    @Optional
    @SerialName("mobile_device_id")
    var mobileDeviceId: String? = null
)

@Serializable
class Logout3 (
    @Optional
    @SerialName("mobile_device_id")
    var mobileDeviceId: String? = null,
    @Optional
    @SerialName("aws_endpoint_id")
    var awsEndpointId: String? = null
)

/**
 * mobile_device_id	String	Unique identifier for the mobile device
 * client_id	UUID (String)	ID of client application
 * user_id	UUID (String)	ID of user
 * token	String	The push notification token to be associated with the mobile device
 * client_type	Integer
 * Type of the client
 *
 * 1 = iOS
 *
 * 3 = Android
 *
 * created_at	Date (ISO 8601)	Date record was created
 * updated_at	Date (ISO 8601)	Date record was updated
 * is_disabled	Optional<Integer>
 *   Is token disabled (i.e. soft deleted)
 *   Undefined/Null => False
 *   0 => False
 *   1 => True
 *
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/67862547/Notification+Tokens+v2
 */
@Serializable
class PushNotificationToken (
    @Optional
    @SerialName("mobile_device_id")
    var mobileDeviceId: String? = null,
    @Optional
    @SerialName("token")
    var token: String? = null,
    @Optional
    @SerialName("aws_endpoint_id")
    var awsEndpointId: String? = null,

    @Optional
    @SerialName("client_id")
    var clientId: String? = null,
    @Optional
    @SerialName("user_id")
    var userId: String? = null,
    @Optional
    @SerialName("client_type")
    var clientType: Int? = null,
    @Optional
    @SerialName("created_at")
    var createdAt: String? = null,
    @Optional
    @SerialName("updated_at")
    var updatedAt: String? = null,
    @Optional
    @SerialName("is_disabled")
    var disabled: Int? = null
)

@Serializable
class Login (
    @Optional
    @SerialName("username")
    var username: String? = null,
    @Optional
    @SerialName("password")
    var password: String? = null
)

/**
 * "total": 2,
 * "aggregations": [
 * {
 * "total": 2,
 * "severity": 3,
 * "alerts": [
 */
@Serializable
class SeverityNotifications (
    @Optional
    @SerialName("total")
    var total: Int? = null,
    @Optional
    @SerialName("aggregations")
    var aggregations: List<Aggregation>? = null
)

@Serializable
class Aggregation (
    @Optional
    @SerialName("total")
    var total: Int? = null,
    @Optional
    @SerialName("alerts")
    var alerts: List<SevereAlarm>? = null,
    /**
     * 1: High
     * 2: Medium
     * 3: Low
     */
    @Optional
    @SerialName("severity")
    var severity: Long? = null
)

@Serializable
class PendingAlarmIdAggregations (
    @Optional
    @SerialName("total")
    var total: Int? = null,
    @Optional
    @SerialName("aggregations")
    var aggregations: List<PendingAlarmIdAggregation>? = null
)

@Serializable
class PendingAlarmIdAggregation (
    @Optional
    @SerialName("total")
    var total: Int? = null,
    @Optional
    @SerialName("severity")
    var severity: Int? = null,
    @Optional
    @SerialName("alarm_ids")
    var alarmIds: List<AlarmIdAggregation>? = null
)

@Serializable
class AlarmIdAggregation (
    @Optional
    @SerialName("total")
    var total: Int? = null,
    @Optional
    @SerialName("alarm_id")
    var alarmId: Int? = null,
    @Optional
    @SerialName("system_modes")
    var systemModes: List<SystemModes>? = null
)

@Serializable
class SystemModes (
    @Optional
    @SerialName("total")
    var total: Int? = null,
    @Optional
    @SerialName("alarm_id")
    var alarmId: Int? = null,
    @Optional
    @SerialName("system_mode")
    var systemMode: Int? = null,
    @Optional
    @SerialName("alerts")
    var alerts: List<SevereAlarm>? = null
)

// ref. ServerAlarmModel.swift
@Serializable
class SevereAlarm (
    @Optional
    @SerialName("account_id")
    var accountID: String? = null,
    @Optional
    @SerialName("acknowledged_by_user")
    var acknowledgedByUser: Long? = null,
    @Optional
    @SerialName("alarm_id")
    var alarmId: String? = null,
    @Optional
    @SerialName("alarm_name")
    var alarmName: String? = null,
    @Optional
    @SerialName("created_at")
    var createdAt: String? = null,
    @Optional
    @SerialName("friendly_name")
    var friendlyName: String? = null,
    @Optional
    @SerialName("icd_id")
    var icdId: String? = null,
    @Optional
    @SerialName("id")
    var id: String? = null,
    @Optional
    @SerialName("incident_time")
    var incidentTime: String? = null,
    @Optional
    @SerialName("location_id")
    var locationId: String? = null,

    /**
     * 1: High
     * 2: Medium
     * 3: Low
     */
    @Optional
    @SerialName("severity")
    var severity: Long? = null,
    @Optional
    @SerialName("friendly_description")
    var friendlyDescription: String? = null,
    @Optional
    @SerialName("user_actions")
    var userActions: UserAction? = null,

    /**
     * 1: Autorun
     * 2: Home
     * 3: Away
     * 4: Vacation
     * 5: Manual
     *
     * ref. https://flotechnologies.atlassian.net/wiki/display/FLO/Set+System+Mode
     */
    @Optional
    @SerialName("system_mode")
    var systemMode: Long? = null,

    @Optional
    @SerialName("status")
    var status: Long? = null,

    @Optional
    @SerialName("extra_info")
    var extraInfo: String? = null,

    @Optional
    @SerialName("incident_id")
    var incidentId: String? = null,

    @Optional
    @SerialName("self_resolved")
    var selfResolved: Long? = null,

    @Optional
    @SerialName("self_resolved_message")
    var selfResolvedMessage: Long? = null,

    @Optional
    @SerialName("is_cleared")
    var cleared: Boolean? = null
)

/**
 * <pre>
 * {
 *   "is_active": true,
 *   "tz_id": "America/Los_Angeles",
 *   "name": "Pacific Standard Time",
 *   "tz": "PST"
 * }
 * </pre>
 */
@Serializable
class TimeZone (
    @Optional
    @SerialName("tz")
    var tz: String? = null,
    // NOTICE: error: JsonField
    // annotation can only be used on private fields if both getter and setter are present.
    // it's a logan-square compatible naming issue, because of it detects isXxxx() functions
    // var isActive: Boolean? = null,
    @Optional
    @SerialName("is_active")
    var active: Boolean? = null,
    @Optional
    @SerialName("name")
    var name: String? = null,
    @Optional
    @SerialName("tz_id")
    var tzId: String? = null,
    @Optional
    @SerialName("display")
    var display: String? = null
)

@Serializable
class UserToken (
    @Optional
    @SerialName("token")
    var token: String? = null,
    @Optional
    @SerialName("deviceType")
    var deviceType: String? = null
)

@Serializable
class UserAction (
    @Optional
    @SerialName("timeout")
    var timeout: Long? = null,
    @Optional
    @SerialName("default_action_time")
    var actionTime: Long? = null,
    @Optional
    @SerialName("actions")
    var actions: List<PendingAlarmAction>? = null
)

@Serializable
class RemoteAlarmNotification (
    @Optional
    @SerialName("id")
    var id: String? = null,
    @Optional
    @SerialName("ts")
    var ts: String? = null,
    @Optional
    @SerialName("notification")
    var alarm: Alarm? = null,
    @Optional
    @SerialName("icd")
    var icd: Icd? = null,
    @Optional
    @SerialName("user_actions")
    var userActions: UserAction? = null,
    @Optional
    @SerialName("friendly_name")
    var friendlyMessage: String? = null,
    @Optional
    @SerialName("friendly_decription")
    var friendlyDescription: String? = null,
    @Optional
    @SerialName("extra_info")
    var extraInfo: String? = null
)

@Serializable
class Alarm (
    @Optional
    @SerialName("alarm_id")
    var alarmId: Long? = null,
    @Optional
    @SerialName("name")
    var name: String? = null,
    @Optional
    @SerialName("default_action_time")
    var actionTime: Long? = null,
    @Optional
    @SerialName("severity")
    var severity: Long? = null
)

@Serializable
class Icd (
    @Optional
    @SerialName("device_id")
    var deviceId: String? = null,
    @Optional
    @SerialName("timezone")
    var timeZone: String? = null,
    @Optional
    @SerialName("system_mode")
    var systemMode: Long? = null,
    @Optional
    @SerialName("icd_id")
    var icdId: String? = null,
    @Optional
    @SerialName("event")
    var event: Int? = null,
    @Optional
    @SerialName("created_at")
    var createdAt: String? = null
)

@Serializable
class PendingAlarmAction (
    @Optional
    @SerialName("option")
    var option: String? = null,
    @Optional
    @SerialName("display")
    var display: String? = null,
    @Optional
    @SerialName("id")
    var id: Long? = null,
    @Optional
    @SerialName("sort")
    var sort: Long? = null,
    @Optional
    @SerialName("display_when")
    var conditions: AlarmActionConditions? = null,
    @Optional
    @SerialName("success_message")
    var successMessage: String? = null,
    @Optional
    @SerialName("failure_message")
    var failureMessage: String? = null
)

@Serializable
class AlarmActionConditions (
    @Optional
    @SerialName("alarm_notification_delivery_filter")
    var filterCondiction: AlarmActionFilterCondition? = null,
    @Optional
    @SerialName("valve")
    var valveCondiction: AlarmActionValveCondition? = null,
    @Optional
    @SerialName("time")
    var timeCondiction: AlarmActionTimeCondition? = null
)

@Serializable
class AlarmActionFilterCondition (
    @Optional
    @SerialName("status")
    var status: Long? = null
)

@Serializable
class AlarmActionValveCondition (
    @Optional
    @SerialName("state")
    var state: Long? = null
)

@Serializable
class AlarmActionTimeCondition (
    @Optional
    @SerialName("chronometer_type")
    var chronometerType: Long? = null,
    @Optional
    @SerialName("time_elapsed_in_minutes")
    var timeElapsedInMinutes: Long? = null
)

@Serializable
class Error (
    @Optional
    @SerialName("message")
    var message: String? = null,
    @Optional
    @SerialName("msg")
    var msg: String? = null,
    @Optional
    @SerialName("error")
    var error: Boolean? = null
)

/**
 * id UUID (String)	StockICD table ID
 * ap_name	String	Device access point SSID
 * ap_password	String	Device access point password
 * device_id	DeviceId (String)	Device ID
 * login_token	String	Device login token
 * client_cert	String	MQTT client certificate
 * client_key	String	MQTT client key
 * server_cert	String	MQTT CA file
 * websocket_cert	String	Websocket certificate
 * websocket_cert_der	Optional<String>	Websocket certificate in DER format
 * websocket_key	String	Websocket key
 *
 * <pre>
 * {
 *   "id": "ffffffff-ffff-ffff-ffff-ffffffffffff",
 *   "ap_name": "Flo-7840",
 *   "ap_password": "",
 *   "device_id": "8cffffff7840",
 *   "login_token": "ffffffffffffffffffffffffffffffffffffffff",
 *   "client_cert": "",
 *   "client_key": "",
 *   "server_cert": "",
 *   "websocket_cert": "",
 *   "websocket_cert_der": "",
 *   "websocket_key": ""
 * }
 * </pre>
 *
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/560824321/Pairing+Endpoints
 */
@Serializable
class Certificate (
    /**
     * purchase id
     * UUID (String)	StockICD table ID
     */
    @Optional
    @SerialName("id")
    var id: String? = null,
    /**
     * String	Device access point SSID
     */
    @Optional
    @SerialName("ap_name")
    var apName: String? = null,
    /**
     * String	Device access point password
     */
    @Optional
    @SerialName("ap_password")
    var apPassword: String? = null,
    /**
     * DeviceId (String)	Device ID
     */
    @Optional
    @SerialName("device_id")
    var deviceId: String? = null,
    /**
     * String	Device login token
     */
    @Optional
    @SerialName("login_token")
    var token: String? = null,
    /**
     * String	MQTT client certificate
     */
    @Optional
    @SerialName("client_cert")
    var clientCert: String? = null,
    /**
     * String	MQTT client key
     */
    @Optional
    @SerialName("client_key")
    var clientKey: String? = null,
    /**
     * String	MQTT CA file
     */
    @Optional
    @SerialName("server_cert")
    var serverCert: String? = null,
    /**
     * String	Websocket certificate
     */
    @Optional
    @SerialName("websocket_cert")
    var websocketCert: String? = null,
    /**
     * Optional<String>	Websocket certificate in DER format
     */
    @Optional
    @SerialName("websocket_cert_der")
    var websocketCertDer: String? = null,
    /**
     * String	Websocket key
     */
    @Optional
    @SerialName("websocket_key")
    var websocketKey: String? = null
)

@Serializable
class QrCode (
    @Optional
    @SerialName("qr_code_data_svg")
    var svg: String? = null
)

@Serializable
class UserAttributes (
    @Optional
    @SerialName("Attributes")
    var attributes: UserProfile? = null
)

@Serializable
class HomeAttributes (
    @Optional
    @SerialName("Attributes")
    var attributes: HomeProfile? = null
)

@Serializable
class Message (
    @Optional
    @SerialName("message")
    var message: String? = null
)

@Serializable
class Usage (
    @Optional
    @SerialName("usage")
    var usage: String? = null
)

@Serializable
class Purchase (
    @Optional
    @SerialName("i")
    var id: String? = null,
    @Optional
    @SerialName("e")
    var encryptCode: String? = null
)

@Serializable
class PurchaseV2 (
    @Optional
    @SerialName("data")
    var data: String? = null
)

@Serializable
class PurchaseV1 (
    @Optional
    @SerialName("data")
    var data: Purchase? = null
)
/**
 *
 * format:
 *
 * <pre>
 * {
 *   user_id: UUID
 *   tokens: Map<DeviceType, Map<MobileDeviceId, PushToken> >
 * }
 * </pre>
 *
 * for example:
 *
 * </pre>
 * {
 * "user_id": "81a593a6-fd5a-41b9-a278-c7f04a86ad56"
 * "tokens": {
 *   "ios": {
 *     "256bde9c-6710-47dc-b1b4-71cfa3c5ac0d": "e)uCJ68NJQD&9fygVbB9(5k##[J77IM5Yi1VRkN*4MhEJtn52H"
 *   },
 *   "android": {
 *     "0944e96d-419a-43b8-8c13-4884949f918d": "QkbxTlTqTC*%YHATG%Zhe)XWXmpAj3xSAyQcGU](hWpUl]WRsE",
 *     "27e586fe-4f84-462d-ac87-5ce9cb897be9": "JsUlziXWxk5o(BX8bhU!Xh)[#IL[eSH2bcGu[iAvJiYx$E^eqZ"
 *   }
 * }
 * <pre>
 */
@Serializable
class NotificationTokens (
    @Optional
    @SerialName("ios_tokens")
    var iosTokens: List<String>? = null,
    @Optional
    @SerialName("android_tokens")
    var androidTokens: List<String>? = null,
    @Optional
    @SerialName("user_id")
    var userId: String? = null
)

/**
 * total total number of alerts found
 * items Page of data within items
 * is_cleared Is alert cleared? (Pending alerts are `false` obviously)
 *
 * severity Alarm severity
 * updated_at Last time alert was updated.
 * incident_id UUID, Id of alarm in the `ICDAlarmIncidentRegistry`
 * alarm_id Id of the alarm
 * alarm_id_system_mode
 * icd_id
 * incident_time
 * status `AlarmNotificationDeliveryFilter` (pending will almost always be `3` which menas `Unresolved`)
 * system_mode
 * friendly_name
 * user_actions
 * ICDAlarmNotificationDeliveryRule
 */
@Serializable
class Notifications (
    @Optional
    @SerialName("total")
    var total: Int? = null,
    @Optional
    @SerialName("items")
    var items: List<SevereAlarm>? = null,
    @Optional
    @SerialName("is_cleared")
    var cleared: Boolean? = null
)

/**
 * {"new_device":false,"websocket_token":"225dffffffffffffffffffffffffffffffffffff","websocket_tls_enabled":true}
 */
@Serializable
class WebsocketToken (
    @Optional
    @SerialName("new_device")
    var newDevice: Boolean? = null,
    @Optional
    @SerialName("websocket_token")
    var token: String? = null,
    @Optional
    @SerialName("websocket_tls_enabled")
    var tlsEnabled: Boolean? = null
)

@Serializable
class AlertFilter (
    @Optional
    @SerialName("alarm_id")
    var alarmId: Long? = null,
    @Optional
    @SerialName("system_mode")
    var systemMode: Long? = null
)

/**
 * {
 *     "notification": {
 *       "alarm_id": 5,
 *       "name": "test Alarm Name",
 *       "severity": 1
 *     },
 *     "icd": {
 *       "device_id": "h8ygy7ytgy7ygy7-huhghuhghyh-u",
 *       "time_zone": "Pacific",
 *       "system_mode": 2,
 *       "icd_id": "ICDID bro"
 *     },
 *     "ts": "2016-08-25T23:01:51.379Z",
 *     "id": "c7482619-3a96-4b38-a4e3-4d8cf5ca5f59"
 * }
 * {
 * "notification":
 * {
 * "severity":1,
 * "name":"Max Flow Event",
 * "description":"On September 06 4:21 pm, your water use exceeded 1.0 gallons in one sitting, which is higher than your normal usage. To protect your home, Flo has shut off your water.",
 * "alarm_id":11
 * },
 * "icd":{"device_id":"8cc7aa0280f0","time_zone":"US\/Pacific","icd_id":"4c17de18-0c46-4a2c-9b32-d6ea9ea6b0f3","system_mode":3},
 * "id":"4f7e3a06-9373-11e7-8f1a-8cc7aa0280ef",
 * "version":1,
 * "ts":"2017-09-06T16:21:58.796-10:00"}
 */
@Serializable
class FloAlarmNotification (
    @Optional
    @SerialName("notification")
    var alarm: AlarmNotification? = null,
    @Optional
    @SerialName("icd")
    var icd: Icd? = null,
    @Optional
    @SerialName("id")
    var id: String? = null,
    @Optional
    @SerialName("version")
    var version: Long? = null,
    @Optional
    @SerialName("ts")
    var timestamp: String? = null
)

@Serializable
class AlarmNotification (
    @Optional
    @SerialName("alarm_id")
    var alarmId: Long? = null,
    @Optional
    @SerialName("name")
    var name: String? = null,
    @Optional
    @SerialName("description")
    var description: String? = null,
    @Optional
    @SerialName("severity")
    var severity: Long? = null
)

const val TRIALING = "trialing"
const val ACTIVE = "active"
const val PAST_DUE = "past_due"
const val CANCELED = "canceled"
const val UNPAID = "unpaid"

const val ACTION_OPENING_VALVE = 5
const val ACTION_CLOSING_VALVE = 7

//const val VAVLE_UNAVAILABLE = 2
//const val VAVLE_OPEN = 1
//const val VAVLE_CLOSED = -1
//const val VAVLE_INTRANSITION = 0
//const val VAVLE_BROKEN = -2

// ref. https://flotechnologies.atlassian.net/wiki/pages/viewpage.action?pageId=38174726
const val VALVE_CLOSED = 0
const val VALVE_OPEN = 1
const val VALVE_IN_TRANSITION = 2
const val VALVE_BROKEN = 3
const val VALVE_UNKNOWN = -1

// ref. https://flotechnologies.atlassian.net/wiki/pages/viewpage.action?pageId=38174726
const val STATUS_RESOLVED = 1
const val STATUS_IGNORED = 2
const val STATUS_UNRESOLVED = 3

const val SEVERITY_HIGH = 1
const val SEVERITY_MEDIUM = 2
const val SEVERITY_LOW = 3

const val MODE_UNKNOWN = 0
const val MODE_AUTORUN = 1
const val MODE_HOME = 2
const val MODE_AWAY = 3
const val MODE_VACATION = 4
const val MODE_MANUAL = 5

val AWAY_MODE = SystemMode(MODE_AWAY)
val HOME_MODE = SystemMode(MODE_HOME)

const val WILL_ONLINE = "online"
const val WILL_OFFLINE = "offline"

// ref. https://flotechnologies.atlassian.net/wiki/pages/viewpage.action?pageId=38174726
const val TYPE_ANTERIOR = 0
const val TYPE_POSTERIOR = 1

const val ONBOARDING_PAIRED = 1
const val ONBOARDING_INSTALLED = 2
const val ONBOARDING_FORCE_SLEEP_REMOVED = 3

@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.SOURCE)
@MustBeDocumented
annotation class Permission(val value: Array<String>)

/**
 * {
 *     "client_id": String,
 *     "client_secret": String,
 *     "grant_type": "client_credentials"
 * }
 *
 * "username": String,
 * "password": String,
 */
@Serializable
class Oauth (
    @Optional
    @SerialName("client_id")
    var clientId: String? = null,
    @Optional
    @SerialName("client_secret")
    var clientSecret: String? = null,
    /**
     *  password
     *  refresh_token
     */
    @Optional
    @SerialName("grant_type")
    var grantType: String? = null,
    @Optional
    @SerialName("username")
    var username: String? = null,
    @Optional
    @SerialName("password")
    var password: String? = null,
    @Optional
    @SerialName("email")
    var email: String? = null,
    @Optional
    @SerialName("refresh_token")
    var refreshToken: String? = null,
    @Optional
    @SerialName("token")
    var token: String? = null
)

/**
 * {
 *     "access_token": String,
 *     "token_type": "Bearer"
 * }
 * "refresh_token": String,
 * "expires_in": Integer,
 * Integer	Number of seconds before the access token expires and must be refreshed
 * "user_id": UUIDv4
 */
@Serializable
class OauthToken (
    @Optional
    @SerialName("access_token")
    var accessToken: String? = null,
    @Optional
    @SerialName("token_type")
    var tokenType: String? = null,
    @Optional
    @SerialName("refresh_token")
    var refreshToken: String? = null,
    @Optional
    @SerialName("expires_in")
    var expiresIn: Long? = null,
    @Optional
    @SerialName("user_id")
    var userId: String? = null
)

/**
 * {
 *     "average_flowrate": 0,
 *     "average_pressure": 59.968529735682786,
 *     "average_temperature": 77,
 *     "did": "f87aef01019c",
 *     "total_flow": 0,
 *     "time": "2017-11-09T08:00:00.000Z"
 * }
 * ref. https://flotechnologies-jira.atlassian.net/projects/AND/issues/AND-84
 */
@Serializable
class Consumption (
    @Optional
    @SerialName("average_flowrate")
    var averageFlowrate: Double? = null,
    @Optional
    @SerialName("average_pressure")
    var averagePressure: Double? = null,
    @Optional
    @SerialName("average_temperature")
    var averageTemperature: Double? = null,
    @Optional
    @SerialName("did")
    var did: String? = null,
    @Optional
    @SerialName("total_flow")
    var totalFlow: Float? = null,
    @Optional
    @SerialName("time")
    var time: String? = null
)

/**
 * [
 * {
 *     "topic": ""
 *     "activity": "sub"|"pub"
 * }
 * ]
 */
@Serializable
class MqttTopicPermission (
    @Optional
    @SerialName("topic")
    var topic: String? = null,
    @Optional
    @SerialName("activity")
    var activity: String? = null
)

@Serializable
class AlarmData (
    @Optional
    @SerialName("data")
    var data: List<SevereAlarm>? = null
)

/**
 * {
 *     "start_date": "2018-01-02T24:00:00Z",
 *     "end_date": "2018-01-02T00:00:00Z"
 * }
 */
@Serializable
class Duration (
    @Optional
    @SerialName("start_date")
    var startDate: String? = null,
    @Optional
    @SerialName("end_date")
    var endDate: String? = null
)

/**
 * {
 *   "request_id": "00f1a056-5737-488c-aa5d-3915c769e49d"
 * }
 * or
 * {
 *     "request_id": "00f1a056-5737-488c-aa5d-3915c769e49d",
 *     "start_date": "2018-01-02T24:00:00Z",
 *     "end_date": "2018-01-02T00:00:00Z",
 *     "fixtures": [
 *     {
 *         "index": 0,
 *         "gallons": 915.55,
 *         "name": "shower",
 *         "ratio": 0.2821,
 *         "type": 1
 *     },
 *     {
 *         "index": 1,
 *         "gallons": 421.21,
 *         "name": "toilet",
 *         "ratio": 0.1298,
 *         "type": 2
 *     },
 *     {
 *         "index": 2,
 *         "gallons": 77.952,
 *         "name": "machines",
 *         "ratio": 0.024,
 *         "type": 3
 *     },
 *     {
 *         "index": 3,
 *         "gallons": 1830.515,
 *         "name": "other",
 *         "ratio": 0.5641,
 *         "type": 4
 *     }
 *     ]
 * }
 */
@Serializable
class KafkaRequest (
    @Optional
    @SerialName("request_id")
    var requestId: String? = null,
    @Optional
    @SerialName("start_date")
    var startDate: String? = null,
    @Optional
    @SerialName("end_date")
    var endDate: String? = null,
    @Optional
    @SerialName("fixtures")
    var fixtures: List<Fixture>? = null,
    @Optional
    @SerialName("device_id")
    var deviceId: String? = null,
    @Optional
    @SerialName("created_at")
    var createdAt: String? = null,
    @Optional
    @SerialName("status")
    var status: String? = null
)

/**
 * {
 *   "index": 0,
 *   "gallons": 915.55,
 *   "name": "shower",
 *   "ratio": 0.2821,
 *   "type": 1
 * }
 */
@Serializable
class Fixture (
    @Optional
    @SerialName("index")
    var index: Int? = null,
    @Optional
    @SerialName("gallons")
    var gallons: Float? = null,
    @Optional
    @SerialName("name")
    var name: String? = null,
    @Optional
    @SerialName("ratio")
    var ratio: Float? = null,
    @Optional
    @SerialName("type")
    var type: Int? = null,
    @Optional
    @SerialName("num_events")
    var num_events: Int? = null,
    @Optional
    @SerialName("feedback")
    var feedback: Feedback? = null
)

/**
 * "account_id": UUID,
 * "stripe_customer_id": String,
 * "plan_id": String,
 * "source_id": String,
 * "status": Status,
 * "created_at": Date,
 * "updated_at": Date,
 * "current_period_end": Date,
 * "current_period_start": Date,
 * "canceled_at": Optional<Date>,
 * "ended_at": Optional<Date>
 *
 * account_id	UUID (String)	ID of account
 * stripe_customer_id	String	ID of customer in Stripe's system
 * plan_id	String	ID of subscription plan
 * source_id	String	ID of the sales source of the subscription
 * status	Status
 * Status of the subscription, maybe one of the following:
 *
 * trialing, active, past_due, canceled, unpaid
 *
 * created_at	Date	Time the record was created
 * updated_at	Date	Time the record was last updated
 * current_period_start	Date	Start date of current paid-for subscription period
 * current_period_end	Date	End date of current paid-for subscription end
 * canceled_at	Optional<Date>	If the subscription was canceled, then this records the date at which it was canceled
 * ended_at	Optional<Date>	If the subscription was ended for any reason, then this records the date at which the subscription was ended
 *
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/255197185/Account+Subscriptions
 */
@Serializable
class FloSubscription (
    @Optional
    @SerialName("account_id")
    var accountId: String? = null,
    @Optional
    @SerialName("stripe_customer_id")
    var stripeCustomerId: String? = null,
    @Optional
    @SerialName("plan_id")
    var planId: String? = null,
    @Optional
    @SerialName("source_id")
    var sourceId: String? = null,
    @Optional
    @SerialName("status")
    var status: String? = null,
    @Optional
    @SerialName("created_at")
    var createdAt: String? = null,
    @Optional
    @SerialName("updated_at")
    var updatedAt: String? = null,
    @Optional
    @SerialName("current_period_end")
    var currentPeriodEnd: String? = null,
    @Optional
    @SerialName("current_period_start")
    var currentPeriodStart: String? = null,
    @Optional
    @SerialName("canceled_at")
    var canceledAt: String? = null,
    @Optional
    @SerialName("ended_at")
    var endedAt: String? = null
)

/**
 * {
 *     "plan_id": String,
 *     "features": List<String>,
 *     "monthly_cost": Float
 * }
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/255197185/Account+Subscriptions
 */
@Serializable
class FloPlan (
    @Optional
    @SerialName("plan_id")
    var planId: String? = null,
    @Optional
    @SerialName("features")
    var features: List<String>? = null,
    @Optional
    @SerialName("monthly_cost")
    var monthlyCost: Float? = null
)

/**
 *
 * {
 *  "stripe_token": String,
 *  "user_id": UUID,
 *  "plan_id": Optional<String>,
 *  "source_id": Optional<String>
 * }
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/255197185/Account+Subscriptions
 */
@Serializable
class FloPayment (
    @Optional
    @SerialName("stripe_token")
    var stripeToken: String? = null,
    @Optional
    @SerialName("user_id")
    var userId: String? = null,
    @Optional
    @SerialName("plan_id")
    var planId: Int? = null,
    @Optional
    @SerialName("source_id")
    var sourceId: Int? = null
)


/**
 *
 * {
 *  "alarm_id": 10,
 *  "filter_settings": {
 *   "exempted": true,
 *   "max_delivery_amount": 1,
 *   "max_delivery_amount_scope": 1,
 *   "max_minutes_elapsed_since_incident_time": 60,
 *   "send_when_valve_is_closed": false
 *  },
 *  "graveyard_time": {
 *   "enabled": false,
 *   "ends_time_in_24_format": "07:00",
 *   "send_app_notification": false,
 *   "send_email": false,
 *   "send_sms": false,
 *   "start_time_in_24_format": "00:00"
 *  },
 *  "internal_id": 1010,
 *  "is_muted": false,
 *  "location_id": "bedbc02d-7676-475c-b28b-922e1ba091c0",
 *  "location_id_alarm_id_system_mode": "bedbc02d-7676-475c-b28b-922e1ba091c0_10_2",
 *  "mandatory": [
 *   2,
 *   3,
 *   5
 *  ],
 *  "optional": [
 *   5,
 *   2,
 *   3
 *  ],
 *  "severity": 1,
 *  "system_mode": 2,
 *  "user_id": "7376163d-0340-4d53-b562-f5bc00ad7e7d"
 * }
 */
@Serializable
class AlarmPreference (
    @Optional
    @SerialName("user_id")
    var userId: String? = null, // UUIDv4
    @Optional
    @SerialName("location_id")
    var locationId: String? = null, // UUIDv4
    @Optional
    @SerialName("mandatory")
    var mandatory: List<Int>? = null,
    @Optional
    @SerialName("optional")
    var optional: List<Int>? = null,
    @Optional
    @SerialName("filter_settings")
    var filterSettings: FilterSettings? = null,
    @Optional
    @SerialName("graveyard_time")
    var graveyardTime: GraveyardTime? = null,
    @Optional
    @SerialName("internal_id")
    var internalId: Long? = null,
    @Optional
    @SerialName("alarm_id")
    var alarmId: Int? = null,
    @Optional
    @SerialName("system_mode")
    var systemMode: Int? = null,
    @Optional
    @SerialName("severity")
    var severity: Int? = null,
    @Optional
    @SerialName("has_action")
    var action: Boolean? = null,
    /*
    @Optional
    @SerialName("user_actions")
    var user_actions: Any? = null,
    */
    @Optional
    @SerialName("is_deleted")
    var deleted: Boolean? = null,
    @Optional
    @SerialName("message_templates")
    var messageTemplates: MessageTemplate? = null,
    @Optional
    @SerialName("is_user_overwritable")
    var userOverwritable: Boolean? = null,
    @Optional
    @SerialName("is_muted")
    var muted: Boolean? = null
)

/**
 * "name": "Manual Valve Open",
 * "friendly_description": "On ##INCIDENT_DATE_TIME##, the water system was turned on manually via the Flo Device.",
 * "friendly_name": "Valve Open",
 * "email_properties": {
 *     "subject": "##ALERT_SEVERITY##",
 *     "template_id": "tem_3GhD9ouwMs6dtC8YbQ82r7"
 * },
 * "push_notification_message": {
 *     "body": "Someone has turned on the water to your home.",
 *     "title": "##ALERT_FRIENDLY_NAME##"
 * },
 * "sms_text": "Someone has turned on the water to your home."
 */
@Serializable
class MessageTemplate (
    @Optional
    @SerialName("name")
    var name: String? = null,
    @Optional
    @SerialName("friendly_description")
    var friendlyDescription: String? = null,
    @Optional
    @SerialName("friendly_name")
    var friendlyName: String? = null
)

@Serializable
class FilterSettings (
    @Optional
    @SerialName("max_delivery_amount_scope")
    var maxDeliveryAmountScope: Int? = null,
    @Optional
    @SerialName("max_minutes_elapsed_since_incident_time")
    var maxMinutesElapsedSinceIncidentTime: Int? = null,
    @Optional
    @SerialName("send_when_valve_is_closed")
    var sendWhenValveIsClosed: Boolean? = null,
    @Optional
    @SerialName("max_delivery_amount")
    var maxDeliveryAmount: Int? = null,
    @Optional
    @SerialName("exempted")
    var exempted: Boolean? = null
)

@Serializable
class AlarmPreferences (
    @Optional
    @SerialName("Items")
    var items: List<AlarmPreference>? = null
)

@Serializable
class GraveyardTime (
    @Optional
    @SerialName("send_app_notification")
    var sendAppNotification: Boolean? = null,
    @Optional
    @SerialName("ends_time_in_24_format")
    var endsTimeIn24Format: String? = null,
    @Optional
    @SerialName("send_email")
    var sendEmail: Boolean? = null,
    @Optional
    @SerialName("start_time_in_24_format")
    var startTimeIn24Format: String? = null,
    @Optional
    @SerialName("send_sms")
    var sendSms: Boolean? = null,
    @Optional
    @SerialName("enabled")
    var enabled: Boolean? = null
)


/**
 *
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
 */
@Serializable
class FloDetect (
    /**
     * status:
     *
     *  - sent
     *  - executed
     *  - feedback_submitted
     *  - learning
     *  - insufficient_data
     *  - internal_error
     */
    @Optional
    @SerialName("status")
    var status: String? = null,
    @Optional
    @SerialName("compute_end_date")
    var compute_end_date: String? = null,
    @Optional
    @SerialName("compute_start_date")
    var compute_start_date: String? = null,
    @Optional
    @SerialName("did")
    var did: String? = null,
    @Optional
    @SerialName("duration_in_seconds")
    var duration_in_seconds: Long? = null,
    @Optional
    @SerialName("end_date")
    var end_date: String? = null,
    @Optional
    @SerialName("event_chronology")
    var event_chronology: List<FlowEvent>? = null,
    @Optional
    @SerialName("fixtures")
    var fixtures: List<Fixture>? = null,
    @Optional
    @SerialName("known_fixtures")
    var knownFixtures: List<String>? = null,
    @Optional
    @SerialName("request_id")
    var request_id: String? = null,
    @Optional
    @SerialName("start_date")
    var start_date: String? = null
)

/**
 * <pre>
 * {
 *   "duration": Number,
 *   "fixture": String,
 *   "type": Integer,
 *   "start": ISO8601Date,
 *   "end": ISO8601Date,
 *   "flow": Number,
 *   "gpm": Number,
 *   "label": [Integer],
 *   "not_label": [Integer],
 *   "sub_label": {
 *       "all": [Integer],
 *       "individual": Integer
 *   },
 *   "not_sub_label": {
 *       "all": [Integer],
 *       "individual": Integer
 *   },
 *   "feedback": {
 *       "case": Integer,
 *       "correct_fixture": String
 *   }
 * }
 * </pre>
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
 */
@Serializable
class FlowEvent (
    @Optional
    @SerialName("duration")
    var duration: Long? = null,
    @Optional
    @SerialName("fixture")
    var fixture: String? = null,
    @Optional
    @SerialName("type")
    var type: Int? = null,
    @Optional
    @SerialName("start")
    var start: String? = null,
    @Optional
    @SerialName("end")
    var end: String? = null,
    @Optional
    @SerialName("flow")
    var flow: Float? = null,
    @Optional
    @SerialName("gpm")
    var gpm: Float? = null,
    @Optional
    @SerialName("label")
    var label: List<Int>? = null,
    @Optional
    @SerialName("not_label")
    var not_label: List<Int>? = null,
    @Optional
    @SerialName("sub_label")
    var sub_label: FlowLabel? = null,
    @Optional
    @SerialName("not_sub_label")
    var not_sub_label: FlowLabel? = null,
    @Optional
    @SerialName("feedback")
    var feedback: FlowFeedback? = null
) {
    @Optional
    @SerialName("friendly_fixture")
    var friendlyFixture: String? = fixture
        get() {
            //return feedback?.fixture ?: field
            if (feedback?.correctFixture != null && feedback?.correctFixture != fixture) {
                return "${feedback?.correctFixture} (was ${fixture})"
            }
            return fixture
        }
}

/**
 * {
    "fixtures": [
        {
            "index": Number,
            "gallons": Number,
            "name": String,
            "ratio": Number,
            "type": Number,
            "num_events": Number,
            "feedback": {
                "accurate": Boolean,
                "reason": Number,
                other_reason: String
            }
        }
    ]
)
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
 */
@Serializable
class FloDetectFeedbacks (
    @Optional
    @SerialName("fixtures")
    var fixtures: List<Fixture>? = null
)

@Serializable
class Feedback (
    @Optional
    @SerialName("accurate")
    var accurate: Boolean? = null,
    @Optional
    @SerialName("reason")
    var reason: Int? = null,
    @Optional
    @SerialName("other_reason")
    var other_reason: String? = null
)

/**
 *
 * ref.  https://flotechnologies.atlassian.net/wiki/pages/diffpagesbyversion.action?pageId=85786625&selectedPageVersions=4&selectedPageVersions=3
 * {
 *    "systems": [
 *    {
 *    "id": String,
 *    "name": String,
 *    "units": {
 *    "temperature": {
 *    "abbrev": String,
 *    "name": String
 *    },
 *    "pressure": {
 *    "abbrev": String,
 *    "name": String
 *    },
 *    "volume": {
 *    "abbrev": String,
 *    "name": String
 *    }
 *    }
 *    }
 *    ]
 * }
 * Property	Type	Description
 * systems	List<Object>	List of unit systems
 * systems[i].id	String	Identifier of the system. Pass this to User Details.
 * systems[i].name	String	Display name of the system
 * systems[i].units	Map<String, Object>	Map of measurement to units
 * systems[i].units.temperature	Object	Temperature units
 * systems[i].units.temperature.abbrev	String	Abbreviation of unit
 * systems[i].units.temperature.name	String	Display name of unit
 * systems[i].units.pressure	Object	Pressure units
 * systems[i].units.pressure.abbrev	String	Abbreviation of unit
 * systems[i].units.pressure.abbrev	String	Display name of unit
 * systems[i].units.volume	Object	Volume units
 * systems[i].units.volume.abbrev	String	Abbreviation of unit
 * systems[i].units.volume.name	String	Display name of unit
 */
@Serializable
class LocaleUnitSystems (
    @Optional
    @SerialName("systems")
    var systems: List<UnitSystem>? = null
)

/**
 *
 * {
 * "id": String,
 * "name": String,
 * "units": {
 * "temperature": {
 * "abbrev": String,
 * "name": String
 * },
 * "pressure": {
 * "abbrev": String,
 * "name": String
 * },
 * "volume": {
 * "abbrev": String,
 * "name": String
 * }
 * }
 * }
 * ref.  https://flotechnologies.atlassian.net/wiki/pages/diffpagesbyversion.action?pageId=85786625&selectedPageVersions=4&selectedPageVersions=3
 *
 * Property	Type	Description
 * id	String	Identifier of the system. Pass this to User Details.
 * name	String	Display name of the system
 * units	Map<String, Object>	Map of measurement to units
 * units.temperature	Object	Temperature units
 * units.temperature.abbrev	String	Abbreviation of unit
 * units.temperature.name	String	Display name of unit
 * units.pressure	Object	Pressure units
 * units.pressure.abbrev	String	Abbreviation of unit
 * units.pressure.abbrev	String	Display name of unit
 * units.volume	Object	Volume units
 * units.volume.abbrev	String	Abbreviation of unit
 * units.volume.name	String	Display name of unit
 *
 * @example
 *
 * <pre>
 * {
 *   "id": "imperial_us",
 *   "name": "Imperial",
 *   "units": {
 *   "pressure": {
 *   "name": "PSI",
 *   "abbrev": "psi"
 *   },
 *   "volume": {
 *   "name": "Gallon",
 *   "abbrev": "gal"
 *   },
 *   "temperature": {
 *   "name": "Fahrenheit",
 *   "abbrev": "F"
 *   }
 *   }
 * }
 * </pre>
 */
@Serializable
class UnitSystem (
    @Optional
    @SerialName("id")
    var id: String? = null,
    @Optional
    @SerialName("name")
    var name: String? = null,
    @Optional
    @SerialName("units")
    var units: LocaleUnits? = null
)

/**
 * ref.  https://flotechnologies.atlassian.net/wiki/pages/diffpagesbyversion.action?pageId=85786625&selectedPageVersions=4&selectedPageVersions=3
 */
@Serializable
class LocaleUnits (
    @Optional
    @SerialName("temperature")
    var temperature: FloUnit? = null,
    @Optional
    @SerialName("pressure")
    var pressure: FloUnit? = null,
    @Optional
    @SerialName("volume")
    var volume: FloUnit? = null
)

/**
 * ref.  https://flotechnologies.atlassian.net/wiki/pages/diffpagesbyversion.action?pageId=85786625&selectedPageVersions=4&selectedPageVersions=3
 */
@Serializable
class FloUnit (
    @Optional
    @SerialName("name")
    var name: String? = null,
    @Optional
    @SerialName("abbrev")
    var abbrev: String? = null
)

/**
 *     {
 *         "firstname": "Andrew",
 *         "lastname": "Chen",
 *         "phone_mobile": "+886000000000",
 *         "geo_locations": [
 *         {
 *             "state_or_province": null,
 *             "country": "us",
 *             "address": null,
 *             "address2": null,
 *             "city": null,
 *             "timezone": null,
 *             "postal_code": null,
 *             "location_id": "ffffffff-ffff-ffff-ffff-ffffffffffff"
 *         }
 *         ],
 *         "is_active": true,
 *         "is_system_user": false,
 *         "id": "ffffffff-ffff-ffff-ffff-ffffffffffff",
 *         "source": "mobile",
 *         "email": "andrew@example.com",
 *         "account": {
 *             "account_id": "ffffffff-ffff-ffff-ffff-ffffffffffff",
 *             "group_id": null
 *         }
 *     }
 * ```
 */
@Serializable
class UserInfos (
    @Optional
    @SerialName("total")
    var total: Int? = null,
    @Optional
    @SerialName("items")
    var items: List<UserProfile>? = null
)

/**
 *
 * ```
 * [
 *   [
 *     "0:48:19",
 *     "1:49:20"
 *   ],
 *   [
 *     "11:08:09",
 *     "11:35:12"
 *   ]
 * ]
 * ```
 *
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/692486293/Away+Mode+Endpoints#AwayModeEndpoints-GET/api/v1/awaymode/icd/:icd_id
 */
@Serializable
data class Durations (
    @SerialName("times")
    val times: List<Array<String>> = emptyList()
)

/**
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/692486293/Away+Mode+Endpoints
 */
@Serializable
class AwayMode (
    /**
     * TODO: UUID
     */
    @Optional
    @SerialName("icd_id")
    var icdId: String? = null,
    /**
     * TODO: ISO8601Date
     */
    @Optional
    @SerialName("created_at")
    var createdAt: String? = null,
    @Optional
    @SerialName("is_enabled")
    var enabled: Boolean? = null,
    @Optional
    @SerialName("times")
    var times: List<Array<String>>? = null
)

/**
 *
 * ```
 * {
 *   "device_id": DeviceId,
 *   "times": [[HourMinuteSeconds]],
 *   "status": ComputationStatus
 * }
 * ```
 *
 * times	Optional<List<List<HourMinuteSeconds>>> (Optional<List<List<<String>>>)
 * A list of paired start and end times of irrigation events. May be null, undefined, or empty.
 *
 * Example:
 *
 * ```
 * [
 *   [
 *     "0:48:19",
 *     "1:49:20"
 *   ],
 *   [
 *     "11:08:09",
 *     "11:35:12"
 *   ]
 * ]
 * ```
 *
 * device_id	DeviceId (String)	Physical ID of the device
 * status	ComputationStatus (String)
 * Status of the irrigation schedule computation. Value is one of the following:
 *
 *  - schedule_found
 *  - schedule_not_found
 *  - no_irrigation_in_home
 *  - learning
 *  - internal_error
 *
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/692486293/Away+Mode+Endpoints
 */
@Serializable
class Irrigation (
    @Optional
    @SerialName("device_id")
    var deviceId: String? = null,
    @Optional
    @SerialName("times")
    var times: List<Array<String>>? = null,
    @Optional
    @SerialName("status")
    var status: String? = null
)

fun Flo.irrigation(authorization: String): Single<Irrigation> {
    return pairedFloDevices(authorization)
            .firstElement()
            .map { it.data!! }
            .flatMapSingle { icdId -> irrigation(authorization, icdId) }
}

fun Flo.enableIrrigation(authorization: String, durations: Durations): Single<ResponseBody> {
    return pairedFloDevices(authorization)
            .firstElement()
            .map { it.data!! }
            .flatMapSingle { icdId -> enableIrrigation(authorization, icdId, durations) }
}

fun Flo.disableIrrigation(authorization: String): Single<ResponseBody> {
    return pairedFloDevices(authorization)
            .firstElement()
            .map { it.data!! }
            .flatMapSingle { icdId -> disableIrrigation(authorization, icdId) }
}

fun Flo.userId(authorization: String): Observable<String> {
    return userDetails(authorization).map {
        it.userId!!
    }
}

fun Flo.accountId(authorization: String): Observable<String> {
    return locations(authorization).map { it.accountId!! }
}

fun Flo.groupId(authorization: String): Observable<String> {
    return userId(authorization)
            .flatMap { userId -> getUserInfo(authorization, userId) }
            .map { it.items ?: emptyList() }
            .flatMap { Observable.fromIterable(it) }
            .filter { it.account != null }
            .map { it.account!! }
            .map { it.group_id ?: "" }
}

fun Flo.getPairedCertificate(authorization: String): Maybe<Certificate> =
    pairedFloDevices(authorization)
            .firstElement()
            .map { it.data!! }
            .flatMap { icdId -> certificate(authorization, icdId).firstElement() }

fun Flo.pairedFloDevices(authorization: String): Observable<FloDevice> =
    icds(authorization)
            .filter { it.paired == true }
            .filter { it.data != null }

fun Flo.away(token: String, durations: Durations = Durations(times = emptyList())): Single<ResponseBody> =
    pairedFloDevices(token)
            .firstOrError()
            .flatMap { dev -> away(token, icdId = dev.data!!, deviceId = dev.deviceId!!, durations = durations) }

fun Flo.away(token: String, deviceId: String, icdId: String, durations: Durations): Single<ResponseBody> =
    enableIrrigation(token, icdId, durations)
            .flatMap { systemMode(token, deviceId, AWAY_MODE) }

fun Flo.home(token: String, deviceId: String): Single<ResponseBody> =
    systemMode(token, deviceId, HOME_MODE)

fun Flo.home(token: String): Single<ResponseBody> =
    pairedFloDevices(token)
            .firstOrError()
            .flatMap { dev -> home(token, dev.deviceId!!) }

fun Flo.sleep(token: String, mode: SleepMode): Single<ResponseBody> =
    pairedFloDevices(token)
            .firstOrError()
            .flatMap { dev -> sleep(token, dev.deviceId!!, mode).firstOrError() }

fun Flo.logout2(token: String, id: String) = logout2(token, Logout2().apply {
    mobileDeviceId = id
})

fun Flo.logout2(token: String, id: String, awsEndpointId: String) = logout2(token, Logout3().apply {
    this.mobileDeviceId = id
    this.awsEndpointId = awsEndpointId
})

/**
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/179699727/Fixture+detection
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/470384641/FloDetect+v2.0+Feedback
 */
const val TYPE_FIXTURE_SHOWER = 1
const val TYPE_FIXTURE_TOILET = 2
const val TYPE_FIXTURE_APPLIANCE = 3
const val TYPE_FIXTURE_FAUCETS = 4
const val TYPE_FIXTURE_OTHER = 5
const val TYPE_FIXTURE_DRIP_IRRIGATION = 6
const val TYPE_FIXTURE_POOL = 7

const val SCHEDULE_FOUND = "schedule_found"
const val SCHEDULE_NOT_FOUND = "schedule_not_found"
const val NO_IRRIGATION_IN_HOME = "no_irrigation_in_home"
const val LEARNING = "learning"
const val INTERNAL_ERROR = "internal_error"

/**
 * Submit feedback for a specific alert
 *
 * ```
 * {
 *   "icd_id": UUID,
 *   "incident_id": UUID,
 *   "alarm_id": Integer,
 *   "system_mode": Integer,
 *   "should_accept_as_normal": Boolean
 *   "cause": CauseEnum,
 *   "plumbing_failure": Optional<PlumbingFailureEnum>
 * }
 * ```
 *
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/704479328/Alert+Feedback
 */
@Serializable
class AlertFeedback (
    @Optional
    @SerialName("icd_id")
    var icdId: String? = null,
    @Optional
    @SerialName("incident_id")
    var incidentId: String? = null,
    @Optional
    @SerialName("alarm_id")
    var alarmId: Int? = null,
    @Optional
    @SerialName("system_mode")
    var systemMode: Int? = null,
    @Optional
    @SerialName("should_accept_as_normal")
    var shouldAcceptAsNormal: Boolean? = null,
    @Optional
    @SerialName("cause")
    var cause: Int? = null,
    @Optional
    @SerialName("cause_other")
    var causeOther: String? = null,
    @Optional
    @SerialName("plumbing_failure")
    var plumbingFailure: Int? = null,
    @Optional
    @SerialName("plumbing_failure_other")
    var plumbingFailureOther: String? = null,
    @Optional
    @SerialName("action_taken")
    var actionTaken: String? = null,
    @Optional
    @SerialName("created_at")
    var createdAt: String? = null,
    @Optional
    @SerialName("updated_at")
    var updatedAt: String? = null
)

/**
 * Retrieve the structure for displaying the feedback flow
 *
 * ```
 * {
 *   "alarm_id": Integer,
 *   "system_mode": Integer,
 *   "options": List<FeedbackStep({
 *   "display_text": String,
 *   "sort_order": Integer,
 *   "property": String,
 *   "value": Integer | String | Boolean,
 *   "type": String,
 *   "options": Optional<List<FeedbackStep>>
 *   })>
 * }
 * ```
 *
 * ref. https://flotechnologies.atlassian.net/wiki/spaces/FLO/pages/704479328/Alert+Feedback
 */
@Serializable
class AlertFeedbackFlow (
    @Optional
    @SerialName("alarm_id")
    var alarmId: Int? = null,
    @Optional
    @SerialName("system_mode")
    var systemMode: Int? = null,
    @Optional
    @SerialName("flow")
    var flow: FeedbackStep? = null,
    /**
     * A dictionary of tagged flows that may be reused throughout the flow.
     */
    @Optional
    @SerialName("flow_tags")
    var flowTags: Map<String, FeedbackStep>? = null
)

@Serializable
data class FeedbackStepOption (
    @Optional
    @SerialName("display_text")
    var displayText: String? = null,
    @Optional
    @SerialName("sort_order")
    var sortOrder: Int? = null,
    @Optional
    @SerialName("property")
    var property: String? = null,
    @Optional
    @SerialName("value")
    var value: String? = null,
    @Optional
    @SerialName("flow")
    var flow: FeedbackStep? = null,
    /**
     * Represents the action to take if the option is selected. Possible values are
     *
     *   * "sleep_2h" => Sleep for 2 hours
     *   * "sleep_24h" => Sleep for 24 hours
     *   * null => Take no action/do nothing
     */
    @Optional
    @SerialName("action")
    var action: String? = null
)

@Serializable
class FeedbackStep (
    @Optional
    @SerialName("title_text")
    var titleText: String? = null,
    @Optional
    @SerialName("type")
    var type: String? = null,
    @Optional
    @SerialName("options")
    var options: List<FeedbackStepOption>? = null,
    /**
     * If tag is defined, then retrieve the FeedbackStep from the flow_tags and proceed from there
     */
    @Optional
    @SerialName("tag")
    var tag: String? = null
)

fun <T> Json.Companion.parseOrNull(deserializer: DeserializationStrategy<T>, string: String): T? {
    return try {
        parse(deserializer, string)
    } catch (e: Throwable) {
        e.printStackTrace()
        null
    }
}

fun <T> Json.parseOrNull(deserializer: DeserializationStrategy<T>, string: String): T? {
    return try {
        parse(deserializer, string)
    } catch (e: Throwable) {
        e.printStackTrace()
        null
    }
}

@Serializable
data class FloDetectAverages (
        @Optional
        @SerialName("averages")
        var averages: List<FloDetectAverage>? = emptyList(),
        @SerialName("device_id")
        var deviceId: String,
        @SerialName("duration_in_seconds")
        var durationInSeconds: Int,
        @SerialName("endDate")
        var endDate: String,
        @SerialName("startDate")
        var startDate: String
)

@Serializable
data class FloDetectAverage (
        @Optional
        @SerialName("fixture")
        var fixture: String? = null,
        @SerialName("gallons")
        var gallons: Double,
        @SerialName("num_events")
        var num_events: Int
)

const val SENT = "sent"
const val EXECUTED = "executed"
const val FEEDBACK_SUBMITTED = "feedback_submitted"
const val INSUFFICIENT_DATA = "insufficient_data"
