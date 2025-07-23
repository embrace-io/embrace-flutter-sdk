import Flutter
import UIKit
import EmbraceIO
import EmbraceCore
import OpenTelemetryApi
import EmbraceOTelInternal

public class EmbracePlugin: NSObject, FlutterPlugin {

    static let MethodChannelId = "embrace"

    // Method Names
    static let AttachSdkMethodName = "attachToHostSdk"
    static let AddBreadcrumbMethodName = "addBreadcrumb"
    static let LogPushNotificationMethodName = "logPushNotification"
    static let LogInfoMethodName = "logInfo"
    static let LogWarningMethodName = "logWarning"
    static let LogErrorMethodName = "logError"
    static let StartViewMethodName = "startView"
    static let EndViewMethodName = "endView"
    static let GetDeviceIdMethodName = "getDeviceId"
    static let TriggerNativeErrorMethodName = "triggerNativeSdkError"
    static let TriggerSignalMethodName = "triggerRaisedSignal"
    static let TriggerChannelErrorMethodName = "triggerMethodChannelError"
    static let SetUserIdentifierMethodName = "setUserIdentifier"
    static let SetUserNameMethodName = "setUserName"
    static let SetUserEmailMethodName = "setUserEmail"
    static let SetUserAsPayerMethodName = "setUserAsPayer"
    static let AddUserPersonaMethodName = "addUserPersona"
    static let ClearUserIdentifierMethodName = "clearUserIdentifier"
    static let ClearUserNameMethodName = "clearUserName"
    static let ClearUserEmailMethodName = "clearUserEmail"
    static let ClearUserAsPayerMethodName = "clearUserAsPayer"
    static let ClearUserPersonaMethodName = "clearUserPersona"
    static let ClearAllUserPersonasMethodName = "clearAllUserPersonas"
    static let LogNetworkRequestMethodName = "logNetworkRequest"
    static let LogInternalErrorMethodName = "logInternalError"
    static let LogDartErrorMethodName = "logDartError"
    static let AddSessionPropertyMethodName = "addSessionProperty"
    static let RemoveSessionPropertyMethodName = "removeSessionProperty"
    static let EndSessionMethodName = "endSession"
    static let GetLastRunEndStateMethodName = "getLastRunEndState"
    static let GetCurrentSessionIdMethodName = "getCurrentSessionId"
    static let GetSdkVersionMethodName = "getSdkVersion"
    static let StartSpanMethodName = "startSpan"
    static let StopSpanMethodName = "stopSpan"
    static let AddSpanEventMethodName = "addSpanEvent"
    static let AddSpanAttributeMethodName = "addSpanAttribute"
    static let RecordCompletedSpanMethodName = "recordCompletedSpan"
    static let GenerateW3cTraceparentMethodName = "generateW3cTraceparent"
    static let GetTraceIdMethodName = "getTraceId"

    // Parameter Names
    static let PropertiesArgName = "properties"
    static let NameArgName = "name"
    static let MessageArgName = "message"
    static let IdentifierArgName = "identifier"
    static let UserIdentifierArgName = "identifier"
    static let UserNameArgName = "name"
    static let UserEmailArgName = "email"
    static let UserPersonaArgName = "persona"
    static let UrlArgName = "url"
    static let HttpMethodArgName = "httpMethod"
    static let StartTimeArgName = "startTime"
    static let EndTimeArgName = "endTime"
    static let BytesSentArgName = "bytesSent"
    static let BytesReceivedArgName = "bytesReceived"
    static let StatusCodeArgName = "statusCode"
    static let ErrorArgName = "error"
    static let TraceIdArgName = "traceId"
    static let DetailsArgName = "details"
    static let EmbraceFlutterSdkVersionArgName = "embraceFlutterSdkVersion"
    static let DartRuntimeVersionArgName = "dartRuntimeVersion"
    static let ErrorStackArgName = "stack"
    static let ErrorMessageArgName = "message"
    static let ErrorContextArgName = "context"
    static let ErrorLibraryArgName = "library"
    static let ErrorTypeArgName = "type"
    static let ErrorWasHandledArgName = "wasHandled"
    static let KeyArgName = "key"
    static let ValueArgName = "value"
    static let PermanentArgName = "permanent"
    static let ClearUserInfoArgName = "clearUserInfo"
    static let TitleArgName = "title"
    static let BodyArgName = "body"
    static let SubtitleArgName = "subtitle"
    static let BadgeArgName = "badge"
    static let CategoryArgName = "category"
    static let NetworkErrorUserInfoKey = "userinfo"
    static let ParentSpanIdArgName = "parentSpanId"
    static let StartTimeMsArgName = "startTimeMs"
    static let SpanIdArgName = "spanId"
    static let ErrorCodeArgName = "errorCode"
    static let EndTimeMsArgName = "endTimeMs"
    static let TimestampMsArgName = "timestampMs"
    static let AttributesArgName = "attributes"
    static let EventsArgName = "events"
    static let W3cTraceparentArgName = "traceParent"

