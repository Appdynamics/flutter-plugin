#import <ADEUMInstrumentation/ADEumHTTPRequestTracker.h>
#import <ADEUMInstrumentation/ADEumSessionFrame.h>
#import <ADEUMInstrumentation/ADEumServerCorrelationHeaders.h>
#import <ADEUMInstrumentation/ADEumInstrumentation_interfaces.h>
#import "AppdynamicsMobilesdkPlugin.h"

typedef enum {
        TAKE_SCREENSHOT,
        START_REQUEST,
        REPORT_DONE,
        SET_USER_DATA,
        SET_USER_DATA_LONG,
        SET_USER_DATA_BOOLEAN,
        SET_USER_DATA_DOUBLE,
        SET_USER_DATA_DATE,
        LEAVE_BREADCRUMB,
        GET_CORRELATION_HEADERS,
        START_TIMER,
        STOP_TIMER,
        REPORT_ERROR,
        START_SESSION_FRAME,
        UPDATE_SESSION_FRAME,
        END_SESSION_FRAME,
        START_NEXT_SESSION,
        REPORT_METRIC
} InstrumentationMethod;

@implementation AppdynamicsMobilesdkPlugin

@synthesize trackers;
@synthesize sessionFrames;

- (id)init {
        self = [super init];

        if (self) {
                self.trackers = [[NSMutableDictionary alloc] init];
                self.sessionFrames = [[NSMutableDictionary alloc] init];
        }

        return self;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
        FlutterMethodChannel* channel = [FlutterMethodChannel
                                         methodChannelWithName:@"appdynamics_mobilesdk"
                                         binaryMessenger:[registrar messenger]];
        AppdynamicsMobilesdkPlugin* instance = [[AppdynamicsMobilesdkPlugin alloc] init];
        [registrar addMethodCallDelegate:instance channel:channel];
}

- (NSString*)startRequest:(NSString*)urlString {
        NSURL *url = [NSURL URLWithString:urlString];
        NSString *trackerId = [[NSUUID UUID] UUIDString];
        ADEumHTTPRequestTracker *tracker = [ADEumHTTPRequestTracker requestTrackerWithURL:url];
        [[self trackers] setObject:tracker forKey:trackerId];
        return trackerId;
}

- (NSString*)startSessionFrame:(NSString*)name {
        NSString *sessionId = [[NSUUID UUID] UUIDString];
        ADEumSessionFrame* sessionFrame = [ADEumInstrumentation startSessionFrame:name];
        [[self sessionFrames] setObject:sessionFrame forKey:sessionId];
        return sessionId;
}

- (void)updateSessionFrame:(NSString*)sessionId name:(NSString*)name {
        ADEumSessionFrame* sessionFrame = [[self sessionFrames] objectForKey:sessionId];
        [sessionFrame updateName:name];
}

- (void)endSessionFrame:(NSString*)sessionId {
        ADEumSessionFrame* sessionFrame = [[self sessionFrames] objectForKey:sessionId];
        [sessionFrame end];
        [[self sessionFrames] removeObjectForKey:sessionId];
}

- (void)leaveBreadcrumb:(NSString*)breadcrumb visibleInCrashesAndSessions:(bool)visibleInCrashesAndSessions {
        ADEumBreadcrumbVisibility mode = visibleInCrashesAndSessions ? ADEumBreadcrumbVisibilityCrashesAndSessions : ADEumBreadcrumbVisibilityCrashesOnly;
        [ADEumInstrumentation leaveBreadcrumb:breadcrumb mode:mode];
}

- (void)setUserDataDate:(NSString*)key value:(NSString*)value {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
        NSDate *date = [dateFormatter dateFromString:value];
        [ADEumInstrumentation setUserDataDate:key value:date];
}

- (void)reportError:(NSString*)errorString stackTrace:(NSString*)stackTrace {
        NSString* domain = @"com.errordomain";

        NSDictionary *userInfo = @{
                NSLocalizedDescriptionKey: errorString,
                NSUnderlyingErrorKey: stackTrace,
        };

        NSError* error = [NSError errorWithDomain:domain code:500 userInfo:userInfo];
        [ADEumInstrumentation reportError:error withSeverity: ADEumErrorSeverityLevelCritical andStackTrace:YES];
}

