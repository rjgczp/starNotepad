package ski.xiaoyu.duo;

import android.content.res.Configuration;
import android.os.Bundle;
import com.getcapacitor.BridgeActivity;
import com.getcapacitor.PluginHandle;

public class MainActivity extends BridgeActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        registerPlugin(SystemPictureInPicturePlugin.class);
        super.onCreate(savedInstanceState);
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
}
