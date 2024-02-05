package io.embrace.flutter

import androidx.annotation.NonNull

import android.content.Context;

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import io.embrace.android.embracesdk.AndroidToUnityCallback
import io.embrace.android.embracesdk.Embrace
import io.embrace.android.embracesdk.Embrace.AppFramework
import io.embrace.android.embracesdk.EmbraceSamples
import io.embrace.android.embracesdk.network.EmbraceNetworkRequestV2
import io.embrace.android.embracesdk.network.http.HttpMethod

import android.os.Handler
import android.os.Looper

internal object EmbraceConstants {
    internal const val METHOD_CHANNEL_ID : String = "embrace"

    // Method Names
    internal const val ATTACH_SDK_METHOD_NAME : String = "attachToHostSdk"
    internal const val END_STARTUP_MOMENT_METHOD_NAME : String = "endStartupMoment"
    internal const val LOG_BREADCRUMB_METHOD_NAME : String = "logBreadcrumb"
    internal const val LOG_INFO_METHOD_NAME : String = "logInfo"
    internal const val LOG_WARNING_METHOD_NAME : String = "logWarning"
    internal const val LOG_ERROR_METHOD_NAME : String = "logError"
    internal const val START_MOMENT_METHOD_NAME : String = "startMoment"
    internal const val END_MOMENT_METHOD_NAME : String = "endMoment"
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
    internal const val SET_USER_PERSONA_METHOD_NAME : String = "setUserPersona"
    internal const val CLEAR_USER_IDENTIFIER_METHOD_NAME : String = "clearUserIdentifier"
    internal const val CLEAR_USER_NAME_METHOD_NAME : String = "clearUserName"
    internal const val CLEAR_USER_EMAIL_METHOD_NAME : String = "clearUserEmail"
    internal const val CLEAR_USER_AS_PAYER_METHOD_NAME : String = "clearUserAsPayer"
    internal const val CLEAR_USER_PERSONA_METHOD_NAME : String = "clearUserPersona"
    internal const val CLEAR_ALL_USER_PERSONAS_METHOD_NAME : String = "clearAllUserPersonas"
    internal const val LOG_NETWORK_REQUEST_METHOD_NAME : String = "logNetworkRequest"
    internal const val LOG_INTERNAL_ERROR_METHOD_NAME : String = "logInternalError"
    internal const val LOG_DART_ERROR_METHOD_NAME : String = "logDartError"
    internal const val LOG_PUSH_NOTIFICATION_METHOD_NAME : String = "logPushNotification"
    internal const val ADD_SESSION_PROPERTY_METHOD_NAME : String = "addSessionProperty"
    internal const val REMOVE_SESSION_PROPERTY_METHOD_NAME : String = "removeSessionProperty"
    internal const val GET_SESSION_PROPERTIES_METHOD_NAME : String = "getSessionProperties"
    internal const val END_SESSION_METHOD_NAME : String = "endSession"
    internal const val GET_LAST_RUN_END_STATE_METHOD_NAME : String = "getLastRunEndState"

