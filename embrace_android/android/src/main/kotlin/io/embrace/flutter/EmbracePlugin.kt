package io.embrace.flutter

import androidx.annotation.NonNull

import android.content.Context;

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import io.embrace.android.embracesdk.Embrace
import io.embrace.android.embracesdk.network.http.HttpMethod
import io.embrace.android.embracesdk.internal.EmbraceInternalApi
import io.embrace.android.embracesdk.internal.FlutterInternalInterface
import io.embrace.android.embracesdk.Severity
import io.embrace.android.embracesdk.network.EmbraceNetworkRequest
import io.embrace.android.embracesdk.spans.EmbraceSpan
import io.embrace.android.embracesdk.spans.ErrorCode
import io.embrace.android.embracesdk.spans.EmbraceSpanEvent

import android.os.Handler
import android.os.Looper
import android.util.Log

internal object EmbraceConstants {
    internal const val METHOD_CHANNEL_ID : String = "embrace"

    // Method Names
    internal const val ATTACH_SDK_METHOD_NAME : String = "attachToHostSdk"
    internal const val ADD_BREADCRUMB_METHOD_NAME : String = "addBreadcrumb"
    internal const val LOG_INFO_METHOD_NAME : String = "logInfo"
    internal const val LOG_WARNING_METHOD_NAME : String = "logWarning"
    internal const val LOG_ERROR_METHOD_NAME : String = "logError"
    internal const val START_VIEW_METHOD_NAME : String = "startView"
    internal const val END_VIEW_METHOD_NAME : String = "endView"
    internal const val GET_DEVICE_ID_METHOD_NAME : String = "getDeviceId"
    internal const val TRIGGER_NATIVE_ERROR_METHOD_NAME : String = "triggerNativeSdkError"
    internal const val TRIGGER_ANR_METHOD_NAME : String = "triggerAnr"
    internal const val TRIGGER_SIGNAL_METHOD_NAME : String = "triggerRaisedSignal"
    internal const val TRIGGER_CHANNEL_ERROR_METHOD_NAME : String = "triggerMethodChannelError"
    internal const val SET_USER_IDENTIFIER_METHOD_NAME : String = "setUserIdentifier"
    internal const val SET_USER_NAME_METHOD_NAME : String = "setUserName"
    internal const val SET_USER_EMAIL_METHOD_NAME : String = "setUserEmail"
    internal const val SET_USER_AS_PAYER_METHOD_NAME : String = "setUserAsPayer"
    internal const val ADD_USER_PERSONA_METHOD_NAME : String = "addUserPersona"
    internal const val CLEAR_USER_IDENTIFIER_METHOD_NAME : String = "clearUserIdentifier"
    internal const val CLEAR_USER_NAME_METHOD_NAME : String = "clearUserName"
    internal const val CLEAR_USER_EMAIL_METHOD_NAME : String = "clearUserEmail"
    internal const val CLEAR_USER_AS_PAYER_METHOD_NAME : String = "clearUserAsPayer"
    internal const val CLEAR_USER_PERSONA_METHOD_NAME : String = "clearUserPersona"
    internal const val CLEAR_ALL_USER_PERSONAS_METHOD_NAME : String = "clearAllUserPersonas"
    internal const val LOG_NETWORK_REQUEST_METHOD_NAME : String = "logNetworkRequest"
    internal const val GENERATE_W3C_TRACEPARENT_METHOD_NAME : String = "generateW3cTraceparent"
    internal const val LOG_INTERNAL_ERROR_METHOD_NAME : String = "logInternalError"
    internal const val LOG_DART_ERROR_METHOD_NAME : String = "logDartError"
    internal const val LOG_PUSH_NOTIFICATION_METHOD_NAME : String = "logPushNotification"
    internal const val ADD_SESSION_PROPERTY_METHOD_NAME : String = "addSessionProperty"
    internal const val REMOVE_SESSION_PROPERTY_METHOD_NAME : String = "removeSessionProperty"
    internal const val END_SESSION_METHOD_NAME : String = "endSession"
    internal const val GET_LAST_RUN_END_STATE_METHOD_NAME : String = "getLastRunEndState"
    internal const val GET_CURRENT_SESSION_ID_METHOD_NAME : String = "getCurrentSessionId"
    internal const val GET_SDK_VERSION_METHOD_NAME : String = "getSdkVersion"
    internal const val START_SPAN_METHOD_NAME : String = "startSpan"
    internal const val STOP_SPAN_METHOD_NAME : String = "stopSpan"
    internal const val ADD_SPAN_EVENT_METHOD_NAME : String = "addSpanEvent"
    internal const val ADD_SPAN_ATTRIBUTE_METHOD_NAME : String = "addSpanAttribute"
    internal const val RECORD_COMPLETED_SPAN_METHOD_NAME : String = "recordCompletedSpan"
    internal const val GET_TRACE_ID_METHOD_NAME : String = "getTraceId"

