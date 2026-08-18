package ski.xiaoyu.duo;

import android.app.Activity;
import android.Manifest;
import android.content.pm.PackageManager;
import android.app.PictureInPictureParams;
import android.os.Build;
import android.util.Rational;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;
import androidx.core.app.NotificationCompat;

@CapacitorPlugin(name = "SystemPictureInPicture", permissions = {
    @Permission(alias = "notifications", strings = { Manifest.permission.POST_NOTIFICATIONS })
})
public class SystemPictureInPicturePlugin extends Plugin {
    private static final String MESSAGE_CHANNEL_ID = "duo-messages";
    private boolean callActive = false;
    private int callWidth = 16;
    private int callHeight = 9;

    @PluginMethod
    public void startCall(PluginCall call) {
        callActive = true;
        callWidth = Math.max(1, call.getInt("width", 16));
        callHeight = Math.max(1, call.getInt("height", 9));
        DuoCallForegroundService.start(getContext());
        call.resolve();
    }

    @PluginMethod
    public void requestNotificationPermission(PluginCall call) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            getPermissionState("notifications") == com.getcapacitor.PermissionState.GRANTED) {
            call.resolve();
            return;
        }
        requestPermissionForAlias("notifications", call, "notificationPermissionResult");
    }

    @PermissionCallback
    private void notificationPermissionResult(PluginCall call) {
        if (getPermissionState("notifications") == com.getcapacitor.PermissionState.GRANTED) call.resolve();
        else call.reject("Notification permission was not granted");
    }

    @PluginMethod
    public void notifyMessage(PluginCall call) {
        String title = call.getString("title", "爱情小屋的新消息");
        String body = call.getString("body", "TA 发来了一条消息");
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            getPermissionState("notifications") != com.getcapacitor.PermissionState.GRANTED) {
            call.reject("Notification permission was not granted");
            return;
        }
        android.app.NotificationManager manager = getContext().getSystemService(android.app.NotificationManager.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(new android.app.NotificationChannel(
                MESSAGE_CHANNEL_ID, "爱情小屋消息", android.app.NotificationManager.IMPORTANCE_DEFAULT));
        }
        NotificationCompat.Builder builder = new NotificationCompat.Builder(getContext(), MESSAGE_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.sym_action_chat)
            .setContentTitle(title).setContentText(body).setAutoCancel(true);
        manager.notify(call.getInt("id", (int) System.currentTimeMillis()), builder.build());
        call.resolve();
    }

    @PluginMethod
    public void stopCall(PluginCall call) {
        callActive = false;
        DuoCallForegroundService.stop(getContext());
        call.resolve();
    }

    @PluginMethod
    public void enter(PluginCall call) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            call.reject("Android 8.0 or newer is required for picture-in-picture");
            return;
        }

        int width = Math.max(1, call.getInt("width", 16));
        int height = Math.max(1, call.getInt("height", 9));
        callActive = true;
        callWidth = width;
        callHeight = height;
        DuoCallForegroundService.start(getContext());
        Rational ratio = boundedRatio(width, height);
        Activity activity = getActivity();

        activity.runOnUiThread(() -> {
            try {
                PictureInPictureParams.Builder builder =
                    new PictureInPictureParams.Builder().setAspectRatio(ratio);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    builder.setSeamlessResizeEnabled(true);
                }
                notifyModeChanged(true);
                boolean active = activity.enterPictureInPictureMode(builder.build());
                if (!active) {
                    notifyModeChanged(false);
                    call.reject("The system declined picture-in-picture mode");
                    return;
                }
                JSObject result = new JSObject();
                result.put("active", true);
                call.resolve(result);
            } catch (IllegalArgumentException | IllegalStateException error) {
                notifyModeChanged(false);
                call.reject("Unable to enter picture-in-picture mode", error);
            }
        });
    }

    public void enterOnBackground() {
        if (!callActive || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return;
        Activity activity = getActivity();
        activity.runOnUiThread(() -> {
            if (activity.isInPictureInPictureMode()) return;
            try {
                notifyModeChanged(true);
                boolean active = activity.enterPictureInPictureMode(
                    new PictureInPictureParams.Builder()
                        .setAspectRatio(boundedRatio(callWidth, callHeight))
                        .build()
                );
                if (!active) notifyModeChanged(false);
            } catch (IllegalArgumentException | IllegalStateException ignored) {
                notifyModeChanged(false);
            }
        });
    }

    @PluginMethod
    public void isActive(PluginCall call) {
        JSObject result = new JSObject();
        result.put(
            "active",
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.N &&
                getActivity().isInPictureInPictureMode()
        );
        call.resolve(result);
    }

    public void notifyModeChanged(boolean active) {
        JSObject state = new JSObject();
        state.put("active", active);
        notifyListeners("modeChanged", state, true);
    }

    private Rational boundedRatio(int width, int height) {
        double ratio = (double) width / (double) height;
        if (ratio > 2.39d) return new Rational(239, 100);
        if (ratio < 0.42d) return new Rational(42, 100);
        return new Rational(width, height);
    }
}