    // Parameter Names
    internal const val ENABLE_INTEGRATION_TESTING_ARG_NAME : String = "enableIntegrationTesting"
    internal const val PROPERTIES_ARG_NAME : String = "properties"
    internal const val NAME_ARG_NAME : String = "name"
    internal const val MESSAGE_ARG_NAME : String = "message"
    internal const val IDENTIFIER_ARG_NAME : String = "identifier"
    internal const val ALLOW_SCREENSHOT_ARG_NAME : String = "allowScreenshot"
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
    internal const val DETAILS_ARG_NAME : String = "details"
    internal const val EMBRACE_FLUTTER_SDK_VERSION_ARG_NAME : String = "embraceFlutterSdkVersion"
    internal const val DART_RUNTIME_VERSION_ARG_NAME : String = "dartRuntimeVersion"
    internal const val ERROR_STACK_ARG_NAME : String = "stack"
    internal const val ERROR_MESSAGE_ARG_NAME : String = "message"
    internal const val ERROR_CONTEXT_ARG_NAME : String = "context"
    internal const val ERROR_LIBRARY_ARG_NAME : String = "library"
    internal const val ERROR_TYPE_ARG_NAME : String = "type"
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
                EmbraceConstants.END_STARTUP_MOMENT_METHOD_NAME -> handleEndStartupMomentCall(call, result)
                EmbraceConstants.LOG_BREADCRUMB_METHOD_NAME -> handleLogBreadcrumbCall(call, result)
                EmbraceConstants.LOG_INFO_METHOD_NAME -> handleLogInfoCall(call, result)
                EmbraceConstants.LOG_WARNING_METHOD_NAME -> handleLogWarningCall(call, result)
                EmbraceConstants.LOG_ERROR_METHOD_NAME -> handleLogErrorCall(call, result)
                EmbraceConstants.LOG_NETWORK_REQUEST_METHOD_NAME -> handleLogNetworkRequestCall(call, result)
                EmbraceConstants.START_MOMENT_METHOD_NAME -> handleStartMomentCall(call, result)
                EmbraceConstants.END_MOMENT_METHOD_NAME -> handleEndMomentCall(call, result)
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
                EmbraceConstants.SET_USER_PERSONA_METHOD_NAME -> handleSetUserPersonaCall(call, result)
                EmbraceConstants.CLEAR_USER_PERSONA_METHOD_NAME -> handleClearUserPersonaCall(call, result)
                EmbraceConstants.CLEAR_ALL_USER_PERSONAS_METHOD_NAME -> handleClearAllUserPersonasCall(call, result)
                EmbraceConstants.ADD_SESSION_PROPERTY_METHOD_NAME -> handleAddSessionPropertyCall(call, result)
                EmbraceConstants.REMOVE_SESSION_PROPERTY_METHOD_NAME -> handleRemoveSessionPropertyCall(call, result)
                EmbraceConstants.GET_SESSION_PROPERTIES_METHOD_NAME -> handleGetSessionPropertiesCall(call, result)
                EmbraceConstants.END_SESSION_METHOD_NAME -> handleEndSessionCall(call, result)
                EmbraceConstants.LOG_INTERNAL_ERROR_METHOD_NAME -> handleLogInternalErrorCall(call, result)
                EmbraceConstants.LOG_DART_ERROR_METHOD_NAME -> handleLogDartErrorCall(call, result)
                EmbraceConstants.LOG_PUSH_NOTIFICATION_METHOD_NAME -> handleLogPushNotificationCall(call, result)
                EmbraceConstants.GET_LAST_RUN_END_STATE_METHOD_NAME -> handleGetLastRunEndStateCall(call, result)

