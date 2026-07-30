package ski.xiaoyu.duo;

import android.app.Activity;
import android.app.PictureInPictureParams;
import android.os.Build;
import android.util.Rational;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "SystemPictureInPicture")
public class SystemPictureInPicturePlugin extends Plugin {

    @PluginMethod
    public void enter(PluginCall call) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            call.reject("Android 8.0 or newer is required for picture-in-picture");
            return;
        }

        int width = Math.max(1, call.getInt("width", 16));
        int height = Math.max(1, call.getInt("height", 9));
        Rational ratio = boundedRatio(width, height);
        Activity activity = getActivity();

        activity.runOnUiThread(() -> {
            try {
                PictureInPictureParams.Builder builder =
                    new PictureInPictureParams.Builder().setAspectRatio(ratio);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    builder.setSeamlessResizeEnabled(true);
                }
                boolean active = activity.enterPictureInPictureMode(builder.build());
                if (!active) {
                    call.reject("The system declined picture-in-picture mode");
                    return;
                }
                notifyModeChanged(true);
                JSObject result = new JSObject();
                result.put("active", true);
                call.resolve(result);
            } catch (IllegalArgumentException | IllegalStateException error) {
                call.reject("Unable to enter picture-in-picture mode", error);
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
