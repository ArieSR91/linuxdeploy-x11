package ru.meefik.linuxdeploy;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.os.Build;

import com.termux.x11.LorieApp;

/**
 * The application class extends {@link LorieApp}: it keeps the state of the Termux:X11 display
 * (preferences, notification, connection with the X server) in the same process.
 */
public class App extends LorieApp {

    public static final String SERVICE_CHANNEL_ID = "SERVICE_CHANNEL";

    @Override
    public void onCreate() {
        super.onCreate();

        // Create notification channels for Oreo and newer
        createNotificationChannels();
    }

    private void createNotificationChannels() {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is new and not in the support library
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            CharSequence name = getString(R.string.service_notification_channel_name);
            String description = getString(R.string.service_notification_channel_description);
            int importance = NotificationManager.IMPORTANCE_LOW;
            NotificationChannel channel = new NotificationChannel(SERVICE_CHANNEL_ID, name, importance);
            channel.setDescription(description);
            // Register the channel with the system; you can't change the importance
            // or other notification behaviors after this
            NotificationManager notificationManager = getSystemService(NotificationManager.class);
            notificationManager.createNotificationChannel(channel);
        }

    }
}
