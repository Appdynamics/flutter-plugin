#import <ADEUMInstrumentation/ADEumHTTPRequestTracker.h>
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
        REPORT_ERROR
} InstrumentationMethod;

@implementation AppdynamicsMobilesdkPlugin

@synthesize trackers;

- (id)init {
        self = [super init];

        if (self) {
                self.trackers = [[NSMutableDictionary alloc] init];
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

- (void)reportError:(NSString*)errorString {
        NSString* domain = @"com.errordomain";
        NSString* reason = errorString;
        NSError* error = [NSError errorWithDomain:domain code:500 userInfo:@{@"Error reason": reason}];
        NSLog(@"%@",error);
        [ADEumInstrumentation reportError:error withSeverity: ADEumErrorSeverityLevelCritical];
}

- (void)reportDone:(NSString*)trackerId responseCode:(int)responseCode {
        ADEumHTTPRequestTracker *tracker = [[self trackers] objectForKey:trackerId];

        if(responseCode > -1) {
                NSLog(@"Setting response code");
                tracker.statusCode = [NSNumber numberWithInt:responseCode];
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
                @"reportError"
        ];
        int item = [items indexOfObject:call.method];

        switch (item) {
        case TAKE_SCREENSHOT:
                [ADEumInstrumentation takeScreenshot];
                break;
        case START_REQUEST:
                result([self startRequest: [[call arguments] objectForKey:@"url"]]);
                break;
        case REPORT_DONE:
                [self reportDone: [[call arguments] objectForKey:@"trackerId"] responseCode:[[[call arguments] objectForKey:@"responseCode"] intValue]];
                break;
        case SET_USER_DATA:
                [ADEumInstrumentation setUserData:[[call arguments] objectForKey:@"key"] value:[[call arguments] objectForKey:@"value"]];
                break;
        case SET_USER_DATA_LONG:
                [ADEumInstrumentation setUserDataLong:[[call arguments] objectForKey:@"key"] value:[[[call arguments] objectForKey:@"value"] longLongValue]];
                break;
        case SET_USER_DATA_BOOLEAN:
                [ADEumInstrumentation setUserDataLong:[[call arguments] objectForKey:@"key"] value:[[[call arguments] objectForKey:@"value"] boolValue]];
                break;
        case SET_USER_DATA_DOUBLE:
                [ADEumInstrumentation setUserDataLong:[[call arguments] objectForKey:@"key"] value:[[[call arguments] objectForKey:@"value"] doubleValue]];
                break;
        case SET_USER_DATA_DATE:
                [self setUserDataDate: [[call arguments] objectForKey:@"key"] value:[[call arguments] objectForKey:@"value"]];
                break;
        case LEAVE_BREADCRUMB:
                [self leaveBreadcrumb: [[call arguments] objectForKey:@"breadcrumb"] visibleInCrashesAndSessions:[[[call arguments] objectForKey:@"visibleInCrashesAndSessions"] boolValue]];
                break;
        case GET_CORRELATION_HEADERS:
                result([ADEumServerCorrelationHeaders generate]);
                break;
        case START_TIMER:
                [ADEumInstrumentation startTimerWithName:[[call arguments] objectForKey:@"label"]];
                break;
        case STOP_TIMER:
                [ADEumInstrumentation stopTimerWithName:[[call arguments] objectForKey:@"label"]];
                break;
        case REPORT_ERROR:
                [self reportError: [[call arguments] objectForKey:@"error"]];
                break;
        default:
                break;
        }
}


@end
