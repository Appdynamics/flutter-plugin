package com.appdynamics.appdynamics_mobilesdk;

import com.appdynamics.eumagent.runtime.Instrumentation;
import com.appdynamics.eumagent.runtime.HttpRequestTracker;
import java.net.URL;
import java.net.MalformedURLException;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** AppdynamicsMobilesdkPlugin */
public class AppdynamicsMobilesdkPlugin implements MethodCallHandler {
  private static HttpRequestTracker tracker;
  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "appdynamics_mobilesdk");
    channel.setMethodCallHandler(new AppdynamicsMobilesdkPlugin());
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if (call.method.equals("httprequest")) {
      String uri = call.argument("uri");
      try {
        URL url = new URL(uri);
        tracker = Instrumentation.beginHttpRequest(url);
      } catch (MalformedURLException e) {
        e.printStackTrace();
      }



      result.success(1);

    } else if(call.method.equals("httprequest.end")) {

      int statusCode = (int)call.argument("statusCode");

      tracker.withResponseCode(statusCode).reportDone();
      result.success(1);
    } else {
      result.notImplemented();
    }
  }

}
