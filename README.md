# AppDynamics Flutter Plugin

Flutter plugin to utilize the AppDynamics SDK.  This plugin is a field integration and thus not an officially licensed AppDynamics product. This plugin wraps the AppDynanmics SDK and requires AppDynamics Mobile Licenses. Any issues with the plugin itself should be created on this repo.

## Quick Start

You can use the example app, which is part of this repository, to try out how your instrumentation might look like:

* Clone this repository: `git clone https://github.com/Appdynamics/flutter-plugin`
* Copy `android/app/src/main/assets/config.sample.properties` to `android/app/src/main/assets/config.properties` and set your application key for android.
* For iOS do the same with `ios/Runner/AppDynamics.sample.plist`.
* Run `flutter run` in the example folder to spin up the app on your emulator or devices.

## Installation

To instrument your flutter based mobile application with AppDynamics MRUM, add this to your package's pubspec.yaml file:

```yaml
dependencies:
  ...
  appdynamics_mobilesdk: ^1.0.0
```

Follow the additional steps below to add the AppDynamics agent to iOS and android platform.

### Android configuration

Follow the guide to [manually instrument an Android application](https://docs.appdynamics.com/display/PRO45/Instrument+an+Android+Application+Manually), i.e. add the class path of the AppDynamics Gradle Plugin to the build path dependencies clause in the file `app/build.gradle`:

```
buildscript {
    ...
    dependencies {
        classpath 'com.android.tools.build:gradle:3.0.1'
	      classpath 'com.appdynamics:appdynamics-gradle-plugin:20.+'
    }
}
...
```

And also active the plugin add the module-level build.gradle (`android/app/build.gradle`):

```
...
apply plugin: 'com.android.application'
apply plugin: 'adeum'
apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"
...
```

Next, verify that the required permissions in your `AndroidManifest.xml` are set:

```xml
<uses-permission android:name="android.permission.INTERNET"></uses-permission>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"></uses-permission>
```

Finally, modify the source of your `MainActivity.java` to start the instrumentation:

```java
...
import android.os.Bundle;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

import com.appdynamics.eumagent.runtime.Instrumentation;

public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    Instrumentation.start("<YOUR_APP_KEY>", getApplicationContext());
    GeneratedPluginRegistrant.registerWith(this);
  }
}
```

Replace `<YOUR_APP_KEY>` with the app key of your mobile application.

If you use AppDynamics OnPrem or SaaS and your controller is based in EMEA or APAC, [make sure to set the right collectorURL and screenshotURL](https://docs.appdynamics.com/display/latest/Instrument+an+Android+Application+Manually#InstrumentanAndroidApplicationManually-instrument-appInstrumenttheAndroidApplication)

Your android application is now instrumented and you should see data appear in the AppDynamics controller.

If necessary follow the official documentation to [customize the instrumentation](https://docs.appdynamics.com/display/latest/Customize+the+Android+Instrumentation).

Your android application is now instrumented and you should see data appear in the AppDynamics controller.

### IOS Configuration

Since this plugin will add the iOS SDK as dependency via it's podspec file, you can start with instrumenting your application.
Follow the [instructions on how to instrument an iOS application](https://docs.appdynamics.com/display/latest/Instrument+an+iOS+Application).
For example, if your application is ObjectiveC based, add the following code to the `ios/Runner/AppDelegate.m` file of your flutter project:

```objective-c
#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

#import <ADEUMInstrumentation/ADEUMInstrumentation.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  ADEumAgentConfiguration *config = [[ADEumAgentConfiguration alloc] initWithAppKey:@"<YOUR_APP_KEY>"];
  // Uncomment the following, to configure the iOS Agent to report the metrics and screenshots to the right EUM server
  // config.collectorURL = @"https://fra-col.eum-appdynamics.com";
  // config.screenshotURL = @"https://fra-image.eum-appdynamics.com/";
  // Uncomment the following to increase the log level of the agent
  // config.loggingLevel = ADEumLoggingLevelAll;
  [ADEumInstrumentation initWithConfiguration: config];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
```

Replace `<YOUR_APP_KEY>` with the app key of your mobile application.

If you use AppDynamics OnPrem or SaaS and your controller is based in EMEA or APAC, [make sure to set the right collectorURL and screenshotURL](https://docs.appdynamics.com/display/latest/Instrument+an+iOS+Application#InstrumentaniOSApplication-step3InitializetheAgent).

If necessary follow the official documentation to [customize the instrumentation](https://docs.appdynamics.com/display/latest/Customize+the+iOS+Instrumentation).

Your iOS application is now instrumented and you should see data appear in the AppDynamics controller.

# Usage

Out of the box the AppDynamics agent will deliver some information like session count, screenshots (iOS only), etc. To enrich your instrumentation you can leverage the API that comes with this plugin. This API tries to be as close as possible to the [iOS](https://docs.appdynamics.com/display/latest/Customize+the+iOS+Instrumentation) and [android](https://docs.appdynamics.com/display/latest/Customize+the+Android+Instrumentation) APIs:

## Collect Additional Types of Data

As with the iOS and android agent you can use additional methods to extend the insturmentation. To use those functionalities import the appdynamics_mobilesdk.dart:

```dart
import 'package:appdynamics_mobilesdk/appdynamics_mobilesdk.dart';
```

### Custom Timers

Start and end a custom timer at any place of your code.

```dart
AppdynamicsMobilesdk.startTimer('Timer Name');
...
AppdynamicsMobilesdk.stopTimer('Timer Name');
```

### User Data

Report user data, that will be attached to sessions and network requests. Use different methods depending on the type of the data:

```dart
AppdynamicsMobilesdk.setUserData("username", username);
AppdynamicsMobilesdk.setUserDataLong("counter", counter);
AppdynamicsMobilesdk.setUserDataDouble("cartValue", cartValue.toDouble());
AppdynamicsMobilesdk.setUserDataDate("loginTime", DateTime.now());
AppdynamicsMobilesdk.setUserDataBoolean("isRegistered", true);
```

## Report Errors and Exceptions

You can capture and send errors & exceptions to AppDynamics with the following:

```dart
Future<Null> main() async {
  FlutterError.onError = (FlutterErrorDetails details) async {
    Zone.current.handleUncaughtError(details.exception, details.stack);
  };
  runZoned<Future<Null>>(() async {
    runApp(new MyApp());
  }, onError: (error, stackTrace) async {
    await AppdynamicsMobilesdk.reportError(error, stackTrace);
  });
}
```

Note, that for iOS there will be only limited information (no stacktrace!)

## Start and End Session Frames

You can use the SessionFrame API to create session frames that will appear in the session activity:

```dart
AppdynamicsSessionFrame frame = await AppdynamicsMobilesdk.startSessionFrame('Checkout');
...
frame.updateName('Checkout (Failed)');
...
frame.end();
```

If your application uses route aware navigation you can add the class `AppdynamicsRouteObserver` to your widgets' `navigatorObservers`. For example, if you use `MaterialApp` (or `CupertinoApp` or any other `WidgetsApp`):

```dart
@override
Widget build(BuildContext context) {
  return MaterialApp(
    home: const MainPage(),
    title: 'My App',
    navigatorObservers: [AppdynamicsRouteObserver()]
  );
}
```

## Track Network Requests

To detect network requests, add a tracker to your requests and report them when the request is completed:

```dart
AppdynamicsHttpRequestTracker tracker = await AppdynamicsMobilesdk.startRequest(uri);
return get(uri).then((response) async {
  tracker.withResponseCode(response.statusCode);
  tracker.withResponseHeaderFields(response.headers);
  tracker.reportDone();
  return response;
});
```

If you use AppDynamics also in your backend application, you can add correlation headers:

```dart
AppdynamicsHttpRequestTracker tracker = await

Map<String, String> correlationHeaders = await AppdynamicsMobilesdk.getCorrelationHeaders();

AppdynamicsMobilesdk.startRequest(uri);
return get(uri, headers: correlationHeaders).then((response) async {
  tracker.withResponseCode(response.statusCode);
  tracker.withResponseHeaderFields(response.headers);
  tracker.reportDone();
  return response;
});
```

Note, that this example uses the dart [http](https://pub.dev/packages/http) package, but of course you can add this code to any other custom HTTP library.

For the dart http package mentioned above you can leverage the wrapper class `AppdynamicsHttpClient` to add the tracker to each request:

```dart
final client = AppdynamicsHttpClient(http.Client());
```

## Take Screenshots

If enabled as controller setting, you can take manual screenshots:

```dart
AppdynamicsMobilesdk.takeScreenshot();
```

Please note, that this only works for iOS and android will give you a black screen.
