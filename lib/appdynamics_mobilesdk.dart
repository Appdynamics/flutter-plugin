import 'dart:async';
import 'package:http/http.dart';

import 'package:flutter/services.dart';

class AppdynamicsHttpRequestTracker {

  String guid;
  int responseCode;
  MethodChannel _channel;
  Map<String, List<String>> responseHeaderFields;


  AppdynamicsHttpRequestTracker(String guid, MethodChannel _channel) {
    this.guid = guid;
    this._channel = _channel;
    this.responseCode = -1;
    print("Start HTTP" + this.guid);
  }

  AppdynamicsHttpRequestTracker withResponseCode(int code) {
    this.responseCode = code;
    return this;
  }

  AppdynamicsHttpRequestTracker withResponseHeaderFields(Map<String, String> fields) {
    this.responseHeaderFields = {};
    fields.forEach((key, value) => {
      this.responseHeaderFields[key] = [value]
    });
    return this;
  }

  Future<void> reportDone() async {
    print("Report Done" + this.guid);
    await this._channel.invokeMethod('httprequest.end', {
      "guid": this.guid,
      "responseCode": this.responseCode,
      "responseHeaderFields": this.responseHeaderFields
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
    final String guid = await _channel.invokeMethod('httprequest', { "uri": uri });
    return new AppdynamicsHttpRequestTracker(guid, _channel);
  }

  static Future<Map<String, String>> getCorrelationHeaders() async {
    final Map<dynamic, dynamic> r = await _channel.invokeMethod('getCorrelationHeaders');
    Map<String, String> result = {};
    r.forEach((key, value) => {
      result[key] = value[0]
    });
    return result;
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

  static Future<void> startTimer(String label) async {
    await _channel.invokeMethod('startTimer',{"label": label});
  }

  static Future<void> stopTimer(String label) async {
    await _channel.invokeMethod('stopTimer',{"label": label});
  }
}

