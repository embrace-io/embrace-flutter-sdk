#import "EmbracePlugin.h"
#import <Embrace/Embrace.h>

@implementation EmbracePlugin

static NSString *const MethodChannelId = @"embrace";

// Method Names
static NSString *const AttachSdkMethodName = @"attachToHostSdk";
static NSString *const EndStartupMomentMethodName = @"endStartupMoment";
static NSString *const AddBreadcrumbMethodName = @"addBreadcrumb";
static NSString *const LogPushNotificationMethodName = @"logPushNotification";
static NSString *const LogInfoMethodName = @"logInfo";
static NSString *const LogWarningMethodName = @"logWarning";
static NSString *const LogErrorMethodName = @"logError";
static NSString *const StartViewMethodName = @"startView";
static NSString *const EndViewMethodName = @"endView";
static NSString *const StartMomentMethodName = @"startMoment";
static NSString *const EndMomentMethodName = @"endMoment";
static NSString *const GetDeviceIdMethodName = @"getDeviceId";
static NSString *const TriggerNativeErrorMethodName = @"triggerNativeSdkError";
static NSString *const TriggerSignalMethodName = @"triggerRaisedSignal";
static NSString *const TriggerChannelErrorMethodName = @"triggerMethodChannelError";
static NSString *const SetUserIdentifierMethodName = @"setUserIdentifier";
static NSString *const SetUserNameMethodName = @"setUserName";
static NSString *const SetUserEmailMethodName = @"setUserEmail";
static NSString *const SetUserAsPayerMethodName = @"setUserAsPayer";
static NSString *const AddUserPersonaMethodName = @"addUserPersona";
static NSString *const ClearUserIdentifierMethodName = @"clearUserIdentifier";
static NSString *const ClearUserNameMethodName = @"clearUserName";
static NSString *const ClearUserEmailMethodName = @"clearUserEmail";
static NSString *const ClearUserAsPayerMethodName = @"clearUserAsPayer";
static NSString *const ClearUserPersonaMethodName = @"clearUserPersona";
static NSString *const ClearAllUserPersonasMethodName = @"clearAllUserPersonas";
static NSString *const LogNetworkRequestMethodName = @"logNetworkRequest";
static NSString *const LogInternalErrorMethodName = @"logInternalError";
static NSString *const LogDartErrorMethodName = @"logDartError";
static NSString *const AddSessionPropertyMethodName = @"addSessionProperty";
static NSString *const RemoveSessionPropertyMethodName = @"removeSessionProperty";
static NSString *const GetSessionPropertiesMethodName = @"getSessionProperties";
static NSString *const EndSessionMethodName = @"endSession";
static NSString *const GetLastRunEndStateMethodName = @"getLastRunEndState";
static NSString *const GetCurrentSessionIdMethodName = @"getCurrentSessionId";
static NSString *const GetSdkVersionMethodName = @"getSdkVersion";

// Parameter Names
static NSString *const PropertiesArgName = @"properties";
static NSString *const NameArgName = @"name";
static NSString *const MessageArgName = @"message";
static NSString *const IdentifierArgName = @"identifier";
static NSString *const UserIdentifierArgName = @"identifier";
static NSString *const UserNameArgName = @"name";
static NSString *const UserEmailArgName = @"email";
static NSString *const UserPersonaArgName = @"persona";
static NSString *const UrlArgName = @"url";
static NSString *const HttpMethodArgName = @"httpMethod";
static NSString *const StartTimeArgName = @"startTime";
static NSString *const EndTimeArgName = @"endTime";
static NSString *const BytesSentArgName = @"bytesSent";
static NSString *const BytesReceivedArgName = @"bytesReceived";
static NSString *const StatusCodeArgName = @"statusCode";
static NSString *const ErrorArgName = @"error";
static NSString *const TraceIdArgName = @"traceId";
static NSString *const DetailsArgName = @"details";
static NSString *const EmbraceFlutterSdkVersionArgName = @"embraceFlutterSdkVersion";
static NSString *const DartRuntimeVersionArgName = @"dartRuntimeVersion";
static NSString *const ErrorStackArgName = @"stack";
static NSString *const ErrorMessageArgName = @"message";
static NSString *const ErrorContextArgName = @"context";
static NSString *const ErrorLibraryArgName = @"library";
static NSString *const ErrorTypeArgName = @"type";
static NSString *const ErrorWasHandledArgName = @"wasHandled";
static NSString *const KeyArgName = @"key";
static NSString *const ValueArgName = @"value";
static NSString *const PermanentArgName = @"permanent";
static NSString *const ClearUserInfoArgName = @"clearUserInfo";
static NSString *const TitleArgName = @"title";
static NSString *const BodyArgName = @"body";
static NSString *const SubtitleArgName = @"subtitle";
static NSString *const BadgeArgName = @"badge";
static NSString *const CategoryArgName = @"category";