- (void)reportDone:(NSString*)trackerId responseCode:(int)responseCode responseHeaderFields:(NSDictionary *)responseHeaderFields {
        ADEumHTTPRequestTracker *tracker = [[self trackers] objectForKey:trackerId];

        if(responseCode > -1) {
                tracker.statusCode = [NSNumber numberWithInt:responseCode];
        }

        if(responseHeaderFields != nil) {
                tracker.allHeaderFields = responseHeaderFields;
        }

        [tracker reportDone];
        [[self trackers] removeObjectForKey:trackerId];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
        NSArray *items = @[
                @"takeScreenshot",
                @"startRequest",
                @"reportDone",
                @"setUserData",
                @"setUserDataLong",
                @"setUserDataBoolean",
                @"setUserDataDouble",
                @"setUserDataDate",
                @"leaveBreadcrumb",
                @"getCorrelationHeaders",
                @"startTimer",
                @"stopTimer",
                @"reportError",
                @"startSessionFrame",
                @"updateSessionFrame",
                @"endSessionFrame",
                @"startNextSession",
                @"reportMetric"
        ];
        int item = [items indexOfObject:call.method];

        switch (item) {
        case TAKE_SCREENSHOT:
                [ADEumInstrumentation takeScreenshot];
                result(@"success");
                break;
        case START_REQUEST:
                result([self startRequest: [[call arguments] objectForKey:@"url"]]);
                break;
        case REPORT_DONE:
                [self reportDone: [[call arguments] objectForKey:@"trackerId"] responseCode:[[[call arguments] objectForKey:@"responseCode"] intValue] responseHeaderFields:[[call arguments] objectForKey:@"responseHeaderFields"]];
                result(@"success");
                break;
        case SET_USER_DATA:
                [ADEumInstrumentation setUserData:[[call arguments] objectForKey:@"key"] value:[[call arguments] objectForKey:@"value"]];
                result(@"success");
                break;
        case SET_USER_DATA_LONG:
                [ADEumInstrumentation setUserDataLong:[[call arguments] objectForKey:@"key"] value:[[[call arguments] objectForKey:@"value"] longLongValue]];
                result(@"success");
                break;
        case SET_USER_DATA_BOOLEAN:
                [ADEumInstrumentation setUserDataBoolean:[[call arguments] objectForKey:@"key"] value:[[[call arguments] objectForKey:@"value"] boolValue]];
                result(@"success");
                break;
        case SET_USER_DATA_DOUBLE:
                [ADEumInstrumentation setUserDataDouble:[[call arguments] objectForKey:@"key"] value:[[[call arguments] objectForKey:@"value"] doubleValue]];
                result(@"success");
                break;
        case SET_USER_DATA_DATE:
                [self setUserDataDate: [[call arguments] objectForKey:@"key"] value:[[call arguments] objectForKey:@"value"]];
                result(@"success");
                break;
        case LEAVE_BREADCRUMB:
                [self leaveBreadcrumb: [[call arguments] objectForKey:@"breadcrumb"] visibleInCrashesAndSessions:[[[call arguments] objectForKey:@"visibleInCrashesAndSessions"] boolValue]];
                result(@"success");
                break;
        case GET_CORRELATION_HEADERS:
                result([ADEumServerCorrelationHeaders generate]);
                break;
        case START_TIMER:
                [ADEumInstrumentation startTimerWithName:[[call arguments] objectForKey:@"label"]];
                result(@"success");
                break;
        case STOP_TIMER:
                [ADEumInstrumentation stopTimerWithName:[[call arguments] objectForKey:@"label"]];
                result(@"success");
                break;
        case REPORT_ERROR:
                [self reportError: [[call arguments] objectForKey:@"error"] stackTrace:[[call arguments] objectForKey:@"stackTrace"]];
                result(@"success");
                break;
        case START_SESSION_FRAME:
                result([self startSessionFrame: [[call arguments] objectForKey:@"name"]]);
                break;
        case UPDATE_SESSION_FRAME:
                [self updateSessionFrame: [[call arguments] objectForKey:@"sessionId"] name:[[call arguments] objectForKey:@"name"]];
                result(@"success");
                break;
        case END_SESSION_FRAME:
                [self endSessionFrame: [[call arguments] objectForKey:@"sessionId"]];
                result(@"success");
                break;
        case START_NEXT_SESSION:
                [ADEumInstrumentation startNextSession];
                result(@"success");
                break;
        case REPORT_METRIC:
                [ADEumInstrumentation reportMetricWithName:[[call arguments] objectForKey:@"name"] value:[[[call arguments] objectForKey:@"value"] longLongValue]];
                result(@"success");
                break;
        default:
                result(FlutterMethodNotImplemented);
                break;
        }
}


@end
