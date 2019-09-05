import 'dart:async';
import 'package:http/http.dart';

import 'package:flutter/services.dart';

class AppdynamicsHttpRequestTracker {

  int guid;
  int responseCode;
  MethodChannel _channel;


  AppdynamicsHttpRequestTracker(int guid, MethodChannel _channel) {
    this.guid = guid;
    this._channel = _channel;
    this.responseCode = -1;
  }

  AppdynamicsHttpRequestTracker withResponseCode(int code) {
    this.responseCode = code;
    return this;
  }

  Future<void> reportDone() async {
    await this._channel.invokeMethod('httprequest.end', {
      "guid": this.guid,
      "responseCode": this.responseCode
    });
  }
}

class AppdynamicsMobilesdk {


  static const MethodChannel _channel =
      const MethodChannel('appdynamics_mobilesdk');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<AppdynamicsHttpRequestTracker> startRequest(String uri) async {
    //TODO, instead of a guid, can I create a tracker class?  that way it mimics the sdk.
    final int guid = await _channel.invokeMethod('httprequest', { "uri": uri });
    return new AppdynamicsHttpRequestTracker(guid, _channel)
  }

  static Future<int> takeScreenshot() async {
    final int guid = await _channel.invokeMethod('takeScreenshot');
    return guid;
  }

  static Future<void> setUserData(String label, String value) async {
    await _channel.invokeMethod('setUserData', {"label": label, "value": value});
  }

  //TODO this should be on a tracker object
  static Future<void> endRequest(int guid, Response response) async {
    await _channel.invokeMethod('httprequest.end',{ "guid": guid, "statusCode": response.statusCode});
  }

  static Future<void> reportError(dynamic error, dynamic stackTrace) async {
    await _channel.invokeMethod('reportError',{ "error": error.toString(), "stackTrace": stackTrace.toString()});
  }
}