static NSString *const NetworkErrorUserInfoKey = @"userinfo";

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                     methodChannelWithName:MethodChannelId
                                     binaryMessenger:[registrar messenger]];
    EmbracePlugin* instance = [[EmbracePlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
}

+ (NSString*)getOptionalNSString:(NSDictionary*)dictionary forKey:(NSString*)key {
    return [self getOptionalNSString:dictionary forKey:key withDefault:nil];
}

+ (NSString*)getOptionalNSString:(NSDictionary*)dictionary forKey:(NSString*)key withDefault:(NSString*)defaultValue {
    NSString* result = dictionary[key];
    if ([result isEqual:[NSNull null]])
    {
        return defaultValue;
    }
    return result;
}

+ (NSDictionary*)getOptionalNSDictionary:(NSDictionary*)dictionary forKey:(NSString*)key {
    NSDictionary* result = dictionary[key];
    if ([result isEqual:[NSNull null]])
    {
        return nil;
    }
    return result;
}

+ (NSNumber*)getOptionalNSNumber:(NSDictionary*)dictionary forKey:(NSString*)key {
    NSNumber* result = dictionary[key];
    if ([result isEqual:[NSNull null]])
    {
        result = [NSNumber numberWithInt:0];
    }
    return result;
}

+ (BOOL)getOptionalBool:(NSDictionary*)dictionary forKey:(NSString*)key withDefaultValue:(BOOL)defaultValue {
    NSNumber* result = dictionary[key];
    if ([result isEqual:[NSNull null]])
    {
        return defaultValue;
    }
    return [result boolValue];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([AttachSdkMethodName isEqualToString:call.method]) {
        [self handleAttachSdkCall:call withResult:result];
    } else if ([EndStartupMomentMethodName isEqualToString: call.method]) {
        [self handleEndStartupMomentCall: call withResult: result];
    } else if ([AddBreadcrumbMethodName isEqualToString: call.method]) {
        [self handleAddBreadcrumbCall: call withResult: result];
    } else if ([LogPushNotificationMethodName isEqualToString: call.method]) {
        [self handleLogPushNotificationCall: call withResult: result];
    } else if ([LogInfoMethodName isEqualToString: call.method]) {
        [self handleLogInfoCall: call withResult: result];
    } else if ([LogWarningMethodName isEqualToString: call.method]) {
        [self handleLogWarningCall: call withResult: result];
    } else if ([LogErrorMethodName isEqualToString: call.method]) {
        [self handleLogErrorCall: call withResult: result];
    } else if ([LogNetworkRequestMethodName isEqualToString: call.method]) {
        [self handleLogNetworkRequestCall: call withResult: result];
    } else if ([StartViewMethodName isEqualToString: call.method]) {
        [self handleStartViewCall: call withResult: result];
    } else if ([EndViewMethodName isEqualToString: call.method]) {
        [self handleEndViewCall: call withResult: result];
    } else if ([StartMomentMethodName isEqualToString: call.method]) {
        [self handleStartMomentCall: call withResult: result];
    } else if ([EndMomentMethodName isEqualToString:call.method]) {
        [self handleEndMomentCall: call withResult: result];
    } else if ([GetDeviceIdMethodName isEqualToString: call.method]) {
        [self handleGetDeviceIdCall: call withResult: result];
    } else if ([TriggerNativeErrorMethodName isEqualToString: call.method]) {
        [self handleNativeError: call withResult: result];
    } else if ([TriggerSignalMethodName isEqualToString: call.method]) {
        [self handleTriggerSignal: call withResult: result];
    } else if ([TriggerChannelErrorMethodName isEqualToString: call.method]) {
        [self handleTriggerChannelError: call withResult: result];
    } else if ([SetUserIdentifierMethodName isEqualToString: call.method]) {
        [self handleSetUserIdentifierCall: call withResult: result];
    } else if ([ClearUserIdentifierMethodName isEqualToString: call.method]) {
        [self handleClearUserIdentifierCall: call withResult: result];
    } else if ([SetUserNameMethodName isEqualToString: call.method]) {
        [self handleSetUserNameCall: call withResult: result];
    } else if ([ClearUserNameMethodName isEqualToString: call.method]) {
        [self handleClearUserNameCall: call withResult: result];
    } else if ([SetUserEmailMethodName isEqualToString: call.method]) {
        [self handleSetUserEmailCall: call withResult: result];
    } else if ([ClearUserEmailMethodName isEqualToString: call.method]) {
        [self handleClearUserEmailCall: call withResult: result];
    } else if ([SetUserAsPayerMethodName isEqualToString: call.method]) {
        [self handleSetUserAsPayerCall: call withResult: result];
    } else if ([ClearUserAsPayerMethodName isEqualToString: call.method]) {
        [self handleClearUserAsPayerCall: call withResult: result];
    } else if ([AddUserPersonaMethodName isEqualToString: call.method]) {
        [self handleAddUserPersonaCall: call withResult: result];
    } else if ([ClearUserPersonaMethodName isEqualToString: call.method]) {
        [self handleClearUserPersonaCall: call withResult: result];
    } else if ([ClearAllUserPersonasMethodName isEqualToString: call.method]) {
        [self handleClearAllUserPersonasCall: call withResult: result];
    } else if ([AddSessionPropertyMethodName isEqualToString: call.method]) {
        [self handleAddSessionPropertyCall: call withResult: result];
    } else if ([RemoveSessionPropertyMethodName isEqualToString: call.method]) {
        [self handleRemoveSessionPropertyCall: call withResult: result];
    } else if ([GetSessionPropertiesMethodName isEqualToString: call.method]) {
        [self handleGetSessionPropertiesCall: call withResult: result];
    } else if ([EndSessionMethodName isEqualToString: call.method]) {
        [self handleEndSessionCall: call withResult: result];
    } else if ([LogInternalErrorMethodName isEqualToString: call.method]) {
        [self handleLogInternalErrorCall: call withResult: result];
    } else if ([LogDartErrorMethodName isEqualToString: call.method]) {
        [self handleLogDartErrorCall: call withResult: result];
    } else if ([GetLastRunEndStateMethodName isEqualToString: call.method]) {
        [self handleGetLastRunEndStateCall: call withResult: result];
    } else if ([GetCurrentSessionIdMethodName isEqualToString: call.method]) {
        [self handleGetCurrentSessionIdCall: call withResult: result];
    } else if ([GetSdkVersionMethodName isEqualToString: call.method]) {
        [self handleGetSdkVersionCall: call withResult: result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)handleAttachSdkCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    BOOL started = [[Embrace sharedInstance] isStarted];

    if (!started) { // fallback to starting the SDK here, but log a warning.
        [[Embrace sharedInstance] startWithLaunchOptions:@{} framework:EMBAppFrameworkFlutter];
    }

    NSString* embraceFlutterSdkVersion = [EmbracePlugin getOptionalNSString: call.arguments forKey: EmbraceFlutterSdkVersionArgName];
    [[EMBFlutterEmbrace sharedInstance] setEmbraceFlutterSDKVersion:embraceFlutterSdkVersion];
    NSString* dartRuntimeVersion = [EmbracePlugin getOptionalNSString: call.arguments forKey: DartRuntimeVersionArgName];
    [[EMBFlutterEmbrace sharedInstance] setDartVersion:dartRuntimeVersion];
    
    // 'attach' to the iOS SDK at this point by requesting any information
    // required by Flutter, and passing any Flutter-specific data down to the
    // iOS SDK.
    result([NSNumber numberWithBool:started]);
}

- (void)handleEndStartupMomentCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSDictionary* properties = [EmbracePlugin getOptionalNSDictionary:call.arguments forKey:PropertiesArgName];
    [[Embrace sharedInstance] endAppStartupWithProperties: properties];
    result(nil);
}

- (void)handleAddBreadcrumbCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    [[Embrace sharedInstance] logBreadcrumbWithMessage: call.arguments[MessageArgName]];
    result(nil);
}

