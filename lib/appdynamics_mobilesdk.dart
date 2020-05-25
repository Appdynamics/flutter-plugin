import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

class AppdynamicsRouteObserver extends RouteObserver<Route<dynamic>> {

  AppdynamicsSessionFrame _currentFrame;
  String _currentName;

  void _updateSessionFrame(Route<dynamic> route) async {
    String name = ''; // route.name;//settings.name;
    // No name could be extracted, skip.
    if(name == null) {
      // Try to infer a name from the widget builder
      if(route is MaterialPageRoute<dynamic>) {
        String builderType = route.builder.runtimeType.toString();
        if(builderType.startsWith('(BuildContext) =>')) {
          String returnType = builderType.split('=>')[1].trim();
          if(returnType != 'Widget') {
            name = returnType;
          }
        }
      } else {
        return;
      }
    }
    // Name was not updated, skip.
    if(_currentName != null && name == _currentName) {
      return;
    }
    if(_currentFrame != null) {
      _currentFrame.end();
    }
    _currentName = name;
    _currentFrame = await AppdynamicsMobilesdk.startSessionFrame(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPush(route, previousRoute);
    _updateSessionFrame(route);
  }

  @override
  void didReplace({Route<dynamic> newRoute, Route<dynamic> oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _updateSessionFrame(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didRemove(route, previousRoute);
    _updateSessionFrame(previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    super.didPop(route, previousRoute);
    _updateSessionFrame(previousRoute);
  }
}


class AppdynamicsHttpClient extends http.BaseClient{
  final http.Client _httpClient;

  AppdynamicsHttpClient(this._httpClient);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    AppdynamicsHttpRequestTracker tracker = await AppdynamicsMobilesdk.startRequest(request.url.toString());
    return _httpClient.send(request).then((response) {
      tracker.withResponseCode(response.statusCode);
      tracker.withResponseHeaderFields(response.headers);
      return response;
    }, onError: (error) {
      print("error");
    }).whenComplete(() {
      tracker.reportDone();
    });
  }
}

class AppdynamicsSessionFrame {
  String sessionId;
  String name;
  MethodChannel _channel;

  AppdynamicsSessionFrame(String sessionId, String name, MethodChannel _channel) {
    this.sessionId = sessionId;
    this.name = name;
    this._channel = _channel;
  }

  Future<AppdynamicsSessionFrame> updateName(String name) async {
    this.name = name;
    await this._channel.invokeMethod('updateSessionFrame', {
      "sessionId": this.sessionId,
      "name": this.name
    });
    return this;
  }

  Future<AppdynamicsSessionFrame> end() async {
    await this._channel.invokeMethod('endSessionFrame', {
      "sessionId": this.sessionId
    });
    return this;
  }
}

class AppdynamicsHttpRequestTracker {

  Future<String> trackerId;
  String error;
  Exception exception;
  int responseCode;
  MethodChannel _channel;
  Map<String, String> responseHeaderFields;


  AppdynamicsHttpRequestTracker(String url, MethodChannel _channel) {
    this.trackerId = _channel.invokeMethod('startRequest', { "url": url });
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

  AppdynamicsHttpRequestTracker withResponseHeaderFields(Map<String, String> fields) {
    this.responseHeaderFields = fields;
    return this;
  }

  Future<void> reportDone() async {
    String trackerId = await this.trackerId;
    await this._channel.invokeMethod('reportDone', {
      "trackerId": trackerId,
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

  static AppdynamicsHttpRequestTracker startRequest(String url) {
    return new AppdynamicsHttpRequestTracker(url, _channel);
  }

  static Future<AppdynamicsSessionFrame> startSessionFrame(String name) async {
    final String sessionId = await _channel.invokeMethod('startSessionFrame', { "name": name });
    return new AppdynamicsSessionFrame(sessionId, name, _channel);
  }

  static Future<Map<String, String>> getCorrelationHeaders([bool valuesAsList = true]) async {
    Map r = await _channel.invokeMethod('getCorrelationHeaders');
    if(r is Map<String, String>) {
      return r;
    }
    Map<String, String> result = {};
    r.forEach((k,v) => {
      result[k] = v.toString()
    });
    return result;
  }

  static Future<void> takeScreenshot() async {
    await _channel.invokeMethod('takeScreenshot');
  }

  static Future<void> setUserData(String key, String value) async {
    await _channel.invokeMethod('setUserData', {"key": key, "value": value});
  }

  static Future<void> setUserDataLong(String key, int value) async {
    await _channel.invokeMethod('setUserDataLong', {"key": key, "value": value});
  }

  static Future<void> setUserDataBoolean(String key, bool value) async {
    await _channel.invokeMethod('setUserDataBoolean', {"key": key, "value": value});
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

  static Future<void> startNextSession() async {
    await _channel.invokeMethod('startNextSession');
  }

  static Future<void> leaveBreadcrumb(breadcrumb, visibleInCrashesAndSessions) async {
    await _channel.invokeMethod('leaveBreadcrumb', { "breadcrumb": breadcrumb, "visibleInCrashesAndSessions": visibleInCrashesAndSessions});
  }

  static Future<void> reportMetric(String name, int value) async {
    await _channel.invokeMethod('reportMetric', {"name": name, "value": value});
  }
}
