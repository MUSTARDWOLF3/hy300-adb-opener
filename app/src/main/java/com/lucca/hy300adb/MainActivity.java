package com.lucca.hy300adb;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.provider.Settings;
import android.text.method.ScrollingMovementMethod;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import java.io.BufferedReader;
import java.io.InputStreamReader;

/**
 * HY300 ADB Opener
 *
 * Attempts to enable wireless ADB from a normal user app. This only works on firmware builds
 * where WRITE_SECURE_SETTINGS is granted to regular apps (typically userdebug builds, which
 * many cheap Rockchip RK3326 projectors like the HY300 clones ship with).
 *
 * On a successful run Android starts the TLS ADB service on a random port; the companion
 * script finds it via mDNS and connects.
 */
public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.BLACK);
        root.setPadding(48, 48, 48, 48);

        TextView title = new TextView(this);
        title.setText("HY300 ADB Opener");
        title.setTextColor(Color.WHITE);
        title.setTextSize(28);
        title.setPadding(0, 0, 0, 16);
        root.addView(title);

        TextView body = new TextView(this);
        body.setTextColor(0xFFCCCCCC);
        body.setTextSize(13);
        body.setMovementMethod(new ScrollingMovementMethod());
        String report;
        try {
            report = runAttempts();
        } catch (Throwable t) {
            report = "ERROR: " + t.getMessage();
        }
        body.setText(report);
        LinearLayout.LayoutParams bp = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f);
        root.addView(body, bp);

        LinearLayout buttons = new LinearLayout(this);
        buttons.setGravity(Gravity.END);
        buttons.setPadding(0, 24, 0, 0);

        Button openDev = new Button(this);
        openDev.setText("Opciones de desarrollador");
        openDev.setOnClickListener((View v) -> {
            try {
                startActivity(new Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            } catch (Exception e) {
                try { startActivity(new Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); } catch (Exception ignored) {}
            }
        });
        buttons.addView(openDev);

        Button close = new Button(this);
        close.setText("Cerrar");
        close.setOnClickListener(v -> finish());
        buttons.addView(close);
        root.addView(buttons);

        setContentView(root);
        close.requestFocus();
    }

    private String runAttempts() {
        StringBuilder log = new StringBuilder();
        boolean any = false;

        log.append("Writing Settings.Global...\n");
        String[] gkeys = {"adb_wifi_enabled", "adb_enabled", "development_settings_enabled"};
        for (String key : gkeys) {
            try {
                Settings.Global.putInt(getContentResolver(), key, 1);
                log.append("  ").append(key).append(" = 1  OK\n");
                any = true;
            } catch (SecurityException e) {
                log.append("  ").append(key).append("  SecurityException (expected on user builds)\n");
            } catch (Exception e) {
                log.append("  ").append(key).append("  ").append(e.getClass().getSimpleName()).append('\n');
            }
        }

        log.append("\nWriting Settings.Secure...\n");
        try {
            Settings.Secure.putInt(getContentResolver(), "adb_enabled", 1);
            log.append("  adb_enabled = 1  OK\n");
            any = true;
        } catch (Exception e) {
            log.append("  adb_enabled  ").append(e.getClass().getSimpleName()).append('\n');
        }

        log.append("\nRuntime.exec...\n");
        String[] cmds = {
                "settings put global adb_wifi_enabled 1",
                "setprop persist.adb.tcp.port 5555",
                "setprop service.adb.tcp.port 5555",
                "start adbd"};
        for (String cmd : cmds) {
            try {
                Process p = Runtime.getRuntime().exec(cmd);
                int code = p.waitFor();
                StringBuilder err = new StringBuilder();
                try (BufferedReader r = new BufferedReader(new InputStreamReader(p.getErrorStream()))) {
                    String line;
                    while ((line = r.readLine()) != null) err.append(line).append(' ');
                }
                log.append("  ").append(cmd).append("  exit=").append(code);
                if (err.length() > 0) log.append("  err=").append(err);
                log.append('\n');
                if (code == 0) any = true;
            } catch (Exception e) {
                log.append("  ").append(cmd).append("  ").append(e.getClass().getSimpleName()).append('\n');
            }
        }

        log.append("\nCurrent state:\n");
        for (String key : gkeys) {
            try {
                int v = Settings.Global.getInt(getContentResolver(), key, -1);
                log.append("  Global.").append(key).append(" = ").append(v).append('\n');
            } catch (Exception e) { }
        }
        try {
            int v = Settings.Secure.getInt(getContentResolver(), "adb_enabled", -1);
            log.append("  Secure.adb_enabled = ").append(v).append('\n');
        } catch (Exception e) { }

        log.append("\nRESULT: ");
        if (any) {
            log.append("At least one method succeeded. Now connect from your PC:\n");
            log.append("  adb mdns services   (look for _adb-tls-connect._tcp)\n");
            log.append("  adb connect <ip>:<port>\n");
            log.append("No pairing code should be needed on a userdebug build.\n");
        } else {
            log.append("No method succeeded. This firmware denies WRITE_SECURE_SETTINGS.\n");
            log.append("Nothing was changed on your device.\n");
        }
        return log.toString();
    }
}
