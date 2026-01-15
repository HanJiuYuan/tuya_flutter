package us.kpmsg.tuya_flutter_ha_sdk;

import android.content.Context;
import android.util.Log;


public class ThingUtil {
    private static final String TAG = "ThingUtil";
    private static boolean appForeground = false;

    public static boolean isAppForeground(Context context) {
        return appForeground;
    }

    public static void setAppForeground(boolean foreground) {
        appForeground = foreground;
        Log.i(TAG, "setAppForeground=" + foreground);
    }
}
