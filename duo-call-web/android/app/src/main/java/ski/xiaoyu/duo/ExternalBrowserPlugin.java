package ski.xiaoyu.duo;

import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

@CapacitorPlugin(name = "ExternalBrowser")
public class ExternalBrowserPlugin extends Plugin {
    private static final String QIXI_HOST = "ai.xiaoyu.ski";
    private static final String QIXI_PATH = "/qx";

    @PluginMethod
    public void open(PluginCall call) {
        String value = call.getString("url", "");
        Uri uri = Uri.parse(value);
        if (
            !"https".equalsIgnoreCase(uri.getScheme()) ||
            !QIXI_HOST.equalsIgnoreCase(uri.getHost()) ||
            !QIXI_PATH.equals(uri.getPath())
        ) {
            call.reject("不允许打开该地址");
            return;
        }

        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            getActivity().startActivity(intent);
            call.resolve(new JSObject());
        } catch (ActivityNotFoundException error) {
            call.reject("未找到可用的浏览器", error);
        }
    }
}
