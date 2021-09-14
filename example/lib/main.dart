import 'dart:async';
import 'dart:math';

import 'package:appdynamics_mobilesdk/appdynamics_mobilesdk.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

Future<void> _reportError(dynamic error, dynamic stackTrace) async {
  print('Caught error: $error');
  print(stackTrace);
  print('Reporting to Appdynamics...');

  await AppdynamicsMobilesdk.reportError(error, stackTrace);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) async {
    if (details.stack != null) {
      Zone.current.handleUncaughtError(details.exception, details.stack!);
    }
  };

  runZonedGuarded<void>(
    () async {
      runApp(MyApp());
    },
    (Object error, StackTrace stackTrace) async {
      await _reportError(error, stackTrace);
    },
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppdynamicsSessionFrame frame;
  int _counter = 0;
  int frameCounter = 0;

  List<Map<String, dynamic>> frames = <Map<String, dynamic>>[
    <String, dynamic>{
      'name': 'Login',
      'image':
          'https://www.appdynamics.com/c/r/appdynamics/index/jcr:content/Grid/blade_2030858110_cop_57397882/bladeContents1/image/image.img.jpg/1618434204181.jpg',
      'urls': <String>['http://www.appdynamics.com/']
    },
    <String, dynamic>{
      'name': 'Logut',
      'image':
          'https://www.appdynamics.com/c/r/appdynamics/index/jcr:content/Grid/blade_1481457281_cop/bladeContents/tile_copy_copy/image.img.jpg/1626797278076.jpg',
      'urls': <String>['http://www.appdynamics.com/']
    }
  ];

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
    if (!mounted) {
      return;
    }

    frame = await AppdynamicsMobilesdk.startSessionFrame('App Start');

    setState(() {
      print(_counter);
      _counter++;
    });

    await _clock();
  }

  Future<void> _clock() async {
    Stream<void>.periodic(const Duration(seconds: 10)).listen((_) async {
      await _next();
      print('Next after 10 seconds');
    });
  }

  Future<void> _next() async {
    await frame.end();

    final Map<String, dynamic> current = frames[frameCounter % frames.length];

    final String frameName = current['name'].toString();
    final String image = current['image'].toString();

    setState(() {
      _image = image;
    });

    final Random rng = Random();

    final String? breadCrumb = current.containsKey('breadcrumb') ? current['breadcrumb'].toString() : null;
    // final startTimer = current.containsKey('startTimer') ? current['startTimer'] : false;
    // final stopTimer = current.containsKey('stopTimer') ? current['stopTimer'] : false;
    final List<String> urls = current.containsKey('urls') ? current['urls'] as List<String> : <String>[];

    if (frameCounter >= frames.length) {
      print('Starting a new session after ' + frameName);
      await AppdynamicsMobilesdk.startNextSession();
      frameCounter = 0;
      _counter++;
    }

    print('===== FRAME: ' + frameName + '======');
    frame = await AppdynamicsMobilesdk.startSessionFrame(frameName);

    if (breadCrumb != null) {
      await AppdynamicsMobilesdk.leaveBreadcrumb(breadCrumb, true);
      if (rng.nextInt(100) > 50) {
        _crashMe();
      }
    }

    if (urls.isNotEmpty) {
      for (int i = 0; i < urls.length; i++) {
        await _makeGetRequest(urls[i]);
      }
    }

    await Future<void>.delayed(const Duration(seconds: 2));

    await AppdynamicsMobilesdk.takeScreenshot();

    if (rng.nextInt(100) > 50) {
      await AppdynamicsMobilesdk.setUserData('language', 'de_DE');
      await AppdynamicsMobilesdk.setUserData('userId', '833ED2BF-FAA4-4660-A58F-4BA1C9C953D5');
      await AppdynamicsMobilesdk.setUserDataBoolean('hasSimplifiedEnabled', true);
    } else {
      await AppdynamicsMobilesdk.setUserData('language', 'fi_FI');
      await AppdynamicsMobilesdk.setUserData('userId', 'CCBF8FE3-20C3-48F6-822B-4FC69916B1A1');
      await AppdynamicsMobilesdk.setUserDataBoolean('hasSimplifiedEnabled', false);
    }

    //AppdynamicsMobilesdk.setUserDataLong('counter_long', _counter);
    //AppdynamicsMobilesdk.setUserDataDouble('cartValue', _counter.toDouble());
    //AppdynamicsMobilesdk.setUserDataDate('myDate', DateTime.now());
    //AppdynamicsMobilesdk.setUserDataBoolean('isRegistered', true);

    await AppdynamicsMobilesdk.reportMetric('frameCounter', frameCounter);

    frameCounter++;
  }

  void _crashMe() {
    dynamic f;
    f();

    final dynamic x = () {
      final dynamic y = () => f();
      y();
    };

    x();
  }

  void _removeButtonPressed() {
    _crashMe();

    setState(() {
      _counter--;
    });
  }

  Future<void> _addButtonPressed() async {
    await _next();
  }

  Future<Response> _makeGetRequest(String uri, [int responseCode = -1]) async {
    print('GET $uri');
    // AppDynamics specific request
    final AppdynamicsHttpRequestTracker tracker = AppdynamicsMobilesdk.startRequest(uri);
    final Map<String, String> correlationHeaders = await AppdynamicsMobilesdk.getCorrelationHeaders();

    print('CH BEGIN');
    print(correlationHeaders);
    print('CH END');
    print(uri + ' start');

    // Request goes out
    return get(Uri.parse(uri), headers: correlationHeaders).then((Response response) async {
      if (responseCode <= 0) {
        responseCode = response.statusCode;
      }

      print(response.headers);

      /*response.headers.forEach((k, v) {
        response.headers[k] = v.replaceAll('%3A', ':');
      });

      print(response.headers);
      */
      tracker
        ..withResponseCode(responseCode)
        ..withResponseHeaderFields(response.headers);

      if (responseCode > 500) {
        tracker.withError('An error!!!');
      }

      await tracker.reportDone();
      print(uri + ' end');
      return response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: _image == ''
              ? const Text('Wait for 10 seconds or press Refresh button to interact')
              : Image.network(
                  _image,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  width: double.infinity,
                ),
        ),
        floatingActionButton: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FloatingActionButton(
              onPressed: _addButtonPressed,
              tooltip: 'Refresh',
              child: const Icon(Icons.autorenew),
            ),
            FloatingActionButton(
              onPressed: _removeButtonPressed,
              tooltip: 'Cancel',
              backgroundColor: Colors.red,
              child: const Icon(Icons.cancel),
            )
          ],
        ),
      ),
    );
  }
}
