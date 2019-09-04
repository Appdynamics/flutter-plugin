import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart';
import 'package:flutter/services.dart';
import 'package:appdynamics_mobilesdk/appdynamics_mobilesdk.dart';

void main() => runApp(MyApp());

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
    var uri = 'https://jsonplaceholder.typicode.com/posts';

    // AppDynamics specific request
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
