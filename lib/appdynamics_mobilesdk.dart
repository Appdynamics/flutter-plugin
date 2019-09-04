import 'dart:async';
import 'package:http/http.dart';

import 'package:flutter/services.dart';

class AppdynamicsMobilesdk {
  static const MethodChannel _channel =
      const MethodChannel('appdynamics_mobilesdk');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<int> startRequest(String uri) async {
    final int guid = await _channel.invokeMethod('httprequest', { "uri": uri });
    return guid;
  }
  static Future<void> endRequest(int guid, Response response) async {
    await _channel.invokeMethod('httprequest.end',{ "guid": guid, "statusCode": response.statusCode});
  }
}