- (void)handleLogPushNotificationCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* title = [EmbracePlugin getOptionalNSString:call.arguments forKey:TitleArgName];
    NSString* body = [EmbracePlugin getOptionalNSString:call.arguments forKey:BodyArgName];
    NSString* subtitle = [EmbracePlugin getOptionalNSString:call.arguments forKey:SubtitleArgName];
    NSNumber* badge = [EmbracePlugin getOptionalNSNumber:call.arguments forKey:BadgeArgName];
    NSString* category = [EmbracePlugin getOptionalNSString:call.arguments forKey:CategoryArgName];
    
    NSMutableDictionary *alertData = [NSMutableDictionary dictionary];
    alertData[@"title"] = title;
    alertData[@"subtitle"] = subtitle;
    alertData[@"body"] = body;
    
    NSMutableDictionary *apsData = [NSMutableDictionary dictionary];
    apsData[@"alert"] = alertData;
    apsData[@"badge"] = badge;
    apsData[@"category"] = category;
    NSDictionary *pushData = @{
        @"aps": apsData
    };
    [[Embrace sharedInstance] applicationDidReceiveNotification:pushData];
     
    result(nil);
}

- (void)handleLogInfoCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* message = [EmbracePlugin getOptionalNSString: call.arguments forKey: MessageArgName];
    NSDictionary* properties = [EmbracePlugin getOptionalNSDictionary: call.arguments forKey: PropertiesArgName];
    
    [[Embrace sharedInstance] logMessage: message withSeverity: EMBSeverityInfo properties: properties];
}

