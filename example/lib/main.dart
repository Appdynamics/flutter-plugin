import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart';
import 'package:flutter/services.dart';
import 'package:appdynamics_mobilesdk/appdynamics_mobilesdk.dart';

//void main() => runApp(MyApp());


bool get isInDebugMode {
  bool inDebugMode = false;
  assert(inDebugMode = false);
  return inDebugMode;
}

/// Reports [error] along with its [stackTrace] to Sentry.io.
Future<Null> _reportError(dynamic error, dynamic stackTrace) async {
  print('Caught error: $error');


  // Errors thrown in development mode are unlikely to be interesting. You can
  // check if you are running in dev mode using an assertion and omit sending
  // the report.
  /*
  if (isInDebugMode) {
    print(stackTrace);
    print('In dev mode. Not sending report to AppDynamics.');
    return;
  }*/

  print('Reporting to Appdynamics...');
  AppdynamicsMobilesdk.reportError(error, stackTrace);
/*
  final SentryResponse response = await _sentry.captureException(
    exception: error,
    stackTrace: stackTrace,
  );

  if (response.isSuccessful) {
    print('Success! Event ID: ${response.eventId}');
  } else {
    print('Failed to report to Sentry.io: ${response.error}');
  }*/
}

Future<Null> main() async {
  // This captures errors reported by the Flutter framework.
  FlutterError.onError = (FlutterErrorDetails details) async {
    if (isInDebugMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode report to the application zone to report to
      // Sentry.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  // This creates a [Zone] that contains the Flutter application and stablishes
  // an error handler that captures errors and reports them.
  //
  // Using a zone makes sure that as many errors as possible are captured,
  // including those thrown from [Timer]s, microtasks, I/O, and those forwarded
  // from the `FlutterError` handler.
  //
  // More about zones:
  //
  // - https://api.dartlang.org/stable/1.24.2/dart-async/Zone-class.html
  // - https://www.dartlang.org/articles/libraries/zones
  runZoned<Future<Null>>(() async {
    runApp(new MyApp());
  }, onError: (error, stackTrace) async {
    await _reportError(error, stackTrace);
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await AppdynamicsMobilesdk.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  _makeGetRequest() async {
    var uri = 'http://10.0.2.2:5000/do';

    // AppDynamics specific request
    AppdynamicsHttpRequestTracker tracker = await AppdynamicsMobilesdk.startRequest(uri);

    // Request goes out
    Response response = await get(uri);

    // AppDynamics end request
    tracker.withResponseCode(response.statusCode).reportDone();

    await AppdynamicsMobilesdk.takeScreenshot();

    await AppdynamicsMobilesdk.setUserData("foo", "bar");

    //await agent.invokeMethod('httprequest.end',{ "statusCode": response.statusCode});
    // sample info available in response
    int statusCode = response.statusCode;
    Map<String, String> headers = response.headers;
    String contentType = headers['content-type'];
    String json = response.body;
    print(json);
    // throw Exception("This is a crash!");

    // TODO convert json to object...

  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _makeGetRequest,
          tooltip: 'Make Http Request',
          child: Icon(Icons.add),
        ),

      ),
    );
  }
}
