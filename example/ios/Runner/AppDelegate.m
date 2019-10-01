#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <ADEUMInstrumentation/ADEumInstrumentation.h>

@implementation AppDelegate

- (void)initAppDynamicsAgent {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"AppDynamics" ofType:@"plist"];
    NSDictionary *settings = [[NSDictionary alloc] initWithContentsOfFile:path];
    ADEumAgentConfiguration *config = [[ADEumAgentConfiguration alloc] initWithAppKey: [settings valueForKey:@"AppKey"]];
    config.loggingLevel = ADEumLoggingLevelAll;
    [ADEumInstrumentation initWithConfiguration:config];
    // Override point for customization after application launch.
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    [self initAppDynamicsAgent];
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
