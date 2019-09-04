import 'dart:async';
import 'package:http/http.dart';

import 'package:flutter/services.dart';

class HttpRequestTracker {
  static const MethodChannel _channel =
  const MethodChannel('appdynamics_mobilesdk.');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<int> startRequest(String uri) async {
    //TODO, instead of a guid, can I create a tracker class?  that way it mimics the sdk.
    final int guid = await _channel.invokeMethod('httprequest', { "uri": uri });
    return guid;
  }

  //TODO this should be on a tracker object
  static Future<void> endRequest(int guid, Response response) async {
    await _channel.invokeMethod('httprequest.end',{ "guid": guid, "statusCode": response.statusCode});
  }
}
