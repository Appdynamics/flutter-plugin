#import <ADEUMInstrumentation/ADEumHTTPRequestTracker.h>
#import <ADEUMInstrumentation/ADEumInstrumentation_interfaces.h>
#import "AppdynamicsMobilesdkPlugin.h"

typedef enum {
    TAKE_SCREENSHOT,
    START_REQUEST,
    REPORT_DONE,
    SET_USER_DATA,
    SET_USER_DATA_LONG,
    SET_USER_DATA_DOUBLE,
    SET_USER_DATA_DATE,
    LEAVE_BREADCRUMB
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

- (void)reportDone:(NSString*)trackerId {
    ADEumHTTPRequestTracker *tracker = [[self trackers] objectForKey:trackerId];
    tracker.statusCode = [NSNumber numberWithInt:200];

    [tracker reportDone];
    [[self trackers] removeObjectForKey:trackerId];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
        NSArray *items = @[@"takeScreenshot", @"startRequest", @"reportDone", @"setUserData", @"setUserDataLong", @"setUserDataDouble", @"setUserDataDate", @"leaveBreadcrumb"];
        int item = [items indexOfObject:call.method];

        switch (item) {
        case TAKE_SCREENSHOT:
                [ADEumInstrumentation takeScreenshot];
                break;
        case START_REQUEST:
                result([self startRequest: [[call arguments] objectForKey:@"url"]]);
                break;
        case REPORT_DONE:
                [self reportDone: [[call arguments] objectForKey:@"trackerId"]];
                break;
        case SET_USER_DATA:
                [ADEumInstrumentation setUserData:[[call arguments] objectForKey:@"key"] value:[[call arguments] objectForKey:@"value"]];
                break;
        case SET_USER_DATA_LONG:
                [ADEumInstrumentation setUserDataLong:[[call arguments] objectForKey:@"key"] value:[[[call arguments] objectForKey:@"value"] intValue]];
                break;
        case LEAVE_BREADCRUMB:
                [self leaveBreadcrumb: [[call arguments] objectForKey:@"breadcrumb"] visibleInCrashesAndSessions:[[[call arguments] objectForKey:@"visibleInCrashesAndSessions"] boolValue]];
                break;
        default:
                break;
        }
}


@end