    // Parameter Names
    internal const val ENABLE_INTEGRATION_TESTING_ARG_NAME : String = "enableIntegrationTesting"
    internal const val PROPERTIES_ARG_NAME : String = "properties"
    internal const val NAME_ARG_NAME : String = "name"
    internal const val MESSAGE_ARG_NAME : String = "message"
    internal const val IDENTIFIER_ARG_NAME : String = "identifier"
    internal const val USER_IDENTIFIER_ARG_NAME : String = "identifier"
    internal const val USER_NAME_ARG_NAME : String = "name"
    internal const val USER_EMAIL_ARG_NAME : String = "email"
    internal const val USER_PERSONA_ARG_NAME : String = "persona"
    internal const val URL_ARG_NAME : String = "url"
    internal const val HTTP_METHOD_ARG_NAME : String = "httpMethod"
    internal const val START_TIME_ARG_NAME : String = "startTime"
    internal const val END_TIME_ARG_NAME : String = "endTime"
    internal const val BYTES_SENT_ARG_NAME : String = "bytesSent"
    internal const val BYTES_RECEIVED_ARG_NAME : String = "bytesReceived"
    internal const val STATUS_CODE_ARG_NAME : String = "statusCode"
    internal const val ERROR_ARG_NAME : String = "error"
    internal const val TRACE_ID_ARG_NAME : String = "traceId"
    internal const val W3C_TRACEPARENT_ARG_NAME : String = "traceParent"
    internal const val DETAILS_ARG_NAME : String = "details"
    internal const val EMBRACE_FLUTTER_SDK_VERSION_ARG_NAME : String = "embraceFlutterSdkVersion"
    internal const val DART_RUNTIME_VERSION_ARG_NAME : String = "dartRuntimeVersion"
    internal const val ERROR_STACK_ARG_NAME : String = "stack"
    internal const val ERROR_MESSAGE_ARG_NAME : String = "message"
    internal const val ERROR_CONTEXT_ARG_NAME : String = "context"
    internal const val ERROR_LIBRARY_ARG_NAME : String = "library"
    internal const val ERROR_TYPE_ARG_NAME : String = "type"
    internal const val ERROR_WAS_HANDLED_ARG_NAME : String = "wasHandled"
    internal const val KEY_ARG_NAME : String = "key"
    internal const val VALUE_ARG_NAME : String = "value"
    internal const val PERMANENT_ARG_NAME : String = "permanent"
    internal const val CLEAR_USER_INFO_ARG_NAME : String = "clearUserInfo"
    internal const val PUSH_TITLE_ARG_NAME : String = "title"
    internal const val PUSH_BODY_ARG_NAME : String = "body"
    internal const val PUSH_FROM_ARG_NAME : String = "from"
    internal const val PUSH_MESSAGE_ID_ARG_NAME : String = "messageId"
    internal const val PUSH_PRIORITY_ARG_NAME : String = "priority"
    internal const val PUSH_HAS_NOTIFICATION_ARG_NAME : String = "hasNotification"
    internal const val PUSH_HAS_DATA_ARG_NAME : String = "hasData"
    internal const val PARENT_SPAN_ID_ARG_NAME : String = "parentSpanId"
    internal const val START_TIME_MS_ARG_NAME : String = "startTimeMs"
    internal const val SPAN_ID_ARG_NAME : String = "spanId"
    internal const val ERROR_CODE_ARG_NAME : String = "errorCode"
    internal const val END_TIME_MS_ARG_NAME : String = "endTimeMs"
    internal const val TIMESTAMP_MS_ARG_NAME : String = "timestampMs"
    internal const val ATTRIBUTES_ARG_NAME : String = "attributes"
    internal const val EVENTS_ARG_NAME : String = "events"
}

/**
 * Extension function to convert nanoseconds to milliseconds.
 */
private fun Long.nanosToMillis(): Long {
    return this / 1_000_000
}

