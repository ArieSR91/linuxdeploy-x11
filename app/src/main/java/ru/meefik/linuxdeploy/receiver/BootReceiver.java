package ru.meefik.linuxdeploy.receiver;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

import ru.meefik.linuxdeploy.EnvUtils;
import ru.meefik.linuxdeploy.PrefStore;

public class BootReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(final Context context, Intent intent) {
        final String action = intent.getAction();
        if (action == null) return;
        if (!Intent.ACTION_BOOT_COMPLETED.equals(action)
                && !Intent.ACTION_SHUTDOWN.equals(action)) return;

        // The autostart/shutdown delay must not block the main thread (ANR on Android 8+),
        // so the work is moved to a background thread and the receiver is kept alive with goAsync().
        final PendingResult result = goAsync();
        final Context appContext = context.getApplicationContext();
        new Thread(() -> {
            try {
                switch (action) {
                    case Intent.ACTION_BOOT_COMPLETED:
                        sleepSeconds(PrefStore.getAutostartDelay(appContext));
                        EnvUtils.execServices(appContext, new String[]{"telnetd", "httpd"}, "start");
                        EnvUtils.execService(appContext, "start", "-m");
                        break;
                    case Intent.ACTION_SHUTDOWN:
                        EnvUtils.execService(appContext, "stop", "-u");
                        EnvUtils.execServices(appContext, new String[]{"telnetd", "httpd"}, "stop");
                        sleepSeconds(PrefStore.getAutostartDelay(appContext));
                        break;
                }
            } finally {
                result.finish();
            }
        }).start();
    }

    private static void sleepSeconds(Integer seconds) {
        if (seconds == null || seconds <= 0) return;
        try {
            Thread.sleep(seconds * 1000L);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
