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
  print(stackTrace);
  print('Reporting to Appdynamics...');
  // AppdynamicsMobilesdk.reportError(error, stackTrace);
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
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion = "unknown";

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      print(_counter);
      _platformVersion = platformVersion;
      _counter++;
    });
  }

  _buttonPressed() async {
    await Future.wait([
      _makeGetRequest('https://raw.githubusercontent.com/bahamas10/css-color-names/master/css-color-names.json'),
      _makeGetRequest('https://raw.githubusercontent.com/bahamas10/css-color-names/master/css-color-names.json', 404)
    ]);

    AppdynamicsMobilesdk.setUserDataLong("counter_long", _counter);
    AppdynamicsMobilesdk.setUserDataDouble("cartValue", _counter.toDouble());
    AppdynamicsMobilesdk.setUserDataDate("myDate", DateTime.now());

    setState(() {
      print(_counter);
      _counter++;
    });
  }

  Future<Response> _makeGetRequest(uri, [responseCode = -1]) async {
    print('GET $uri');
    // AppDynamics specific request
    AppdynamicsHttpRequestTracker tracker = await AppdynamicsMobilesdk.startRequest(uri);
    Map<String, String> correlationHeaders = await AppdynamicsMobilesdk.getCorrelationHeaders(false);

    print(correlationHeaders);
    print(uri + "start");

    // Request goes out
    return get(uri, headers: correlationHeaders).then((response) async {

      if(responseCode <= 0) {
        responseCode = response.statusCode;
      }

      tracker.withResponseCode(responseCode).withResponseHeaderFields(response.headers);

      if(responseCode > 500) {
        tracker.withError('An error!!!');
      }

      tracker.reportDone();
      print(uri + "end");
      /*int statusCode = response.statusCode;
      Map<String, String> headers = response.headers;
      String contentType = headers['content-type'];
      String json = response.body;
      print(uri + "end");
      print("HERE COMES SOME DATA");
      print(json);
      print(headers);*/
      return response;
    });
    /*// AppDynamics specific request
    int guid = await AppdynamicsMobilesdk.startRequest(uri);

    // Request goes out
    Response response = await get(uri);

    // AppDynamics end request
    AppdynamicsMobilesdk.endRequest(guid, response);

    //await agent.invokeMethod('httprequest.end',{ "statusCode": response.statusCode});
    // sample info available in response
    int statusCode = response.statusCode;
    Map<String, String> headers = response.headers;
    String contentType = headers['content-type'];
    String json = response.body;
    throw Exception("This is a crash!");

    // TODO convert json to object...*/

  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text(
            '$_counter',
            style: Theme.of(context).textTheme.display1,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _buttonPressed,
          tooltip: 'Make Http Request',
          child: Icon(Icons.add),
        ),

      ),
    );
  }
}
