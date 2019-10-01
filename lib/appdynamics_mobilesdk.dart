import 'dart:async';
import 'package:http/http.dart';

import 'package:flutter/services.dart';

class AppdynamicsHttpRequestTracker {

  String trackerId;
  int responseCode;
  MethodChannel _channel;
  Map<String, List<String>> responseHeaderFields;


  AppdynamicsHttpRequestTracker(String trackerId, MethodChannel _channel) {
    this.trackerId = trackerId;
    this._channel = _channel;
    this.responseCode = -1;
    print("Start HTTP" + this.trackerId);
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
    print("Report Done" + this.trackerId);
    await this._channel.invokeMethod('reportDone', {
      "trackerId": this.trackerId,
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

  static Future<AppdynamicsHttpRequestTracker> startRequest(String url) async {
    //TODO, instead of a guid, can I create a tracker class?  that way it mimics the sdk.
    final String trackerId = await _channel.invokeMethod('startRequest', { "url": url });
    return new AppdynamicsHttpRequestTracker(trackerId, _channel);
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
