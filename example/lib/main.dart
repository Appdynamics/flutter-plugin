import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:appdynamics_mobilesdk/appdynamics_mobilesdk.dart';
// import 'package:flutter_load_local_json/settings.dart';

Future<Null> _reportError(dynamic error, dynamic stackTrace) async {
  print('Caught error: $error');
  print(stackTrace);
  print('Reporting to Appdynamics...');
  AppdynamicsMobilesdk.reportError(error, stackTrace);
}

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) async {
    Zone.current.handleUncaughtError(details.exception, details.stack);
  };
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
  AppdynamicsSessionFrame frame;
  int _counter = 0;
  int frameCounter = 0;

  List<dynamic> frames = [
    {
      "name": "Login",
      "image": "",
      "urls": [
          "http://www.appdynamics.com/"
      ]
    },
    {
      "name": "Logut",
      "image": "",
      "urls": [
          "http://www.appdynamics.com/"
      ]
    }
  ];

  String _frameName = 'Unknown';
  String _image = '';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {


    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;


    var settings = json.decode(await rootBundle.loadString('assets/settings.json'));

    if(settings.containsKey("frames")) { frames = settings["frames"]; }

    frame = await AppdynamicsMobilesdk.startSessionFrame("App Start");

    setState(() {
      print(_counter);
      _counter++;
      _frameName = "App Start";
    });

    _clock();
  }

  _clock() async {
    while(true) {
      await _next();
      await new Future.delayed(const Duration(seconds: 10));
      print("Next after 10 seconds");
    }
  }

  _next() async {
    frame.end();

    var current = frames[frameCounter % frames.length];

    var frameName = current["name"];
    var image = current["image"];

    var breadCrumb = current.containsKey("breadcrumb") ? current["breadcrumb"] : false;
    var startTimer = current.containsKey("startTimer") ? current["startTimer"] : false;
    var stopTimer = current.containsKey("stopTimer") ? current["stopTimer"] : false;
    var urls = current.containsKey("urls") ? current["urls"] : false;

    if(frameCounter >= frames.length) {
      print('Starting a new session after ' + frameName);
      await AppdynamicsMobilesdk.startNextSession();
      frameCounter = 0;
    }

    if(startTimer != false) {
      print('Start Timer');
      await AppdynamicsMobilesdk.startTimer(current["startTimer"]);
    }

    if(stopTimer != false) {
      print('Stop Timer');
      await AppdynamicsMobilesdk.stopTimer(current["stopTimer"]);
    }

    if(breadCrumb != false) {
      await AppdynamicsMobilesdk.leaveBreadcrumb(breadCrumb, true);
    }

    print(frameName);
    frame = await AppdynamicsMobilesdk.startSessionFrame(frameName);

    if(urls != false) {
      for(var i = 0; i < urls.length; i++){
        await _makeGetRequest(urls[i]);
      }
    }

    await AppdynamicsMobilesdk.takeScreenshot();

    /*AppdynamicsMobilesdk.setUserData("counter_long", _counter);
    AppdynamicsMobilesdk.setUserDataLong("counter_long", _counter);
    AppdynamicsMobilesdk.setUserDataDouble("cartValue", _counter.toDouble());
    AppdynamicsMobilesdk.setUserDataDate("myDate", DateTime.now());
    AppdynamicsMobilesdk.setUserDataBoolean("isRegistered", true);*/

    frameCounter++;

    setState(() {
      _frameName = frameName;
      _image = image;
    });
  }

  _crashMe() async {
    var f;
    f();
    var x = () {
      var y = () => f();
      y();
    };
    x();
  }

  _removeButtonPressed() async {
    _crashMe();
    setState(() {
      print(_counter);
      _counter--;
    });
  }

  _addButtonPressed() async {
    await _next();
  }

  Future<Response> _makeGetRequest(uri, [responseCode = -1]) async {
    print('GET $uri');
    // AppDynamics specific request
    AppdynamicsHttpRequestTracker tracker = await AppdynamicsMobilesdk.startRequest(uri);
    Map<String, String> correlationHeaders = await AppdynamicsMobilesdk.getCorrelationHeaders();

    print("CH BEGIN");
    print(correlationHeaders);
    print("CH END");
    print(uri + " start");

    // Request goes out
    return get(uri, headers: correlationHeaders).then((response) async {

      if(responseCode <= 0) {
        responseCode = response.statusCode;
      }

      print(response.headers);

      /*response.headers.forEach((k, v) {
        response.headers[k] = v.replaceAll('%3A', ':');
      });

      print(response.headers);
      */
      tracker.withResponseCode(responseCode).withResponseHeaderFields(response.headers);

      if(responseCode > 500) {
        tracker.withError('An error!!!');
      }

      await tracker.reportDone();
      print(uri + " end");
      return response;
    });

  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('$_frameName'),
        ),
        body: Center(
          child: Image.network(
            '$_image',
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
            alignment: Alignment.center,
          ),
        ),
        floatingActionButton: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
  mainAxisSize: MainAxisSize.min,
          children: <Widget>[
          FloatingActionButton(
            onPressed: _addButtonPressed,
            tooltip: 'Refresh',
            child: Icon(Icons.autorenew),
          ),
          FloatingActionButton(
            onPressed: _removeButtonPressed,
            tooltip: 'Cancel',
            child: Icon(Icons.cancel),
            backgroundColor: Colors.red,
        )]),
      ),
    );
  }
}
