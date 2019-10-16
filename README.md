# appdynamics_mobilesdk

Flutter plugin to utilize the AppDynamics SDK.

## Getting Started

To instrument your flutter based mobile application with AppDynamics MRUM, download the latest version via git:

```shell
git clone https://github.com/Appdynamics/flutter-plugin
```

Next add it as path-based dependency to your `pubspec.yml`:

```yaml
dependencies:
  ...
  appdynamics_mobilesdk:
    path: /path/to/flutter-plugin
```

Afterwards follow the additional steps to add the android and iOS agent to both platforms.

### Android configuration

Follow the guide to [manually instrument an Android application](https://docs.appdynamics.com/display/PRO45/Instrument+an+Android+Application+Manually), i.e. add the class path of the AppDynamics Gradle Plugin to the build path dependencies clause in the file `app/build.gradle`:

```
buildscript {
    ...
    dependencies {
        classpath 'com.android.tools.build:gradle:3.0.1'
	      classpath 'com.appdynamics:appdynamics-gradle-plugin:5.+'
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

```
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

If you use AppDynamics OnPrem or SaaS and your controller is based in EMEA or APAC, [make sure to set the right collectorURL and screenshotURL](https://docs.appdynamics.com/display/PRO45/Instrument+an+Android+Application+Manually#InstrumentanAndroidApplicationManually-instrument-appInstrumenttheAndroidApplication)

Your android application is now instrumented and you should see data appear in the AppDynamics controller.

If necessary follow the official documentation to [customize the instrumentation](https://docs.appdynamics.com/display/PRO45/Customize+the+Android+Instrumentation).

Your android application is now instrumented and you should see data appear in the AppDynamics controller.

### IOS Configuration

Add the following code to the `ios/Runner/AppDelegate.m` file:

```objective-c
#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

#import <ADEUMInstrumentation/ADEUMInstrumentation.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [ADEumInstrumentation initWithKey: @"<YOUR_APP_KEY>"];
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
```

Replace `<YOUR_APP_KEY>` with the app key of your mobile application.

This is like you would instrument any other iOS application. If you use AppDynamics OnPrem or SaaS and your controller is based in EMEA or APAC, [make sure to set the right collectorURL and screenshotURL](https://docs.appdynamics.com/display/PRO45/Instrument+an+iOS+Application#InstrumentaniOSApplication-step3InitializetheAgent).

If necessary follow the official documentation to [customize the instrumentation](https://docs.appdynamics.com/display/PRO45/Customize+the+iOS+Instrumentation).

Your iOS application is now instrumented and you should see data appear in the AppDynamics controller.