    // OTel keys
    static let SpanScreenView = "emb-screen-view"
    static let AttrViewName = "view.name"
    static let AttrEmbType = "emb.type"
    static let AttrUrl = "url.full"
    static let AttrHttpMethod = "http.request.method"
    static let AttrHttpStatusCode = "http.response.status_code"
    static let AttrHttpRequestBodySize = "http.request.body.size"
    static let AttrHttpResponseBodySize = "http.response.body.size"
    static let AttrErrorMessage = "error.message"
    static let AttrTraceId = "emb.trace_id"
    static let AttrW3cTraceparent = "emb.w3c_traceparent"
    static let TypeUxView = "ux.view"
    static let TypeNetworkRequest = "perf.network_request"
    static let AttrExcStacktrace = "exception.stacktrace"
    static let AttrExcType = "exception.type"
    static let AttrExcMessage = "exception.message"
    static let AttrExcHandling = "emb.exception_handling"

    private let repository = EmbraceSpanRepository()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: MethodChannelId, binaryMessenger: registrar.messenger())
        let instance = EmbracePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case EmbracePlugin.AttachSdkMethodName:
                handleAttachSdkCall(call, result: result)
            case EmbracePlugin.AddBreadcrumbMethodName:
                handleAddBreadcrumbCall(call, result: result)
            case EmbracePlugin.LogPushNotificationMethodName:
                handleLogPushNotificationCall(call, result: result)
            case EmbracePlugin.LogInfoMethodName:
                handleLogInfoCall(call, result: result)
            case EmbracePlugin.LogWarningMethodName:
                handleLogWarningCall(call, result: result)
            case EmbracePlugin.LogErrorMethodName:
                handleLogErrorCall(call, result: result)
            case EmbracePlugin.LogNetworkRequestMethodName:
                handleLogNetworkRequestCall(call, result: result)
            case EmbracePlugin.StartViewMethodName:
                handleStartViewCall(call, result: result)
            case EmbracePlugin.EndViewMethodName:
                handleEndViewCall(call, result: result)
            case EmbracePlugin.GetDeviceIdMethodName:
                handleGetDeviceIdCall(call, result: result)
            case EmbracePlugin.TriggerNativeErrorMethodName:
                handleNativeError(call, result: result)
            case EmbracePlugin.TriggerSignalMethodName:
                handleTriggerSignal(call, result: result)
            case EmbracePlugin.TriggerChannelErrorMethodName:
                handleTriggerChannelError(call, result: result)
            case EmbracePlugin.SetUserIdentifierMethodName:
                handleSetUserIdentifierCall(call, result: result)
            case EmbracePlugin.ClearUserIdentifierMethodName:
                handleClearUserIdentifierCall(call, result: result)
            case EmbracePlugin.SetUserNameMethodName:
                handleSetUserNameCall(call, result: result)
            case EmbracePlugin.ClearUserNameMethodName:
                handleClearUserNameCall(call, result: result)
            case EmbracePlugin.SetUserEmailMethodName:
                handleSetUserEmailCall(call, result: result)
            case EmbracePlugin.ClearUserEmailMethodName:
                handleClearUserEmailCall(call, result: result)
            case EmbracePlugin.SetUserAsPayerMethodName:
                handleSetUserAsPayerCall(call, result: result)
            case EmbracePlugin.ClearUserAsPayerMethodName:
                handleClearUserAsPayerCall(call, result: result)
            case EmbracePlugin.AddUserPersonaMethodName:
                handleAddUserPersonaCall(call, result: result)
            case EmbracePlugin.ClearUserPersonaMethodName:
                handleClearUserPersonaCall(call, result: result)
            case EmbracePlugin.ClearAllUserPersonasMethodName:
                handleClearAllUserPersonasCall(call, result: result)
            case EmbracePlugin.AddSessionPropertyMethodName:
                handleAddSessionPropertyCall(call, result: result)
            case EmbracePlugin.RemoveSessionPropertyMethodName:
                handleRemoveSessionPropertyCall(call, result: result)
            case EmbracePlugin.EndSessionMethodName:
                handleEndSessionCall(call, result: result)
            case EmbracePlugin.LogInternalErrorMethodName:
                handleLogInternalErrorCall(call, result: result)
            case EmbracePlugin.LogDartErrorMethodName:
                handleLogDartErrorCall(call, result: result)
            case EmbracePlugin.GetLastRunEndStateMethodName:
                handleGetLastRunEndStateCall(call, result: result)
            case EmbracePlugin.GetCurrentSessionIdMethodName:
                handleGetCurrentSessionIdCall(call, result: result)
            case EmbracePlugin.GetSdkVersionMethodName:
                handleGetSdkVersionCall(call, result: result)
            case EmbracePlugin.StartSpanMethodName:
                handleStartSpanCall(call, result: result)
            case EmbracePlugin.StopSpanMethodName:
                handleStopSpanCall(call, result: result)
            case EmbracePlugin.AddSpanEventMethodName:
                handleAddSpanEventCall(call, result: result)
            case EmbracePlugin.AddSpanAttributeMethodName:
                handleAddSpanAttributeCall(call, result: result)
            case EmbracePlugin.RecordCompletedSpanMethodName:
                handleRecordCompletedSpanCall(call, result: result)
            case EmbracePlugin.GenerateW3cTraceparentMethodName:
                handleGenerateW3cTraceparentCall(call, result: result)
            case EmbracePlugin.GetTraceIdMethodName:
                handleGetTraceIdCall(call, result: result)
            default:
                result(FlutterMethodNotImplemented)
        }
    }

    private func handleAttachSdkCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        var started = false
        if let client = Embrace.client,
           let args = call.arguments as? [String: Any],
           let flutterSdkVersion = args[EmbracePlugin.EmbraceFlutterSdkVersionArgName] as? String,
           let dartRuntimeVersion = args[EmbracePlugin.DartRuntimeVersionArgName] as? String {
            started = client.state == .started

            if (started) { // fallback to starting the SDK here, but log a warning.
                try? client.metadata.addResource(key: "emb_flutter_sdk_version", value: flutterSdkVersion, lifespan:.process)
                try? client.metadata.addResource(key: "emb_dart_runtime_version", value: dartRuntimeVersion, lifespan:.process)
            }
        }

        // 'attach' to the iOS SDK at this point by requesting any information
        // required by Flutter, and passing any Flutter-specific data down to the
        // iOS SDK.
        result(NSNumber(value: started))
    }

    private func handleAddBreadcrumbCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let message = args[EmbracePlugin.MessageArgName] as? String {
                client.add(event: .breadcrumb(message, properties: [:]))
            }
            result(nil)
        }
    }

    private func handleLogPushNotificationCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let title = args[EmbracePlugin.TitleArgName] as? String,
                let body = args[EmbracePlugin.BodyArgName] as? String,
                let subtitle = args[EmbracePlugin.SubtitleArgName] as? String,
                let badge = args[EmbracePlugin.BadgeArgName] as? Int,
                let category = args[EmbracePlugin.CategoryArgName] as? String {

                let pushData: [AnyHashable: Any?] = [
                    "aps": [
                        "alert" : [
                            "title" : title,
                            "subtitle" : subtitle,
                            "body" : body
                        ],
                        "badge" : badge,
                        "category" : category
                    ]
                ]
                try? client.add(event: .push(userInfo: pushData as [AnyHashable : Any]))
            }
            result(nil)
        }
    }

    private func handleLogInfoCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let message = args[EmbracePlugin.MessageArgName] as? String {
                let props = args[EmbracePlugin.PropertiesArgName] as? [String: String] ?? [:]
                client.log(message, severity: .info, attributes: props)
            }
        }
    }

    private func handleLogWarningCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let message = args[EmbracePlugin.MessageArgName] as? String {
                let props = args[EmbracePlugin.PropertiesArgName] as? [String: String] ?? [:]
                client.log(message, severity: .warn, attributes: props)
            }
        }
    }

    private func handleLogErrorCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let message = args[EmbracePlugin.MessageArgName] as? String {
                let props = args[EmbracePlugin.PropertiesArgName] as? [String: String] ?? [:]
                client.log(message, severity: .error, attributes: props)
            }
        }
    }

    private func handleLogNetworkRequestCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let url = args[EmbracePlugin.UrlArgName] as? String,
                let sanitizedUrl = stripQueryAndFragment(urlString: url),
                let path = getUrlPath(urlString: sanitizedUrl),
                let method = args[EmbracePlugin.HttpMethodArgName] as? String,
                let startTime = args[EmbracePlugin.StartTimeArgName] as? Int,
                let endTime = args[EmbracePlugin.EndTimeArgName] as? Int {

                let statusCode = String(args[EmbracePlugin.StatusCodeArgName] as? Int ?? -1)
                let bytesSent = String(args[EmbracePlugin.BytesSentArgName] as? Int ?? -1)
                let bytesReceived = String(args[EmbracePlugin.BytesReceivedArgName] as? Int ?? -1)
                let err = args[EmbracePlugin.ErrorArgName] as? String
                let traceId = args[EmbracePlugin.TraceIdArgName] as? String
                let w3cTraceparent = args[EmbracePlugin.W3cTraceparentArgName] as? String

                let attrs: [String : String?] = [
                    EmbracePlugin.AttrEmbType : EmbracePlugin.TypeNetworkRequest,
                    EmbracePlugin.AttrUrl : sanitizedUrl,
                    EmbracePlugin.AttrHttpMethod: method,
                    EmbracePlugin.AttrHttpStatusCode : statusCode,
                    EmbracePlugin.AttrHttpRequestBodySize : bytesSent,
                    EmbracePlugin.AttrHttpResponseBodySize : bytesReceived,
                    EmbracePlugin.AttrErrorMessage : err,
                    EmbracePlugin.AttrTraceId : traceId,
                    EmbracePlugin.AttrW3cTraceparent : w3cTraceparent
                ]
                let filteredAttrs = attrs.compactMapValues { $0 }

                // construct span
                let builder = client.buildSpan(name: method + " " + path)
                filteredAttrs.forEach { (key: String, value: String) in
                    builder.setAttribute(key: key, value: value)
                }
                let span = builder.setStartTime(time: Date(timeIntervalSince1970: TimeInterval(startTime) / 1000))
                    .startSpan()

                if (w3cTraceparent == nil) {
                    let trid = span.context.traceId.hexString
                    let spid = span.context.spanId.hexString
                    let traceParent = W3C.traceparent(traceId: trid, spanId: spid)
                    span.setAttribute(key: EmbracePlugin.AttrW3cTraceparent, value: traceParent)
                }
                span.end(time: Date(timeIntervalSince1970: TimeInterval(endTime) / 1000))
            }
            result(nil)
        }
    }

    private func stripQueryAndFragment(urlString: String) -> String? {
        guard var components = URLComponents(string: urlString) else {
            return nil
        }
        components.query = nil
        components.fragment = nil
        return components.url?.absoluteString
    }

    private func getUrlPath(urlString: String) -> String? {
        guard let components = URLComponents(string: urlString) else {
            return nil
        }
        return components.path
    }

    private var viewSpanDict: [String : Span] = [:]

    private func handleStartViewCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let viewName = args[EmbracePlugin.NameArgName] as? String {

                // End the previous view if one already exists.
                viewSpanDict.removeValue(forKey: viewName)?.end()
                viewSpanDict[viewName] = client.buildSpan(name: EmbracePlugin.SpanScreenView)
                    .setAttribute(key: EmbracePlugin.AttrViewName, value: viewName)
                    .setAttribute(key: EmbracePlugin.AttrEmbType, value: EmbracePlugin.TypeUxView)
                    .startSpan()
            }
            result(nil)
        }
    }

    private func handleEndViewCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let viewName = args[EmbracePlugin.NameArgName] as? String {
                    viewSpanDict.removeValue(forKey: viewName)?.end()
                }
            result(nil)
        }
    }

    private func handleGetDeviceIdCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            result(client.currentDeviceId())
        }
    }

    private func handleNativeError(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSException(name: NSExceptionName.invalidArgumentException, reason: "Embrace sample: throwing NSError", userInfo: nil).raise()
        result(nil)
    }

    private func handleTriggerSignal(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        raise(SIGABRT)
    }

    private func handleTriggerChannelError(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSException(name: NSExceptionName.invalidArgumentException, reason: "Embrace sample: throwing NSError", userInfo: nil).raise()
        result(nil)
    }

    private func handleSetUserIdentifierCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let userId = args[EmbracePlugin.UserIdentifierArgName] as? String {
                client.metadata.userIdentifier = userId
            }
            result(nil)
        }
    }

    private func handleClearUserIdentifierCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            client.metadata.userIdentifier = nil
            result(nil)
        }
    }

    private func handleSetUserNameCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let userName = args[EmbracePlugin.UserNameArgName] as? String {
                    client.metadata.userName = userName
                }
            result(nil)
        }
    }

    private func handleClearUserNameCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            client.metadata.userName = nil
            result(nil)
        }
    }

    private func handleSetUserEmailCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let userEmail = args[EmbracePlugin.UserEmailArgName] as? String {
                    client.metadata.userEmail = userEmail
                }
            result(nil)
        }
    }

    private func handleClearUserEmailCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            client.metadata.userEmail = nil
            result(nil)
        }
    }

    private func handleSetUserAsPayerCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            try? client.metadata.add(persona: PersonaTag("payer"), lifespan: .process)
            result(nil)
        }
    }

    private func handleClearUserAsPayerCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            try? client.metadata.remove(persona: PersonaTag("payer"), lifespan: .process)
            result(nil)
        }
    }

    private func handleAddUserPersonaCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let persona = args[EmbracePlugin.UserPersonaArgName] as? String {
                    try? client.metadata.add(persona: PersonaTag(persona), lifespan: .process)
                }
            result(nil)
        }
    }

    private func handleClearUserPersonaCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let persona = args[EmbracePlugin.UserPersonaArgName] as? String {
                    try? client.metadata.remove(persona: PersonaTag(persona), lifespan: .process)
                }
            result(nil)
        }
    }

    private func handleClearAllUserPersonasCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            try? client.metadata.removeAllPersonas()
            result(nil)
        }
    }

    private func handleAddSessionPropertyCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let keyStr = args[EmbracePlugin.KeyArgName] as? String,
                let valueStr = args[EmbracePlugin.ValueArgName] as? String {
                    let perm = args[EmbracePlugin.PermanentArgName] as? Bool ?? false
                    try? client.metadata.addProperty(key: keyStr, value: valueStr, lifespan: perm ? .permanent : .session)
                }
            result(nil)
        }
    }

    private func handleRemoveSessionPropertyCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let keyStr = args[EmbracePlugin.KeyArgName] as? String {
                    try? client.metadata.removeProperty(key: keyStr)
                }
            result(nil)
        }
    }

    private func handleEndSessionCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            client.endCurrentSession()
            result(nil)
        }
    }

    private func handleLogInternalErrorCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // no-op
        result(nil)
    }

    private func handleLogDartErrorCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let message = args[EmbracePlugin.ErrorMessageArgName] as? String,
                let type = args[EmbracePlugin.ErrorTypeArgName] as? String,
                let stack = args[EmbracePlugin.ErrorStackArgName] as? String {
                    let handled = args[EmbracePlugin.ErrorWasHandledArgName] as? Bool ?? false
                    let attrs = [
                        EmbracePlugin.AttrExcStacktrace: stack,
                        EmbracePlugin.AttrExcType: type,
                        EmbracePlugin.AttrExcHandling : handled ? "HANDLED" : "UNHANDLED",
                        EmbracePlugin.AttrExcMessage : message
                    ]
                    client.log(message, severity: .error, type: .exception, attributes: attrs, stackTraceBehavior: .notIncluded)
                }
        }
    }

    private func handleGetLastRunEndStateCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            var ordinal = 0
            let state = client.lastRunEndState()
            switch(state) {
                case .cleanExit:
                    ordinal = 2
                case .crash:
                    ordinal = 1
                case .unavailable:
                    ordinal = 0
                @unknown default:
                    ordinal = 0
            }
            result(NSNumber(value: ordinal))
        }
    }

    private func handleGetCurrentSessionIdCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            result(client.currentSessionId())
        }
    }

    private func handleGetSdkVersionCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(Embrace.sdkVersion)
    }

    private func handleStartSpanCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let name = args[EmbracePlugin.NameArgName] as? String {
                let parentSpanId = args[EmbracePlugin.ParentSpanIdArgName] as? String
                let startTimeMs = args[EmbracePlugin.StartTimeMsArgName] as? Int
                let spanId = repository.startSpan(name: name, parentSpanId: parentSpanId, startTimeMs: startTimeMs)
                result(spanId)
            } else {
                result(nil)
            }
        }
    }

    private func handleStopSpanCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let spanId = args[EmbracePlugin.SpanIdArgName] as? String {
                    let endTimeMs = args[EmbracePlugin.EndTimeMsArgName] as? Int
                    let errorCode = args[EmbracePlugin.ErrorCodeArgName] as? String
                    let success = repository.stopSpan(spanId: spanId, endTimeMs: endTimeMs, errorCode: errorCode)
                    result(NSNumber(value: success))
                } else {
                    result(NSNumber(value: false))
                }
        }
    }

    private func handleAddSpanEventCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let spanId = args[EmbracePlugin.SpanIdArgName] as? String,
                let name = args[EmbracePlugin.NameArgName] as? String {
                    let timestampMs = args[EmbracePlugin.TimestampMsArgName] as? Int
                    let attrs = args[EmbracePlugin.AttributesArgName] as? [String: String] ?? [:]
                    let success = repository.addSpanEvent(spanId: spanId, name: name, timestampMs: timestampMs, attributes: attrs)
                    result(NSNumber(value: success))
                } else {
                    result(NSNumber(value: false))
                }
        }
    }

    private func handleAddSpanAttributeCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let spanId = args[EmbracePlugin.SpanIdArgName] as? String,
                let keyObj = args[EmbracePlugin.KeyArgName] as? String,
                let valueObj = args[EmbracePlugin.ValueArgName] as? String {
                    let success = repository.addSpanAttribute(spanId: spanId, key: keyObj, value: valueObj)
                    result(NSNumber(value: success))
                } else {
                    result(NSNumber(value: false))
                }
        }
    }

    private func handleRecordCompletedSpanCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let name = args[EmbracePlugin.NameArgName] as? String,
                let startTimeMs = args[EmbracePlugin.StartTimeMsArgName] as? Int,
                let endTimeMs = args[EmbracePlugin.EndTimeMsArgName] as? Int {
                    let errorCode = args[EmbracePlugin.ErrorCodeArgName] as? String
                    let parentSpanId = args[EmbracePlugin.ParentSpanIdArgName] as? String
                    let attrs = args[EmbracePlugin.AttributesArgName] as? [String: String] ?? [:]
                    let events = args[EmbracePlugin.EventsArgName] as? Array<Dictionary<String, Any>> ?? []
                    let success = repository.recordCompletedSpan(name: name, startTimeMs: startTimeMs, endTimeMs: endTimeMs, errorCode: errorCode, parentSpanId: parentSpanId, attributes: attrs, events: events)
                    result(NSNumber(value: success))
                } else {
                    result(nil)
                }
        }
    }

    private func handleGenerateW3cTraceparentCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let traceId = args[EmbracePlugin.TraceIdArgName] as? String,
                let spanId = args[EmbracePlugin.SpanIdArgName] as? String {
                result(W3C.traceparent(traceId: traceId, spanId: spanId))
            } else {
                result(W3C.traceparent(traceId: TraceId.random().hexString, spanId: SpanId.random().hexString))
            }
        }
    }

    private func handleGetTraceIdCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        callAppleSdk { client in
            if let args = call.arguments as? [String: Any],
                let spanId = args[EmbracePlugin.SpanIdArgName] as? String,
                let span = repository.findSpan(id: spanId) {
                result(span.context.traceId.hexString)
            } else {
                result(nil)
            }
        }
    }

    private func callAppleSdk<T>(action: (Embrace) -> T) -> T? {
        guard let client = Embrace.client, client.state == .started else {
            return nil
        }
        return action(client)
    }
}
