#import "AppDelegate.h"
#import <Embrace/Embrace.h>
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.

  [[Embrace sharedInstance] startWithLaunchOptions:launchOptions framework:EMBAppFrameworkFlutter];

  [[Embrace sharedInstance] endAppStartup];

  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
