package ski.xiaoyu.duo;

import android.content.res.Configuration;
import android.os.Bundle;
import com.getcapacitor.BridgeActivity;
import com.getcapacitor.PluginHandle;
import androidx.core.view.WindowCompat;

public class MainActivity extends BridgeActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        registerPlugin(SystemPictureInPicturePlugin.class);
        registerPlugin(ExternalBrowserPlugin.class);
        super.onCreate(savedInstanceState);
        WindowCompat.enableEdgeToEdge(getWindow());
    }

    @Override
    public void onPictureInPictureModeChanged(
        boolean isInPictureInPictureMode,
        Configuration newConfig
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig);
        if (bridge == null) return;
        PluginHandle handle = bridge.getPlugin("SystemPictureInPicture");
        if (
            handle != null &&
            handle.getInstance() instanceof SystemPictureInPicturePlugin
        ) {
            ((SystemPictureInPicturePlugin) handle.getInstance())
                .notifyModeChanged(isInPictureInPictureMode);
        }
    }

    @Override
    protected void onUserLeaveHint() {
        super.onUserLeaveHint();
        if (bridge == null) return;
        PluginHandle handle = bridge.getPlugin("SystemPictureInPicture");
        if (handle != null && handle.getInstance() instanceof SystemPictureInPicturePlugin) {
            ((SystemPictureInPicturePlugin) handle.getInstance()).enterOnBackground();
        }
    }
}
