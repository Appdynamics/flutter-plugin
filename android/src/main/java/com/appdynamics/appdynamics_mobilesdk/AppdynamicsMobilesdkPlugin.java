package com.appdynamics.appdynamics_mobilesdk;

import com.appdynamics.eumagent.runtime.Instrumentation;
import com.appdynamics.eumagent.runtime.HttpRequestTracker;
import com.appdynamics.eumagent.runtime.SessionFrame;
import com.appdynamics.eumagent.runtime.ErrorSeverityLevel;
import com.appdynamics.eumagent.runtime.ServerCorrelationHeaders;
import com.appdynamics.eumagent.runtime.BreadcrumbVisibility;
import java.net.URL;
import java.net.MalformedURLException;
import java.util.Map;
import java.util.List;
import java.util.HashMap;
import java.util.ArrayList;
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
  private static Map<String, SessionFrame> sessionFrames = new HashMap<String, SessionFrame>();

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

  public String startSessionFrame(String name) {
    String sessionId = UUID.randomUUID().toString();
    SessionFrame sessionFrame = Instrumentation.startSessionFrame(name);
    sessionFrames.put(sessionId, sessionFrame);
    return sessionId;
  }

  public void updateSessionFrame(String sessionId, String newName) {
    SessionFrame sessionFrame = sessionFrames.get(sessionId);
    sessionFrame.updateName(newName);
  }

  public void endSessionFrame(String sessionId) {
    SessionFrame sessionFrame = sessionFrames.get(sessionId);
    sessionFrame.end();
    sessionFrames.remove(sessionId);
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

        Map<String, String> headerFields = (Map<String, String>) call.argument("responseHeaderFields");

        HttpRequestTracker tracker = trackers.get(trackerId);

        if (responseCode > -1) {
            tracker.withResponseCode(responseCode);
        }

        if (httpError != null) {
            tracker.withError(httpError);
        }

        if (headerFields != null) {
            Map<String, List<String>> finalMap = new HashMap<String, List<String>>();
            for(Map.Entry<String, String> entry : headerFields.entrySet()) {
              List<String> list = new ArrayList<String>();
              list.add(entry.getValue());
              finalMap.put(entry.getKey(), list);
            }
            tracker.withResponseHeaderFields(finalMap);
        }

        tracker.reportDone();

        trackers.remove(trackerId);

        result.success(1);
        break;
      case "setUserData":
          Instrumentation.setUserData(call.argument("key").toString(), call.argument("value").toString());
        break;
      case "setUserDataLong":
          Instrumentation.setUserDataLong(call.argument("key").toString(), Long.parseLong(call.argument("value").toString()));
        break;
        case "setUserDataBoolean":
            Instrumentation.setUserDataBoolean(call.argument("key").toString(), Boolean.parseBoolean(call.argument("value").toString()));
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
        Map<String, String> finalMap = new HashMap<String, String>();
        for(Map.Entry<String, List<String>> entry : correlationHeaders.entrySet()) {
          finalMap.put(entry.getKey(), entry.getValue().get(0));
        }
        result.success(finalMap);
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
        //StackTraceElement[] trace = new StackTraceElement[tracelines.length];
        List<StackTraceElement> trace = new ArrayList<StackTraceElement>();

        for(int i = 0; i < tracelines.length; i ++) {
          String line = tracelines[i];
          //Log.d("AppD-line",line);
          //#0      _MyAppState._makeGetRequest (package:appdynamics_mobilesdk_example/main.dart:129:5)(test:1)
          //dart:async/zone.dart:1029:19

          String spacesanitized = line.trim().replaceAll("\\s{2,}", " ");

          //stacknumber-0 methodname-1 fileinfo&lineinfo-2;
          String[] parts = spacesanitized.split("\\(");
          if(parts.length > 1) {
            String fileinfo = parts[1].replaceAll("(\\(|\\))", "");
            // Log.d("fileinfo", fileinfo);
            String[] filesparts = fileinfo.split(":");
            String methodName = parts[0].substring(3, parts[0].length()-1).trim();
            String declaringClass = "Flutter.NoClass";
            if(methodName.lastIndexOf('.') > -1) {
              declaringClass = "Flutter." + methodName.substring(0,methodName.lastIndexOf('.'));
              methodName = methodName.substring(methodName.lastIndexOf('.')+1);
            }
            int linenumber = 0;
            if(filesparts.length == 4) {
              linenumber = Integer.parseInt(filesparts[2]);
              fileinfo = filesparts[1];
            }
            //  StackTraceElement(declaringClass, methodName, fileName, linenumber)
            Log.d("AppD", declaringClass);
            Log.d("AppD", methodName);
            Log.d("AppD", fileinfo);
            Log.d("AppD", String.valueOf(linenumber));
            trace.add(new StackTraceElement(declaringClass, methodName, fileinfo, linenumber));
          }
        }

        Log.d("AppD","-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-APPD-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-");
        Log.d("AppD",error);
        Log.d("AppD",stackTrace);

        ex.setStackTrace(trace.toArray(new StackTraceElement[0]));
        Log.d("Appd", ex.toString());
        ex.printStackTrace();
        Instrumentation.reportError(ex, ErrorSeverityLevel.CRITICAL);
        break;
      case "startSessionFrame":
        result.success(this.startSessionFrame(call.argument("name").toString()));
        break;
      case "updateSessionFrame":
        this.updateSessionFrame(call.argument("sessionId").toString(), call.argument("name").toString());
        break;
      case "endSessionFrame":
        this.endSessionFrame(call.argument("sessionId").toString());
        break;
      case "startNextSession":
        Instrumentation.startNextSession();
        break;
      default:
        result.notImplemented();
    }
  }
}