/** EmbracePlugin */
public class EmbracePlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    public override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) : Unit {
        channel = MethodChannel(binding.binaryMessenger, EmbraceConstants.METHOD_CHANNEL_ID)
        channel.setMethodCallHandler(this)
        context = binding.getApplicationContext()
    }

    public override fun onMethodCall(call: MethodCall, result: Result) : Unit {
        try {
            when (call.method) {
                EmbraceConstants.ATTACH_SDK_METHOD_NAME -> handleAttachSdkCall(call, result)
                EmbraceConstants.ADD_BREADCRUMB_METHOD_NAME -> handleAddBreadcrumbCall(call, result)
                EmbraceConstants.LOG_INFO_METHOD_NAME -> handleLogInfoCall(call, result)
                EmbraceConstants.LOG_WARNING_METHOD_NAME -> handleLogWarningCall(call, result)
                EmbraceConstants.LOG_ERROR_METHOD_NAME -> handleLogErrorCall(call, result)
                EmbraceConstants.LOG_NETWORK_REQUEST_METHOD_NAME -> handleLogNetworkRequestCall(call, result)
                EmbraceConstants.GENERATE_W3C_TRACEPARENT_METHOD_NAME -> handleGenerateW3cTraceparentCall(call, result)
                EmbraceConstants.START_VIEW_METHOD_NAME -> handleStartViewCall(call, result)
                EmbraceConstants.END_VIEW_METHOD_NAME -> handleEndViewCall(call, result)
                EmbraceConstants.GET_DEVICE_ID_METHOD_NAME -> handleGetDeviceIdCall(call, result)
                EmbraceConstants.TRIGGER_NATIVE_ERROR_METHOD_NAME -> handleTriggerNativeSdkError(call, result)
                EmbraceConstants.TRIGGER_ANR_METHOD_NAME -> handleTriggerAnr(call, result)
                EmbraceConstants.TRIGGER_SIGNAL_METHOD_NAME -> handleTriggerRaisedSignal(call, result)
                EmbraceConstants.TRIGGER_CHANNEL_ERROR_METHOD_NAME -> handleTriggerMethodChannelError(call, result)
                EmbraceConstants.SET_USER_IDENTIFIER_METHOD_NAME -> handleSetUserIdentifierCall(call, result)
                EmbraceConstants.CLEAR_USER_IDENTIFIER_METHOD_NAME -> handleClearUserIdentifierCall(call, result)
                EmbraceConstants.SET_USER_NAME_METHOD_NAME -> handleSetUserNameCall(call, result)
                EmbraceConstants.CLEAR_USER_NAME_METHOD_NAME -> handleClearUserNameCall(call, result)
                EmbraceConstants.SET_USER_EMAIL_METHOD_NAME -> handleSetUserEmailCall(call, result)
                EmbraceConstants.CLEAR_USER_EMAIL_METHOD_NAME -> handleClearUserEmailCall(call, result)
                EmbraceConstants.SET_USER_AS_PAYER_METHOD_NAME -> handleSetUserAsPayerCall(call, result)
                EmbraceConstants.CLEAR_USER_AS_PAYER_METHOD_NAME -> handleClearUserAsPayerCall(call, result)
                EmbraceConstants.ADD_USER_PERSONA_METHOD_NAME -> handleAddUserPersonaCall(call, result)
                EmbraceConstants.CLEAR_USER_PERSONA_METHOD_NAME -> handleClearUserPersonaCall(call, result)
                EmbraceConstants.CLEAR_ALL_USER_PERSONAS_METHOD_NAME -> handleClearAllUserPersonasCall(call, result)
                EmbraceConstants.ADD_SESSION_PROPERTY_METHOD_NAME -> handleAddSessionPropertyCall(call, result)
                EmbraceConstants.REMOVE_SESSION_PROPERTY_METHOD_NAME -> handleRemoveSessionPropertyCall(call, result)
                EmbraceConstants.END_SESSION_METHOD_NAME -> handleEndSessionCall(call, result)
                EmbraceConstants.LOG_INTERNAL_ERROR_METHOD_NAME -> handleLogInternalErrorCall(call, result)
                EmbraceConstants.LOG_DART_ERROR_METHOD_NAME -> handleLogDartErrorCall(call, result)
                EmbraceConstants.LOG_PUSH_NOTIFICATION_METHOD_NAME -> handleLogPushNotificationCall(call, result)
                EmbraceConstants.GET_LAST_RUN_END_STATE_METHOD_NAME -> handleGetLastRunEndStateCall(call, result)
                EmbraceConstants.GET_CURRENT_SESSION_ID_METHOD_NAME -> handleGetCurrentSessionIdCall(call, result)
                EmbraceConstants.GET_SDK_VERSION_METHOD_NAME -> handleGetSdkVersion(call, result)
                EmbraceConstants.START_SPAN_METHOD_NAME -> handleStartSpan(call, result)
                EmbraceConstants.STOP_SPAN_METHOD_NAME -> handleStopSpan(call, result)
                EmbraceConstants.ADD_SPAN_EVENT_METHOD_NAME -> handleAddSpanEvent(call, result)
                EmbraceConstants.ADD_SPAN_ATTRIBUTE_METHOD_NAME -> handleAddSpanAttribute(call, result)
                EmbraceConstants.RECORD_COMPLETED_SPAN_METHOD_NAME -> handleRecordCompletedSpan(call, result)
                EmbraceConstants.GET_TRACE_ID_METHOD_NAME -> handleGetTraceId(call, result)
                else -> {
                    result.notImplemented()
                    throw NotImplementedError("EmbracePlugin received a method call for ${call.method} but has no handler for that name.")
                }
            }
        } catch (e: Throwable) {
            if (call.method == EmbraceConstants.TRIGGER_CHANNEL_ERROR_METHOD_NAME) {
                throw e
            }
            safeSdkCall { 
                Log.e("EmbraceFlutter", e.message ?: "Unknown error", e)
                logError(e.message ?: "Unknown error")
            }
        }
    }

    /**
     * Performs a call on the Android SDK safely by wrapping in a try-catch & swallowing any exceptions.
     */
    private inline fun <T> safeSdkCall(action: Embrace.() -> T?): T? {
        return try {
            if (Embrace.isStarted) {
                Embrace.action()
            } else {
                null
            }
        } catch (_: Throwable) {
            null
        }
    }

    /**
     * Performs a call on the Android SDK safely by wrapping in a try-catch & swallowing any exceptions.
     */
    private inline fun <reified T> safeFlutterInterfaceCall(action: FlutterInternalInterface.() -> T?): T? {
        try {
            val obj = EmbraceInternalApi.getInstance().flutterInternalInterface
            return obj.action()
        } catch (ignored: Throwable) {
        }
        return null
    }

    public override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) : Unit {
        channel.setMethodCallHandler(null)
    }

    /// Returns the argument if it exists, otherwise returns defaultValue.
    private fun <T> MethodCall.getArgumentOrDefault(argName: String, defaultValue: T) : T {
        return this.argument<T>(argName) ?: defaultValue
    }

    /// Returns the argument if it exists, otherwise returns false
    private fun MethodCall.getBooleanArgument(argName: String) : Boolean {
        return this.getArgumentOrDefault<Boolean>(argName, false)
    }

    /// Returns the argument if it exists, otherwise returns empty string
    private fun MethodCall.getStringArgument(argName: String) : String {
        return this.getArgumentOrDefault<String>(argName, "")
    }

    /// Returns the argument if it exists, otherwise returns emptyMap
    private fun <T> MethodCall.getMapArgument(argName: String) : Map<String, T> {
        return this.getArgumentOrDefault<Map<String, T>>(argName, emptyMap<String, T>())
    }

    /// Returns the argument if it exists, otherwise returns emptyList
    private fun <T> MethodCall.getListArgument(argName: String) : List<T> {
        return this.getArgumentOrDefault<List<T>>(argName, emptyList<T>())
    }

    /// Returns the argument if it exists, otherwise returns 0
    private fun MethodCall.getIntArgument(argName: String) : Int {
        return this.getArgumentOrDefault<Int>(argName, 0)
    }

    /// Returns the argument if it exists, otherwise returns 0
    private fun MethodCall.getLongArgument(argName: String, default: Long = 0L) : Long {
        return this.getArgumentOrDefault<Long>(argName, default)
    }

    private fun MethodCall.getErrorCode(argName: String): ErrorCode? {
        val arg = getStringArgument(argName) ?: return null
        return when (arg.lowercase()) {
            "failure" -> ErrorCode.FAILURE
            "abandon" -> ErrorCode.USER_ABANDON
            "unknown" -> ErrorCode.UNKNOWN
            else -> null
        }
    }

    private fun handleAttachSdkCall(call: MethodCall, result: Result) : Unit {
        val started = Embrace.isStarted

        if (!started) {
            Embrace.start(context)
        }

        safeFlutterInterfaceCall { 
            val embraceFlutterSdkVersion = call.getStringArgument(EmbraceConstants.EMBRACE_FLUTTER_SDK_VERSION_ARG_NAME)
            val dartRuntimeVersion = call.getStringArgument(EmbraceConstants.DART_RUNTIME_VERSION_ARG_NAME)
            addEnvelopeResource("hosted_platform_version", embraceFlutterSdkVersion)
            addEnvelopeResource("hosted_sdk_version", dartRuntimeVersion) 
        }

        // 'attach' to the Android SDK at this point by requesting any information
        // required by Flutter, and passing any Flutter-specific data down to the
        // Android SDK.
        result.success(started)
        return
    }

    private fun handleAddBreadcrumbCall(call: MethodCall, result: Result) : Unit {
        val message = call.getStringArgument(EmbraceConstants.MESSAGE_ARG_NAME)
        safeSdkCall {
            addBreadcrumb(message)
        }
        result.success(null)
        return
    }

    private fun handleLogPushNotificationCall(call: MethodCall, result: Result) {
        val title = call.getStringArgument(EmbraceConstants.PUSH_TITLE_ARG_NAME)
        val body = call.getStringArgument(EmbraceConstants.PUSH_BODY_ARG_NAME)
        val from = call.getStringArgument(EmbraceConstants.PUSH_FROM_ARG_NAME)
        val id = call.getStringArgument(EmbraceConstants.PUSH_MESSAGE_ID_ARG_NAME)
        val notificationPriority = call.getIntArgument(EmbraceConstants.PUSH_PRIORITY_ARG_NAME)
        val hasNotification = call.getBooleanArgument(EmbraceConstants.PUSH_HAS_NOTIFICATION_ARG_NAME)
        val hasData = call.getBooleanArgument(EmbraceConstants.PUSH_HAS_DATA_ARG_NAME)
        safeSdkCall {
            logPushNotification(title, body, from, id, notificationPriority, 0, hasNotification, hasData)
        }
    }

    private fun handleLogInfoCall(call: MethodCall, result: Result) : Unit {
        val message = call.getStringArgument(EmbraceConstants.MESSAGE_ARG_NAME) 
        val properties = call.getMapArgument<Any>(EmbraceConstants.PROPERTIES_ARG_NAME) 
        safeSdkCall {
            logMessage(message, Severity.INFO, properties)
        }
    }

    private fun handleLogWarningCall(call: MethodCall, result: Result) : Unit {
        val message = call.getStringArgument(EmbraceConstants.MESSAGE_ARG_NAME) 
        val properties = call.getMapArgument<Any>(EmbraceConstants.PROPERTIES_ARG_NAME)
        safeSdkCall {
            logMessage(message, Severity.WARNING, properties)
        }
    }

    private fun handleLogErrorCall(call: MethodCall, result: Result) : Unit {
        val message = call.getStringArgument(EmbraceConstants.MESSAGE_ARG_NAME) 
        val properties = call.getMapArgument<Any>(EmbraceConstants.PROPERTIES_ARG_NAME)
        safeSdkCall {
            logMessage(message, Severity.ERROR, properties)
        }
    }

    private fun handleLogNetworkRequestCall(call: MethodCall, result: Result) : Unit {
        val url = call.getStringArgument(EmbraceConstants.URL_ARG_NAME)
        val method = call.getArgumentOrDefault<String?>(EmbraceConstants.HTTP_METHOD_ARG_NAME, null) ?: return
        val startTime = call.getArgumentOrDefault<Long>(EmbraceConstants.START_TIME_ARG_NAME, 0)
        val endTime = call.getArgumentOrDefault<Long>(EmbraceConstants.END_TIME_ARG_NAME, 0)
        val bytesSent = call.getArgumentOrDefault<Long>(EmbraceConstants.BYTES_SENT_ARG_NAME, 0)
        val bytesReceived = call.getArgumentOrDefault<Long>(EmbraceConstants.BYTES_RECEIVED_ARG_NAME, 0)
        val statusCode = call.getArgumentOrDefault<Int>(EmbraceConstants.STATUS_CODE_ARG_NAME, 0)
        val error = call.getArgumentOrDefault<String?>(EmbraceConstants.ERROR_ARG_NAME, null)
        val traceId = call.getArgumentOrDefault<String?>(EmbraceConstants.TRACE_ID_ARG_NAME, null)
        var w3cTraceparent = call.getArgumentOrDefault<String?>(EmbraceConstants.W3C_TRACEPARENT_ARG_NAME, null)

        if (w3cTraceparent == null) {
            w3cTraceparent = safeSdkCall {
                generateW3cTraceparent()
            }
        }
        val httpMethod = HttpMethod.fromString(method)

        val request =
            if (error != null) {
                EmbraceNetworkRequest.fromIncompleteRequest(
                    url,
                    httpMethod,
                    startTime,
                    endTime,
                    "",
                    error,
                    null,
                    w3cTraceparent,
                    null
                )
            } else {
                EmbraceNetworkRequest.fromCompletedRequest(
                    url,
                    httpMethod,
                    startTime,
                    endTime,
                    bytesSent,
                    bytesReceived,
                    statusCode,
                    traceId,
                    w3cTraceparent,
                    null
                )
            }

        safeSdkCall {
            recordNetworkRequest(request)
        }
    }

    private fun handleGenerateW3cTraceparentCall(call: MethodCall, result: Result) : Unit {
        val w3cTraceparent = safeSdkCall {
            generateW3cTraceparent()
        }
        result.success(w3cTraceparent)
    }

    private fun handleStartViewCall(call: MethodCall, result: Result) : Unit {
        val name = call.getStringArgument(EmbraceConstants.NAME_ARG_NAME)
        safeSdkCall {
            startView(name)
        }
        result.success(null)
        return
    }

    private fun handleEndViewCall(call: MethodCall, result: Result) : Unit {
        val name = call.getStringArgument(EmbraceConstants.NAME_ARG_NAME)
        safeSdkCall {
            endView(name)
        }
        result.success(null)
        return
    }

    private fun handleGetDeviceIdCall(call: MethodCall, result: Result) : Unit {
        val id = safeSdkCall {
            deviceId
        }
        result.success(id)
        return
    }

    private fun handleTriggerNativeSdkError(call: MethodCall, result: Result) : Unit {
        runOnMainThread {
            throw IllegalStateException("Whoops!")
        }
        result.success(null)
    }

    private fun handleTriggerAnr(call: MethodCall, result: Result) : Unit {
        runOnMainThread {
            java.lang.Thread.sleep(10000)
        }
        result.success(null)
    }

    private fun handleTriggerRaisedSignal(call: MethodCall, result: Result) : Unit {
        // unimplemented
        result.success(null)
    }

    private fun handleTriggerMethodChannelError(call: MethodCall, result: Result) : Unit {
        // note: Dart installs its own handler for this Thread called DartMessenger (in debug + release mode).
        // We need to intercept that to automatically capture the exception, which would be useful as
        // otherwise it'll get swallowed.
        throw IllegalStateException("Whoops!")
        result.success(null)
    }

    private fun runOnMainThread(runnable: Runnable) {
        Handler(Looper.getMainLooper()).post(runnable);
    }

    private fun handleSetUserIdentifierCall(call: MethodCall, result: Result) : Unit {
        val id = call.getStringArgument(EmbraceConstants.USER_IDENTIFIER_ARG_NAME)
        safeSdkCall {
            setUserIdentifier(id)
        }
        result.success(null)
        return
    }

    private fun handleClearUserIdentifierCall(call: MethodCall, result: Result) : Unit {
        safeSdkCall {
            clearUserIdentifier()
        }
        result.success(null)
        return
    }
    
    private fun handleSetUserNameCall(call: MethodCall, result: Result) : Unit {
        val name = call.getStringArgument(EmbraceConstants.USER_NAME_ARG_NAME)
        safeSdkCall {
            setUsername(name)
        }
        result.success(null)
        return
    }

    private fun handleClearUserNameCall(call: MethodCall, result: Result) : Unit {
        safeSdkCall {
            clearUsername()
        }
        result.success(null)
        return
    }

    private fun handleSetUserEmailCall(call: MethodCall, result: Result) : Unit {
        val email = call.getStringArgument(EmbraceConstants.USER_EMAIL_ARG_NAME)
        safeSdkCall {
            setUserEmail(email)
        }
        result.success(null)
        return
    }

    private fun handleClearUserEmailCall(call: MethodCall, result: Result) : Unit {
        safeSdkCall {
            clearUserEmail()
        }
        result.success(null)
        return
    }

    private fun handleSetUserAsPayerCall(call: MethodCall, result: Result) : Unit {
        safeSdkCall {
            addUserPersona("payer")
        }
        result.success(null)
        return
    }

    private fun handleClearUserAsPayerCall(call: MethodCall, result: Result) : Unit {
        safeSdkCall {
            clearUserPersona("payer")
        }
        result.success(null)
        return
    }

    private fun handleAddUserPersonaCall(call: MethodCall, result: Result) : Unit {
        val persona = call.getStringArgument(EmbraceConstants.USER_PERSONA_ARG_NAME)
        safeSdkCall {
            addUserPersona(persona)
        }
        result.success(null)
        return
    }

    private fun handleClearUserPersonaCall(call: MethodCall, result: Result) : Unit {
        val persona = call.getStringArgument(EmbraceConstants.USER_PERSONA_ARG_NAME)
        safeSdkCall {
            clearUserPersona(persona)
        }
        result.success(null)
        return
    }

    private fun handleClearAllUserPersonasCall(call: MethodCall, result: Result) : Unit {
        safeSdkCall {
            clearAllUserPersonas()
        }
        result.success(null)
        return
    }

    private fun handleAddSessionPropertyCall(call: MethodCall, result: Result) : Unit {
        val key = call.getStringArgument(EmbraceConstants.KEY_ARG_NAME)
        val value = call.getStringArgument(EmbraceConstants.VALUE_ARG_NAME)
        val permanent = call.getBooleanArgument(EmbraceConstants.PERMANENT_ARG_NAME)
        safeSdkCall {
            addSessionProperty(key, value, permanent)
        }
        result.success(null)
        return
    }

    private fun handleRemoveSessionPropertyCall(call: MethodCall, result: Result) : Unit {
        val key = call.getStringArgument(EmbraceConstants.KEY_ARG_NAME)
        safeSdkCall {
            removeSessionProperty(key)
        }
        result.success(null)
        return
    }

    private fun handleEndSessionCall(call: MethodCall, result: Result) : Unit {
        val clearUserInfo = call.getBooleanArgument(EmbraceConstants.CLEAR_USER_INFO_ARG_NAME)
        safeSdkCall {
            endSession(clearUserInfo)
        }
        result.success(null)
        return
    }

    private fun handleLogInternalErrorCall(call: MethodCall, result: Result) : Unit {
        val message = call.getStringArgument(EmbraceConstants.MESSAGE_ARG_NAME)
        val details = call.getStringArgument(EmbraceConstants.DETAILS_ARG_NAME)
        safeSdkCall { 
            Log.e(message, details)
            logError(message)
        }
        result.success(null)
        return
    }

    private fun handleLogDartErrorCall(call: MethodCall, result: Result) : Unit {
        val stack = call.getStringArgument(EmbraceConstants.ERROR_STACK_ARG_NAME)
        val message = call.getStringArgument(EmbraceConstants.ERROR_MESSAGE_ARG_NAME)
        val context = call.getStringArgument(EmbraceConstants.ERROR_CONTEXT_ARG_NAME)
        val library = call.getStringArgument(EmbraceConstants.ERROR_LIBRARY_ARG_NAME)
        val type = call.getStringArgument(EmbraceConstants.ERROR_TYPE_ARG_NAME)
        val wasHandled = call.getBooleanArgument(EmbraceConstants.ERROR_WAS_HANDLED_ARG_NAME)

        safeSdkCall {
            val props = mutableMapOf<String, String>()
            context?.let { props["exception.context"] = it }
            library?.let { props["exception.library"] = it }
            stack?.let { props["exception.stacktrace"] = it }
            message?.let { props["exception.message"] = it }
            type?.let { props["exception.type"] = it }
            props["emb.exception_handling"]  = if (wasHandled) "handled" else "unhandled"

            logMessage(
                severity = Severity.ERROR,
                message = "Dart error",
                properties = props
            )
        }
        result.success(null)
        return
    }

    private fun handleGetLastRunEndStateCall(call: MethodCall, result: Result) : Unit {
        val lastState = safeSdkCall {
            lastRunEndState.value
        }
        result.success(lastState)
        return
    }

    private fun handleGetCurrentSessionIdCall(call: MethodCall, result: Result) {
        val currentSessionId = safeSdkCall {
            currentSessionId
        }
        result.success(currentSessionId)
    }

    private fun handleGetSdkVersion(call: MethodCall, result: Result) {
        val version = io.embrace.android.embracesdk.core.BuildConfig::class.java
            .getField("VERSION_NAME")[null] as String
        result.success(version)
    }

    private fun handleStartSpan(call: MethodCall, result: Result) {
        val name = call.getStringArgument(EmbraceConstants.NAME_ARG_NAME)
        val parentSpanId: String? = call.argument(EmbraceConstants.PARENT_SPAN_ID_ARG_NAME)
        val startTimeMs: Long? = call.argument(EmbraceConstants.START_TIME_MS_ARG_NAME)
        val span = safeSdkCall {            
            if (parentSpanId.isNullOrEmpty() == false) {
                val parent = getSpan(parentSpanId)
                startSpan(name, parent, startTimeMs)
            }
            else {
                startSpan(name, null, startTimeMs)
            }
         }
        result.success(span)
    }

    private fun handleStopSpan(call: MethodCall, result: Result) {
        val spanId = call.getStringArgument(EmbraceConstants.SPAN_ID_ARG_NAME)
        val errorCode = call.getErrorCode(EmbraceConstants.ERROR_CODE_ARG_NAME)
        val endTimeMs: Long? = call.argument(EmbraceConstants.END_TIME_MS_ARG_NAME)
        val success = safeSdkCall {  
            val span = getSpan(spanId)
            span?.stop(errorCode, endTimeMs)
        }

        result.success(success)
    }

    private fun handleAddSpanEvent(call: MethodCall, result: Result) {
        val spanId = call.getStringArgument(EmbraceConstants.SPAN_ID_ARG_NAME)
        val name = call.getStringArgument(EmbraceConstants.NAME_ARG_NAME)
        val timestampMs: Long? = call.argument(EmbraceConstants.TIMESTAMP_MS_ARG_NAME)
        val attributes = call.getMapArgument<String>(EmbraceConstants.ATTRIBUTES_ARG_NAME)
        val success = safeSdkCall { 
            val span = getSpan(spanId)
            span?.addEvent(name, timestampMs, attributes)
        }
        result.success(success)
    }

    private fun handleAddSpanAttribute(call: MethodCall, result: Result) {
        val spanId = call.getStringArgument(EmbraceConstants.SPAN_ID_ARG_NAME)
        val key = call.getStringArgument(EmbraceConstants.KEY_ARG_NAME)
        val value = call.getStringArgument(EmbraceConstants.VALUE_ARG_NAME)
        val success = safeSdkCall { 
            val span = getSpan(spanId)
            span?.addAttribute(key, value)
         }
        result.success(success)
    }

    private fun handleRecordCompletedSpan(call: MethodCall, result: Result) {
        val name = call.getStringArgument(EmbraceConstants.NAME_ARG_NAME)
        val startTimeMs = call.getLongArgument(EmbraceConstants.START_TIME_MS_ARG_NAME)
        val endTimeMs = call.getLongArgument(EmbraceConstants.END_TIME_MS_ARG_NAME)
        val errorCode = call.getErrorCode(EmbraceConstants.ERROR_CODE_ARG_NAME)
        val parentSpanId: String? = call.argument(EmbraceConstants.PARENT_SPAN_ID_ARG_NAME)
        val attributes = call.getMapArgument<String>(EmbraceConstants.ATTRIBUTES_ARG_NAME)
        val events = call.getListArgument<Map<String, Any>>(EmbraceConstants.EVENTS_ARG_NAME)
        val success = safeSdkCall { 
            val parent = parentSpanId?.let { getSpan(it) }
            val spanEvents = events.mapNotNull { mapToEvent(it) }
            recordCompletedSpan(name, startTimeMs, endTimeMs, errorCode, parent, attributes, spanEvents)
         }
        result.success(success)
    }

    private fun handleGetTraceId(call: MethodCall, result: Result) {
        val spanId = call.getStringArgument(EmbraceConstants.SPAN_ID_ARG_NAME)
        val traceId = safeSdkCall {
            val span = getSpan(spanId)
            span?.traceId
        }
        result.success(traceId)
    }

    private fun mapToEvent(map: Map<String, Any>): EmbraceSpanEvent? {
        val name = map["name"]
        val timestampMs = map["timestampMs"] as? Long?
        val timestampNanos = (map["timestampNanos"] as? Long?)?.nanosToMillis()
        val attributes = map["attributes"]

        // If timestampMs is specified but isn't the right type, return and don't create the event
        if (timestampMs == null && map["timestampMs"] != null) {
            return null
        }

        // If timestampMs is valid, use it
        // else if timestampNanos is valid, use it
        // else if timestampNanos isn't specified, use the current time in millis
        // Otherwise, it means we have an invalid type of timestampNanos so we don't create the event
        val validatedTimeMs = timestampMs ?: timestampNanos ?: if (map["timestampNanos"] == null) {
            System.currentTimeMillis()
        } else {
            return null
        }

        return if (name is String && attributes is Map<*, *>?) {
            EmbraceSpanEvent.create(
                name = name,
                timestampMs = validatedTimeMs,
                attributes = attributes?.let { toStringMap(it) }
            )
        } else {
            null
        }
    }

    private fun toStringMap(map: Map<*, *>): Map<String, String> =
        map.entries
            .filter { it.key is String && it.value is String }
            .associate { Pair(it.key.toString(), it.value.toString()) 
    }
}
