package com.appdynamics.appdynamics_mobilesdk;

import com.appdynamics.eumagent.runtime.Instrumentation;
import com.appdynamics.eumagent.runtime.HttpRequestTracker;
import com.appdynamics.eumagent.runtime.ErrorSeverityLevel;
import com.appdynamics.eumagent.runtime.ServerCorrelationHeaders;
import com.appdynamics.eumagent.runtime.BreadcrumbVisibility;
import java.net.URL;
import java.net.MalformedURLException;
import java.util.Map;
import java.util.List;
import java.util.HashMap;
import java.util.UUID;

import java.text.SimpleDateFormat;
import java.text.ParseException;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

import android.util.Log;

/** AppdynamicsMobilesdkPlugin */
public class AppdynamicsMobilesdkPlugin implements MethodCallHandler {
  private static Map<String, HttpRequestTracker> trackers = new HashMap<String, HttpRequestTracker>();

  private static SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "appdynamics_mobilesdk");
    channel.setMethodCallHandler(new AppdynamicsMobilesdkPlugin());
  }

  public String startRequest(URL url) {
    String trackerId = UUID.randomUUID().toString();
    HttpRequestTracker tracker = Instrumentation.beginHttpRequest(url);
    trackers.put(trackerId, tracker);
    return trackerId;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    Log.d("AppD",call.method);
    switch(call.method) {
      case "takeScreenshot":
        Instrumentation.takeScreenshot();
        break;
      case "startRequest":
        try {
          URL url = new URL(call.argument("url").toString());
          result.success(this.startRequest(url));
        } catch(MalformedURLException e) {
          e.printStackTrace();
        }
        break;
      case "reportDone":
        int responseCode = (int) call.argument("responseCode");
        String trackerId = call.argument("trackerId");
        String httpError = call.argument("error");

        Map<String, List<String>> headerFields = (Map<String, List<String>>) call.argument("responseHeaderFields");

        HttpRequestTracker tracker = trackers.get(trackerId);

        if (responseCode > -1) {
            tracker.withResponseCode(responseCode);
        }

        if (httpError != null) {
            tracker.withError(httpError);
        }

        if (headerFields != null) {
            tracker.withResponseHeaderFields(headerFields);
        }

        tracker.reportDone();
        result.success(1);
        break;
      case "setUserData":
          Instrumentation.setUserData(call.argument("key").toString(), call.argument("value").toString());
        break;
      case "setUserDataLong":
          Instrumentation.setUserDataLong(call.argument("key").toString(), Long.parseLong(call.argument("value").toString()));
        break;
      case "setUserDataDouble":
          Instrumentation.setUserDataDouble(call.argument("key").toString(), Double.parseDouble(call.argument("value").toString()));
        break;
      case "setUserDataDate":
        try {
          Instrumentation.setUserDataDate(call.argument("key").toString(), dateFormat.parse(call.argument("value").toString()));
        } catch(ParseException e) {
          e.printStackTrace();
        }
        break;
      case "leaveBreadcrumb":
          Instrumentation.leaveBreadcrumb(call.argument("breadcrumb").toString(), Boolean.parseBoolean(call.argument("visibleInCrashesAndSessions").toString()) ? BreadcrumbVisibility.CRASHES_AND_SESSIONS : BreadcrumbVisibility.CRASHES_ONLY);
        break;
      case "getCorrelationHeaders":
        Map<String,List<String>> correlationHeaders = ServerCorrelationHeaders.generate();
        for (Map.Entry<String,List<String>> entry : correlationHeaders.entrySet()) {
            Log.d("AppD", entry.getKey());
            List<String> list = entry.getValue();
            for(String elem : list) {
                Log.d("AppD", "--" + entry.getKey());
            }
        }
        result.success(correlationHeaders);
        break;
      case "startTimer":
          Instrumentation.startTimer(call.argument("label").toString());
      case "stopTimer":
          Instrumentation.stopTimer(call.argument("label").toString());
          break;
      case "reportError":
        String error = call.argument("error");
        String stackTrace = call.argument("stackTrace");
        String[] tracelines = stackTrace.split("\\r?\\n");
        Exception ex = new Exception(error);
        StackTraceElement[] trace = new StackTraceElement[tracelines.length];

        for(int i = 0; i < tracelines.length; i ++) {
          String line = tracelines[i];
          Log.d("AppD-line",line);
          //#0      _MyAppState._makeGetRequest (package:appdynamics_mobilesdk_example/main.dart:129:5)(test:1)
          //dart:async/zone.dart:1029:19

          String spacesanitized = line.trim().replaceAll("\\s{2,}", " ");

          //stacknumber-0 methodname-1 fileinfo&lineinfo-2;
          String[] parts = spacesanitized.split("\\(");
          String fileinfo = parts[1].replaceAll("(\\(|\\))", "");
          Log.d("fileinfo", fileinfo);
          String[] filesparts = fileinfo.split(":");
          int linenumber = filesparts.length == 4 ? Integer.parseInt(filesparts[2]) : 0;
          //  StackTraceElement(declaringClass, methodName, fileName, linenumber)
          trace[i] = new StackTraceElement("flutter",parts[0].substring(3, parts[0].length()-1),fileinfo,linenumber);
        }

        Log.d("AppD","-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-APPD-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");
        Log.d("AppD",error);
        Log.d("AppD",stackTrace);

         {

        };
        ex.setStackTrace(trace);
        Instrumentation.reportError(ex, ErrorSeverityLevel.CRITICAL);
        break;
      default:
        result.notImplemented();
    }
  }

  /*public void onMethodCallOld(MethodCall call, Result result) {
    Log.d("AppD","-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-APPD-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");
    if (call.method.equals("getPlatformVersion")) {
        result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if (call.method.equals("setUserData")) {
        Log.d("AppD","-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-USER DATA-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");
        String label = call.argument("label");
        String value = call.argument("value");
        Log.d("AppD", label);
        Log.d("AppD", value);
        Instrumentation.setUserData(label, value);
        Instrumentation.reportMetric(label, 1);
    } else if (call.method.equals("takeScreenshot")) {
        Instrumentation.takeScreenshot();
        Log.d("AppD", "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-SCREENSHOT-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");
        result.success(1);
    } else if (call.method.equals("getCorrelationHeaders")) {
        Map<String,List<String>> correlationHeaders = ServerCorrelationHeaders.generate();
        Log.d("AppD","-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-HEADERS BEGIN-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");
        for (Map.Entry<String,List<String>> entry : correlationHeaders.entrySet()) {
            Log.d("AppD", entry.getKey());
            List<String> list = entry.getValue();
            for(String elem : list) {
                Log.d("AppD", "--" + entry.getKey());
            }
        }
        Log.d("AppD","-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-HEADERS END-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");

        result.success(correlationHeaders);
    } else if (call.method.equals("httprequest")) {
      String uri = call.argument("uri");
      Log.d("AppD", "Send...");
      try {
        URL url = new URL(uri);
        String guid = UUID.randomUUID().toString();
        HttpRequestTracker tracker = Instrumentation.beginHttpRequest(url);
        trackers.put(guid, tracker);
        result.success(guid);
      } catch (MalformedURLException e) {
        e.printStackTrace();
      }
    } else if(call.method.equals("httprequest.end")) {

        int responseCode = (int) call.argument("responseCode");
        String guid = call.argument("guid");

        Map<String, List<String>> headerFields = (Map<String, List<String>>) call.argument("responseHeaderFields");

        HttpRequestTracker tracker = trackers.get(guid);

        if (responseCode > -1) {
            tracker.withResponseCode(responseCode);
        }

        if (headerFields != null) {
            tracker.withResponseHeaderFields(headerFields);
        }

        tracker.reportDone();
        result.success(1);
    } else if (call.method.equals("startTimer")) {
        String label = call.argument("label");
        Instrumentation.startTimer(label);
    } else if (call.method.equals("stopTimer")) {
        String label = call.argument("label");
        Instrumentation.stopTimer(label);
    } else if (call.method.equals("reportError")) {

        String error = call.argument("error");
        String stackTrace = call.argument("stackTrace");
        String[] tracelines = stackTrace.split("\\r?\\n");
        Exception ex = new Exception(error);
        StackTraceElement[] trace = new StackTraceElement[tracelines.length];

        for(int i = 0; i < tracelines.length; i ++) {
          String line = tracelines[i];
          Log.d("AppD-line",line);
          //#0      _MyAppState._makeGetRequest (package:appdynamics_mobilesdk_example/main.dart:129:5)(test:1)
          //dart:async/zone.dart:1029:19

          String spacesanitized = line.trim().replaceAll("\\s{2,}", " ");

          //stacknumber-0 methodname-1 fileinfo&lineinfo-2;
          String[] parts = spacesanitized.split("\\(");
          String fileinfo = parts[1].replaceAll("(\\(|\\))", "");
          Log.d("fileinfo", fileinfo);
          String[] filesparts = fileinfo.split(":");
          int linenumber = filesparts.length == 4 ? Integer.parseInt(filesparts[2]) : 0;
          //  StackTraceElement(declaringClass, methodName, fileName, linenumber)
          trace[i] = new StackTraceElement("flutter",parts[0].substring(3, parts[0].length()-1),fileinfo,linenumber);
        }

        Log.d("AppD","-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-APPD-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");
        Log.d("AppD",error);
        Log.d("AppD",stackTrace);

         {

        };
        ex.setStackTrace(trace);
        Instrumentation.reportError(ex, ErrorSeverityLevel.CRITICAL);


    }  else {
      result.notImplemented();
    }
  }*/

}