- (void)handleLogWarningCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* message = [EmbracePlugin getOptionalNSString:call.arguments forKey:MessageArgName];
    NSDictionary* properties = [EmbracePlugin getOptionalNSDictionary: call.arguments forKey: PropertiesArgName];
    
    [[Embrace sharedInstance] logMessage: message withSeverity: EMBSeverityWarning properties: properties];
}

- (void)handleLogErrorCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* message = [EmbracePlugin getOptionalNSString:call.arguments forKey:MessageArgName];
    NSDictionary* properties = [EmbracePlugin getOptionalNSDictionary: call.arguments forKey: PropertiesArgName];
    
    [[Embrace sharedInstance] logMessage: message withSeverity: EMBSeverityError properties: properties];
}

- (void)handleLogNetworkRequestCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* url = [EmbracePlugin getOptionalNSString: call.arguments forKey: UrlArgName];
    NSString* method = [EmbracePlugin getOptionalNSString: call.arguments forKey: HttpMethodArgName];
    NSNumber* statusCode = [EmbracePlugin getOptionalNSNumber: call.arguments forKey: StatusCodeArgName];
    NSNumber* startTime = [EmbracePlugin getOptionalNSNumber: call.arguments forKey: StartTimeArgName];
    NSNumber* endTime = [EmbracePlugin getOptionalNSNumber: call.arguments forKey: EndTimeArgName];
    NSNumber* bytesSent = [EmbracePlugin getOptionalNSNumber: call.arguments forKey: BytesSentArgName];
    NSNumber* bytesReceived = [EmbracePlugin getOptionalNSNumber: call.arguments forKey: BytesReceivedArgName];
    NSString* error = [EmbracePlugin getOptionalNSString: call.arguments forKey: ErrorArgName];
    NSString* traceId = [EmbracePlugin getOptionalNSString: call.arguments forKey: TraceIdArgName];
    
    // Start/end times are passed in ms, but the iOS SDK is expecting seconds
    NSTimeInterval startTimeInSeconds = [startTime longValue] / 1000;
    NSTimeInterval endTimeInSeconds = [endTime longValue] / 1000;

    NSURL* urlObj = [NSURL URLWithString: url];
    NSDate* startDate = [NSDate dateWithTimeIntervalSince1970: startTimeInSeconds];
    NSDate* endDate = [NSDate dateWithTimeIntervalSince1970: endTimeInSeconds];
    NSError* errorObj = nil;
    if (error != nil) {
        errorObj = [NSError errorWithDomain:NSURLErrorDomain code: [statusCode intValue] userInfo:@{NetworkErrorUserInfoKey: error}];
    }

    EMBNetworkRequest* request = [EMBNetworkRequest networkRequestWithURL: urlObj method: method startTime: startDate endTime: endDate bytesIn: [bytesSent intValue] bytesOut: [bytesReceived intValue] responseCode: [statusCode intValue] error: errorObj traceId: traceId];
    [[Embrace sharedInstance] logNetworkRequest: request];
}