                else -> {
                    result.notImplemented()
                    throw NotImplementedError("EmbracePlugin received a method call for ${call.method} but has no handler for that name.")
                }
            }
        } catch (e: Throwable) {
            if (call.method == EmbraceConstants.TRIGGER_CHANNEL_ERROR_METHOD_NAME) {
              throw e
            }
            Embrace.getInstance().logError(e);
        }
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
    private fun MethodCall.getMapArgument(argName: String) : Map<String, Any> {
        return this.getArgumentOrDefault<Map<String, Any>>(argName, emptyMap<String, Any>())
    }

    /// Returns the argument if it exists, otherwise returns 0
    private fun MethodCall.getIntArgument(argName: String) : Int {
        return this.getArgumentOrDefault<Int>(argName, 0)
    }

    private fun handleAttachSdkCall(call: MethodCall, result: Result) : Unit {
        val started = Embrace.getInstance().isStarted()

        if (!started) { // fallback to starting the SDK here, but log a warning.
            val enableIntegrationTesting = call.getBooleanArgument(EmbraceConstants.ENABLE_INTEGRATION_TESTING_ARG_NAME)
            Embrace.getInstance().start(context, enableIntegrationTesting, AppFramework.FLUTTER)
        }

        val embraceFlutterSdkVersion = call.getStringArgument(EmbraceConstants.EMBRACE_FLUTTER_SDK_VERSION_ARG_NAME)
        Embrace.getInstance().setEmbraceFlutterSdkVersion(embraceFlutterSdkVersion)
        val dartRuntimeVersion = call.getStringArgument(EmbraceConstants.DART_RUNTIME_VERSION_ARG_NAME)
        Embrace.getInstance().setDartVersion(dartRuntimeVersion)

        // 'attach' to the Android SDK at this point by requesting any information
        // required by Flutter, and passing any Flutter-specific data down to the
        // Android SDK.
        result.success(started)
        return
    }

    private fun handleEndStartupMomentCall(call: MethodCall, result: Result) : Unit {
        val properties = call.getMapArgument(EmbraceConstants.PROPERTIES_ARG_NAME) 
        Embrace.getInstance().endAppStartup(properties)
        result.success(null)
        return
    }

    private fun handleLogBreadcrumbCall(call: MethodCall, result: Result) : Unit {
        val message = call.getStringArgument(EmbraceConstants.MESSAGE_ARG_NAME)
        Embrace.getInstance().logBreadcrumb(message)
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
        Embrace.getInstance().logPushNotification(title, body, from, id, notificationPriority, 0, hasNotification, hasData)
    }

    private fun handleLogInfoCall(call: MethodCall, result: Result) : Unit {
        val message = call.getStringArgument(EmbraceConstants.MESSAGE_ARG_NAME) 
        val properties = call.getMapArgument(EmbraceConstants.PROPERTIES_ARG_NAME) 
        Embrace.getInstance().logInfo(message, properties)
    }

    private fun handleLogWarningCall(call: MethodCall, result: Result) : Unit {
        val message = call.getStringArgument(EmbraceConstants.MESSAGE_ARG_NAME) 
        val properties = call.getMapArgument(EmbraceConstants.PROPERTIES_ARG_NAME) 
        val allowScreenshot = call.getBooleanArgument(EmbraceConstants.ALLOW_SCREENSHOT_ARG_NAME) 
        Embrace.getInstance().logWarning(message, properties, allowScreenshot)
    }

    private fun handleLogErrorCall(call: MethodCall, result: Result) : Unit {
        val message = call.getStringArgument(EmbraceConstants.MESSAGE_ARG_NAME) 
        val properties = call.getMapArgument(EmbraceConstants.PROPERTIES_ARG_NAME) 
        val allowScreenshot = call.getBooleanArgument(EmbraceConstants.ALLOW_SCREENSHOT_ARG_NAME) 
        Embrace.getInstance().logError(message, properties, allowScreenshot)
    }

    private fun handleLogNetworkRequestCall(call: MethodCall, result: Result) : Unit {
        val url = call.getStringArgument(EmbraceConstants.URL_ARG_NAME)
        val method = call.getArgumentOrDefault<String?>(EmbraceConstants.HTTP_METHOD_ARG_NAME, null)
        val startTime = call.getArgumentOrDefault<Long>(EmbraceConstants.START_TIME_ARG_NAME, 0)
        val endTime = call.getArgumentOrDefault<Long>(EmbraceConstants.END_TIME_ARG_NAME, 0)
        val bytesSent = call.getArgumentOrDefault<Int>(EmbraceConstants.BYTES_SENT_ARG_NAME, 0)
        val bytesReceived = call.getArgumentOrDefault<Int>(EmbraceConstants.BYTES_RECEIVED_ARG_NAME, 0)
        val statusCode = call.getArgumentOrDefault<Int>(EmbraceConstants.STATUS_CODE_ARG_NAME, 0)
        val error = call.getArgumentOrDefault<String?>(EmbraceConstants.ERROR_ARG_NAME, null)
        val traceId = call.getArgumentOrDefault<String?>(EmbraceConstants.TRACE_ID_ARG_NAME, null)

        val requestBuilder = EmbraceNetworkRequestV2.newBuilder()
            .withUrl(url)
            .withHttpMethod(HttpMethod.fromString(method))
            .withStartTime(startTime)
            .withEndTime(endTime)
            .withBytesIn(bytesSent)
            .withBytesOut(bytesReceived)
            .withResponseCode(statusCode)
            
        if (error != null) {
            requestBuilder.withError(Error(error))
        }

        if (traceId != null) {
            requestBuilder.withTraceId(traceId)
        }

        Embrace.getInstance().logNetworkRequest(requestBuilder.build())
    }

    private fun handleStartMomentCall(call: MethodCall, result: Result) : Unit {
        val name = call.getStringArgument(EmbraceConstants.NAME_ARG_NAME)
        val identifier = call.getStringArgument(EmbraceConstants.IDENTIFIER_ARG_NAME)
        val allowScreenshot = call.getBooleanArgument(EmbraceConstants.ALLOW_SCREENSHOT_ARG_NAME)
        val properties = call.getMapArgument(EmbraceConstants.PROPERTIES_ARG_NAME)
        Embrace.getInstance().startEvent(name, identifier, allowScreenshot, properties)
        result.success(null)
        return
    }

    private fun handleEndMomentCall(call: MethodCall, result: Result) : Unit {
        val name = call.getStringArgument(EmbraceConstants.NAME_ARG_NAME)
        val identifier = call.getStringArgument(EmbraceConstants.IDENTIFIER_ARG_NAME)
        val properties = call.getMapArgument(EmbraceConstants.PROPERTIES_ARG_NAME)
        Embrace.getInstance().endEvent(name, identifier, properties)
        result.success(null)
        return
    }

    private fun handleStartViewCall(call: MethodCall, result: Result) : Unit {
        val name = call.getStringArgument(EmbraceConstants.NAME_ARG_NAME)
        Embrace.getInstance().startFragment(name)
        result.success(null)
        return
    }

    private fun handleEndViewCall(call: MethodCall, result: Result) : Unit {
        val name = call.getStringArgument(EmbraceConstants.NAME_ARG_NAME)
        Embrace.getInstance().endFragment(name)
        result.success(null)
        return
    }

    private fun handleGetDeviceIdCall(call: MethodCall, result: Result) : Unit {
        val id: String = Embrace.getInstance().getDeviceId()
        result.success(id)
        return
    }

    private fun handleTriggerNativeSdkError(call: MethodCall, result: Result) : Unit {
        runOnMainThread {
            EmbraceSamples.throwJvmException()
        }
        result.success(null)
    }

    private fun handleTriggerAnr(call: MethodCall, result: Result) : Unit {
        runOnMainThread {
            EmbraceSamples.triggerLongAnr()
        }
        result.success(null)
    }

    private fun handleTriggerRaisedSignal(call: MethodCall, result: Result) : Unit {
        EmbraceSamples.causeNdkIllegalInstruction()
        result.success(null)
    }

    private fun handleTriggerMethodChannelError(call: MethodCall, result: Result) : Unit {
        // note: Dart installs its own handler for this Thread called DartMessenger (in debug + release mode).
        // We need to intercept that to automatically capture the exception, which would be useful as
        // otherwise it'll get swallowed.
        print("Method channel error!")
        EmbraceSamples.throwJvmException()
        result.success(null)
    }

    private fun runOnMainThread(runnable: Runnable) {
        Handler(Looper.getMainLooper()).post(runnable);
    }

    private fun handleSetUserIdentifierCall(call: MethodCall, result: Result) : Unit {
        val id = call.getStringArgument(EmbraceConstants.USER_IDENTIFIER_ARG_NAME)
        Embrace.getInstance().setUserIdentifier(id)
        result.success(null)
        return
    }

    private fun handleClearUserIdentifierCall(call: MethodCall, result: Result) : Unit {
        Embrace.getInstance().clearUserIdentifier()
        result.success(null)
        return
    }
    
    private fun handleSetUserNameCall(call: MethodCall, result: Result) : Unit {
        val name = call.getStringArgument(EmbraceConstants.USER_NAME_ARG_NAME)
        Embrace.getInstance().setUsername(name)
        result.success(null)
        return
    }

    private fun handleClearUserNameCall(call: MethodCall, result: Result) : Unit {
        Embrace.getInstance().clearUsername()
        result.success(null)
        return
    }

    private fun handleSetUserEmailCall(call: MethodCall, result: Result) : Unit {
        val email = call.getStringArgument(EmbraceConstants.USER_EMAIL_ARG_NAME)
        Embrace.getInstance().setUserEmail(email)
        result.success(null)
        return
    }

    private fun handleClearUserEmailCall(call: MethodCall, result: Result) : Unit {
        Embrace.getInstance().clearUserEmail()
        result.success(null)
        return
    }

    private fun handleSetUserAsPayerCall(call: MethodCall, result: Result) : Unit {
        Embrace.getInstance().setUserAsPayer()
        result.success(null)
        return
    }

    private fun handleClearUserAsPayerCall(call: MethodCall, result: Result) : Unit {
        Embrace.getInstance().clearUserAsPayer()
        result.success(null)
        return
    }

    private fun handleSetUserPersonaCall(call: MethodCall, result: Result) : Unit {
        val persona = call.getStringArgument(EmbraceConstants.USER_PERSONA_ARG_NAME)
        Embrace.getInstance().setUserPersona(persona)
        result.success(null)
        return
    }

    private fun handleClearUserPersonaCall(call: MethodCall, result: Result) : Unit {
        val persona = call.getStringArgument(EmbraceConstants.USER_PERSONA_ARG_NAME)
        Embrace.getInstance().clearUserPersona(persona)
        result.success(null)
        return
    }

    private fun handleClearAllUserPersonasCall(call: MethodCall, result: Result) : Unit {
        Embrace.getInstance().clearAllUserPersonas()
        result.success(null)
        return
    }

    private fun handleAddSessionPropertyCall(call: MethodCall, result: Result) : Unit {
        val key = call.getStringArgument(EmbraceConstants.KEY_ARG_NAME)
        val value = call.getStringArgument(EmbraceConstants.VALUE_ARG_NAME)
        val permanent = call.getBooleanArgument(EmbraceConstants.PERMANENT_ARG_NAME)
        Embrace.getInstance().addSessionProperty(key, value, permanent)
        result.success(null)
        return
    }

    private fun handleRemoveSessionPropertyCall(call: MethodCall, result: Result) : Unit {
        val key = call.getStringArgument(EmbraceConstants.KEY_ARG_NAME)
        Embrace.getInstance().removeSessionProperty(key)
        result.success(null)
        return
    }

    private fun handleGetSessionPropertiesCall(call: MethodCall, result: Result) : Unit {
        val properties = Embrace.getInstance().getSessionProperties()
        result.success(properties)
        return
    }

    private fun handleEndSessionCall(call: MethodCall, result: Result) : Unit {
        val clearUserInfo = call.getBooleanArgument(EmbraceConstants.CLEAR_USER_INFO_ARG_NAME)
        Embrace.getInstance().endSession(clearUserInfo)
        result.success(null)
        return
    }

    private fun handleLogInternalErrorCall(call: MethodCall, result: Result) : Unit {
        val message = call.getStringArgument(EmbraceConstants.MESSAGE_ARG_NAME)
        val details = call.getStringArgument(EmbraceConstants.DETAILS_ARG_NAME)
        Embrace.getInstance().logInternalError(message, details)
        result.success(null)
        return
    }

    private fun handleLogDartErrorCall(call: MethodCall, result: Result) : Unit {
        val stack = call.getStringArgument(EmbraceConstants.ERROR_STACK_ARG_NAME)
        val message = call.getStringArgument(EmbraceConstants.ERROR_MESSAGE_ARG_NAME)
        val context = call.getStringArgument(EmbraceConstants.ERROR_CONTEXT_ARG_NAME)
        val library = call.getStringArgument(EmbraceConstants.ERROR_LIBRARY_ARG_NAME)
        val type = call.getStringArgument(EmbraceConstants.ERROR_TYPE_ARG_NAME)
        try {
            Embrace.getInstance().logDartErrorWithType(stack, message, context, library, type)
        } catch (nsm: NoSuchMethodError) {
            // If the underlying Embrace Android SDK < 5.14.2, then use the older method
            Embrace.getInstance().logDartError(stack, message, context, library)
        }
        result.success(null)
        return
    }

    private fun handleGetLastRunEndStateCall(call: MethodCall, result: Result) : Unit {
        try {
            val lastState = Embrace.getInstance().lastRunEndState.value
            result.success(lastState)
        } catch (nsm: NoSuchMethodError) {
            // The method was implemented in Embrace Android SDK 5.21.0
            result.notImplemented()
        }
        return
    }
}
