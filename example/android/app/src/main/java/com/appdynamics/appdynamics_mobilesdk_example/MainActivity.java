package com.appdynamics.appdynamics_mobilesdk_example;

import android.os.Bundle;
import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import com.appdynamics.eumagent.runtime.Instrumentation;
import com.appdynamics.eumagent.runtime.AgentConfiguration;
import java.net.URL;
import java.net.MalformedURLException;
import java.io.InputStream;
import java.util.*;


public class MainActivity extends FlutterActivity {
  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    String appkey = "";
    try {
      InputStream is = getApplicationContext().getAssets().open("config.properties");
      Properties props = new Properties();
      props.load(is);

      appkey = props.getProperty("APPDYNAMICS_EUM_KEY", "");

      is.close();
    } catch (Exception e) {
    }
    // Instrumentation.start(appkey, getApplicationContext());
    Instrumentation.start(AgentConfiguration.builder()
            .withAppKey(appkey)
            .withContext(getApplicationContext())
            .withLoggingLevel(Instrumentation.LOGGING_LEVEL_VERBOSE)
            .build());
    GeneratedPluginRegistrant.registerWith(this);
  }
}