- (void)handleStartViewCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    [[Embrace sharedInstance] startViewWithName:call.arguments[NameArgName]];
    result(nil);
}

- (void)handleEndViewCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    [[Embrace sharedInstance] endViewWithName: call.arguments[NameArgName]];
    result(nil);
}

- (void)handleStartMomentCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* name = call.arguments[NameArgName];
    NSString* identifier = [EmbracePlugin getOptionalNSString:call.arguments forKey:IdentifierArgName];
    NSDictionary* properties = [EmbracePlugin getOptionalNSDictionary: call.arguments forKey:PropertiesArgName];
    
    [[Embrace sharedInstance] startMomentWithName: name
                                       identifier: identifier
                                       properties: properties];
    result(nil);
}

- (void)handleEndMomentCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* identifier = [EmbracePlugin getOptionalNSString:call.arguments forKey:IdentifierArgName];
    NSDictionary* properties = [EmbracePlugin getOptionalNSDictionary: call.arguments forKey:PropertiesArgName];
    [[Embrace sharedInstance] endMomentWithName: call.arguments[NameArgName]
                                     identifier: identifier
                                     properties: properties];
    result(nil);
}

- (void)handleGetDeviceIdCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* deviceId = [[Embrace sharedInstance] getDeviceId];
    result(deviceId);
}

- (void)handleSetUserIdentifierCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* identifier = [EmbracePlugin getOptionalNSString:call.arguments forKey:UserIdentifierArgName];
    [[Embrace sharedInstance] setUserIdentifier:identifier];
    result(nil);
}

- (void)handleClearUserIdentifierCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    [[Embrace sharedInstance] clearUserIdentifier];
    result(nil);
}

- (void)handleSetUserNameCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* name = [EmbracePlugin getOptionalNSString:call.arguments forKey:UserNameArgName];
    [[Embrace sharedInstance] setUsername:name];
    result(nil);
}

- (void)handleClearUserNameCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    [[Embrace sharedInstance] clearUsername];
    result(nil);
}

- (void)handleSetUserEmailCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* email = [EmbracePlugin getOptionalNSString:call.arguments forKey:UserEmailArgName];
    [[Embrace sharedInstance] setUserEmail:email];
    result(nil);
}

- (void)handleClearUserEmailCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    [[Embrace sharedInstance] clearUserEmail];
    result(nil);
}

- (void)handleSetUserAsPayerCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    [[Embrace sharedInstance] setUserAsPayer];
    result(nil);
}

- (void)handleClearUserAsPayerCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    [[Embrace sharedInstance] clearUserAsPayer];
    result(nil);
}

- (void)handleAddUserPersonaCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* persona = [EmbracePlugin getOptionalNSString:call.arguments forKey:UserPersonaArgName];
    [[Embrace sharedInstance] setUserPersona:persona];
    result(nil);
}

- (void)handleClearUserPersonaCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* persona = [EmbracePlugin getOptionalNSString:call.arguments forKey:UserPersonaArgName];
    [[Embrace sharedInstance] clearUserPersona:persona];
    result(nil);
}

- (void)handleClearAllUserPersonasCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    [[Embrace sharedInstance] clearAllUserPersonas];
    result(nil);
}

- (void)handleAddSessionPropertyCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* key = [EmbracePlugin getOptionalNSString:call.arguments forKey:KeyArgName];
    NSString* value = [EmbracePlugin getOptionalNSString:call.arguments forKey:ValueArgName];
    BOOL permanent = [EmbracePlugin getOptionalBool:call.arguments forKey:PermanentArgName withDefaultValue:false];
    
    [[Embrace sharedInstance] addSessionProperty:value withKey:key permanent:permanent];
    result(nil);
}

- (void)handleRemoveSessionPropertyCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* key = [EmbracePlugin getOptionalNSString:call.arguments forKey:KeyArgName];
    
    [[Embrace sharedInstance] removeSessionPropertyWithKey:key];
    result(nil);
}

- (void)handleGetSessionPropertiesCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSDictionary* properties = [[Embrace sharedInstance] getSessionProperties];
    result(properties);
}

- (void)handleEndSessionCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    BOOL clearUserInfo = [EmbracePlugin getOptionalBool:call.arguments forKey:ClearUserInfoArgName withDefaultValue:true];
    
    [[Embrace sharedInstance] endSession:clearUserInfo];
    result(nil);
}

- (void)handleLogInternalErrorCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* message = [EmbracePlugin getOptionalNSString:call.arguments forKey:MessageArgName];
    NSString* details = [EmbracePlugin getOptionalNSString:call.arguments forKey:DetailsArgName];

    // TODO: future pass information to host SDK once EMB-8577 is implemented.
    result(nil);
}

- (void)handleLogDartErrorCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* stack = [EmbracePlugin getOptionalNSString:call.arguments forKey:ErrorStackArgName];
    NSString* message = [EmbracePlugin getOptionalNSString:call.arguments forKey:ErrorMessageArgName];
    NSString* context = [EmbracePlugin getOptionalNSString:call.arguments forKey:ErrorContextArgName];
    NSString* library = [EmbracePlugin getOptionalNSString:call.arguments forKey:ErrorLibraryArgName];
    NSString* type = [EmbracePlugin getOptionalNSString:call.arguments forKey:ErrorTypeArgName];
    BOOL wasHandled = [EmbracePlugin getOptionalBool:call.arguments forKey:ErrorWasHandledArgName withDefaultValue:false];

    if (wasHandled) {
        [[EMBFlutterEmbrace sharedInstance] logHandledExceptionWithName:type
                                                                message:message
                                                             stackTrace:stack
                                                                context:context
                                                                library:library];
    } else {
        [[EMBFlutterEmbrace sharedInstance] logUnhandledExceptionWithName:type
                                                                  message:message
                                                               stackTrace:stack
                                                                  context:context
                                                                  library:library];
    }
    
    result(nil);
}

- (void)handleGetLastRunEndStateCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    EMBLastRunEndState lastState = [[Embrace sharedInstance] lastRunEndState];
    result([NSNumber numberWithInteger:lastState]);
}

- (void)handleGetCurrentSessionIdCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    NSString* sessionId = [[Embrace sharedInstance] getCurrentSessionId];
    result(sessionId);
}

- (void)handleGetSdkVersionCall:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    // There is currently no way to get the version of the iOS SDK at runtime, it
    // will be implmented in EMB-13383.
    result(nil);
}

- (void)handleNativeError:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    @throw [NSException
            exceptionWithName:NSInvalidArgumentException
            reason:@"Embrace sample: throwing NSError"
            userInfo:nil];
    result(nil);
}

- (void)handleTriggerSignal:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    asm(".byte 0x0f, 0x0b");
    result(nil);
}

- (void)handleTriggerChannelError:(FlutterMethodCall*)call withResult:(FlutterResult)result {
    @throw [NSException
            exceptionWithName:NSInvalidArgumentException
            reason:@"Embrace sample: throwing NSError"
            userInfo:nil];
    result(nil);
}

@end
