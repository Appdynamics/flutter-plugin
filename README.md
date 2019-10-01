# appdynamics_mobilesdk

Flutter plugin to utilize the AppDynamics SDK.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/developing-packages/),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

### Config files

Currently appdynamics information needs to be setup in the example project for testing.  

#### Android configuration
For gradle to build the example app, under the example/android directory add local.properties with the following information

```
sdk.dir=/path/to/local/android/sdk
flutter.sdk=/path/to/local/flutter/sdk
flutter.buildMode=debug
appdynamics.accountname=EUM Accountname
appdynamics.licensekey=EUM License Key
```
For the example android app, an eum appkey is need. A config.propertiesfile needs to be added at example/android/app/src/main/assets/config.properties

```
APPDYNAMICS_EUM_KEY=**-***-**-***
```

#### IOS Configuration

Run pod install
