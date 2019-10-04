import 'dart:async';
import 'package:http/http.dart';
import 'package:intl/intl.dart';

import 'package:flutter/services.dart';

class AppdynamicsHttpRequestTracker {

  String trackerId;
  String error;
  Exception exception;
  int responseCode;
  MethodChannel _channel;
  Map<String, List<String>> responseHeaderFields;


  AppdynamicsHttpRequestTracker(String trackerId, MethodChannel _channel) {
    this.trackerId = trackerId;
    this._channel = _channel;
    this.responseCode = -1;
  }

  AppdynamicsHttpRequestTracker withResponseCode(int code) {
    this.responseCode = code;
    return this;
  }

  AppdynamicsHttpRequestTracker withException(Exception exception) {
    this.exception = exception;
    return this;
  }

  AppdynamicsHttpRequestTracker withError(String error) {
    this.error = error;
    return this;
  }

  AppdynamicsHttpRequestTracker withResponseHeaderFields(Map<dynamic, dynamic> fields) {
    if(fields is Map<String, String>) {
      this.responseHeaderFields = {};
      fields.forEach((key, value) => {
        this.responseHeaderFields[key] = [value]
      });
    } else {
      this.responseHeaderFields = fields;
    }
    return this;
  }

  Future<void> reportDone() async {
    await this._channel.invokeMethod('reportDone', {
      "trackerId": this.trackerId,
      "responseCode": this.responseCode,
      "responseHeaderFields": this.responseHeaderFields,
      "error": this.error,
      "exception": this.exception
    });
  }
}

class AppdynamicsMobilesdk {


  static const MethodChannel _channel =
      const MethodChannel('appdynamics_mobilesdk');

  static Future<AppdynamicsHttpRequestTracker> startRequest(String url) async {
    //TODO, instead of a guid, can I create a tracker class?  that way it mimics the sdk.
    final String trackerId = await _channel.invokeMethod('startRequest', { "url": url });
    return new AppdynamicsHttpRequestTracker(trackerId, _channel);
  }

  static Future<Map<dynamic, dynamic>> getCorrelationHeaders([bool valuesAsList = true]) async {
    final Map<dynamic, dynamic> r = await _channel.invokeMethod('getCorrelationHeaders');
    if(valuesAsList) {
      return r;
    }
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

  static Future<void> setUserData(String key, String value) async {
    await _channel.invokeMethod('setUserData', {"key": key, "value": value});
  }

  static Future<void> setUserDataLong(String key, int value) async {
    await _channel.invokeMethod('setUserDataLong', {"key": key, "value": value});
  }

  static Future<void> setUserDataDouble(String key, double value) async {
    await _channel.invokeMethod('setUserDataDouble', {"key": key, "value": value});
  }

  static Future<void> setUserDataDate(String key, DateTime dt) async {
    String value = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(dt);
    await _channel.invokeMethod('setUserDataDate', {"key": key, "value": value.toString()});
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
