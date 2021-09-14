/// Flutter plugin to utilize the AppDynamics SDK.
import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';

class AppdynamicsRouteObserver extends RouteObserver<Route<dynamic>> {
  AppdynamicsSessionFrame? _currentFrame;
  String? _currentName;

  void _updateSessionFrame(Route<dynamic>? route) async {
    String name = ''; // route.name;//settings.name;
    // No name could be extracted, skip.

    // Try to infer a name from the widget builder
    if (route is MaterialPageRoute<dynamic>) {
      final String builderType = route.builder.runtimeType.toString();

      if (builderType.startsWith('(BuildContext) =>')) {
        final String returnType = builderType.split('=>')[1].trim();
        if (returnType != 'Widget') {
          name = returnType;
        }
      }
    } else {
      return;
    }

    // Name was not updated, skip.
    if (_currentName != null && name == _currentName) {
      return;
    }

    await _currentFrame?.end();

    _currentName = name;
    _currentFrame = await AppdynamicsMobilesdk.startSessionFrame(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    _updateSessionFrame(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    _updateSessionFrame(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);

    _updateSessionFrame(previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    _updateSessionFrame(previousRoute);
  }
}

class AppdynamicsHttpClient extends http.BaseClient {
  AppdynamicsHttpClient(this.httpClient);

  final http.Client httpClient;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final AppdynamicsHttpRequestTracker tracker = AppdynamicsMobilesdk.startRequest(request.url.toString());

    return httpClient.send(request).then((http.StreamedResponse response) {
      tracker
        ..withResponseCode(response.statusCode)
        ..withResponseHeaderFields(response.headers);

      return response;
    }, onError: (dynamic error) {
      log('error');
    }).whenComplete(tracker.reportDone);
  }
}

class AppdynamicsSessionFrame {
  AppdynamicsSessionFrame(
    String sessionId,
    String name,
    MethodChannel _channel,
  ) {
    this.sessionId = sessionId;
    this.name = name;
    this._channel = _channel;
  }

  late String sessionId;
  late String name;
  late MethodChannel _channel;

  Future<AppdynamicsSessionFrame> updateName(String name) async {
    this.name = name;

    await this._channel.invokeMethod<void>(
      'updateSessionFrame',
      <String, dynamic>{
        'sessionId': this.sessionId,
        'name': this.name,
      },
    );

    return this;
  }

  Future<AppdynamicsSessionFrame> end() async {
    await this._channel.invokeMethod<void>(
      'endSessionFrame',
      <String, dynamic>{'sessionId': this.sessionId},
    );

    return this;
  }
}

/// Class to report HTTP requests. Use the startRequest method to create a tracker
/// and use reportDone() to end the tracking
class AppdynamicsHttpRequestTracker {
  AppdynamicsHttpRequestTracker(String url, MethodChannel _channel) {
    this.trackerId = _channel.invokeMethod<String>(
      'startRequest',
      <String, String>{'url': url},
    );
    this._channel = _channel;
    this.responseCode = -1;
  }

  Future<String?>? trackerId;
  String? error;
  Exception? exception;
  late int responseCode;
  late MethodChannel _channel;
  Map<String, String>? responseHeaderFields;

  void withResponseCode(int code) {
    this.responseCode = code;
  }

  void withException(Exception exception) {
    this.exception = exception;
  }

  void withError(String error) {
    this.error = error;
  }

  void withResponseHeaderFields(Map<String, String> fields) {
    this.responseHeaderFields = fields;
  }

  Future<void> reportDone() async {
    final String? trackerId = await this.trackerId;

    if (trackerId == null) {
      throw Exception('trackerId must not be null');
    }

    await _channel.invokeMethod<void>('reportDone', <String, dynamic>{
      'trackerId': trackerId,
      'responseCode': this.responseCode,
      'responseHeaderFields': this.responseHeaderFields ?? <String, String>{},
      'error': this.error,
      'exception': this.exception
    });
  }
}

/// Interact with the AppDynamics Agent running in your application
///
/// This class provides a number of methods to interact with the AppDynamics Agent including
///
/// * Reporting custom metrics/timers
/// * Reporting information points manually
class AppdynamicsMobilesdk {
  static const MethodChannel _channel = MethodChannel('appdynamics_mobilesdk');

  /// Begins tracking an HTTP request. Call this immediately before sending an HTTP request to track it manually.
  static AppdynamicsHttpRequestTracker startRequest(String url) {
    return AppdynamicsHttpRequestTracker(url, _channel);
  }

  static Future<AppdynamicsSessionFrame> startSessionFrame(String name) async {
    final String? sessionId = await _channel.invokeMethod<String>(
      'startSessionFrame',
      <String, String>{'name': name},
    );

    if (sessionId == null) {
      throw Exception('sessionId must not be null');
    }

    return AppdynamicsSessionFrame(sessionId, name, _channel);
  }

  static Future<Map<String, String>> getCorrelationHeaders([bool valuesAsList = true]) async {
    final Map<dynamic, dynamic>? r = await _channel.invokeMethod('getCorrelationHeaders');

    if (r is Map<String, String>) {
      return r;
    }

    if (r == null) {
      return <String, String>{};
    }

    return r.map((dynamic key, dynamic value) {
      return MapEntry<String, String>(key.toString(), value.toString());
    });
  }

  static Future<void> takeScreenshot() async {
    await _channel.invokeMethod<void>('takeScreenshot');
  }

  static Future<void> setUserData(String key, String value) async {
    await _channel.invokeMethod<void>(
      'setUserData',
      <String, String>{
        'key': key,
        'value': value,
      },
    );
  }

  static Future<void> setUserDataLong(String key, int value) async {
    await _channel.invokeMethod<void>(
      'setUserDataLong',
      <String, dynamic>{'key': key, 'value': value},
    );
  }

  static Future<void> setUserDataBoolean(String key, bool value) async {
    await _channel.invokeMethod<void>(
      'setUserDataBoolean',
      <String, dynamic>{'key': key, 'value': value},
    );
  }

  static Future<void> setUserDataDouble(String key, double value) async {
    await _channel.invokeMethod<void>(
      'setUserDataDouble',
      <String, dynamic>{'key': key, 'value': value},
    );
  }

  static Future<void> setUserDataDate(String key, DateTime dt) async {
    final String value = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(dt);
    await _channel.invokeMethod<void>(
      'setUserDataDate',
      <String, dynamic>{'key': key, 'value': value.toString()},
    );
  }

  /// Reports an error that was caught.
  static Future<void> reportError(dynamic error, dynamic stackTrace) async {
    await _channel.invokeMethod<void>(
      'reportError',
      <String, dynamic>{'error': error.toString(), 'stackTrace': stackTrace.toString()},
    );
  }

  static Future<void> startTimer(String label) async {
    await _channel.invokeMethod<void>('startTimer', <String, dynamic>{'label': label});
  }

  static Future<void> stopTimer(String label) async {
    await _channel.invokeMethod<void>('stopTimer', <String, dynamic>{'label': label});
  }

  static Future<void> startNextSession() async {
    await _channel.invokeMethod<void>('startNextSession');
  }

  /// Leaves a breadcrumb that will appear in a crash report.
  static Future<void> leaveBreadcrumb(dynamic breadcrumb, bool visibleInCrashesAndSessions) async {
    await _channel.invokeMethod<void>(
      'leaveBreadcrumb',
      <String, dynamic>{'breadcrumb': breadcrumb, 'visibleInCrashesAndSessions': visibleInCrashesAndSessions},
    );
  }

  /// Reports metric value for the given name.
  static Future<void> reportMetric(String name, int value) async {
    await _channel.invokeMethod<void>(
      'reportMetric',
      <String, dynamic>{'name': name, 'value': value},
    );
  }
}
