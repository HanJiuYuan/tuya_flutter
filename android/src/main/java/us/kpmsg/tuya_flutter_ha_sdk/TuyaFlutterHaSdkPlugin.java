// android/src/main/java/us/kpmsg/tuya_flutter_ha_sdk/TuyaFlutterHaSdkPlugin.java

package us.kpmsg.tuya_flutter_ha_sdk;

import android.app.Application;
import android.net.wifi.WifiManager;
import android.net.wifi.WifiInfo;
import android.content.Context;
import android.content.Intent;
import android.net.wifi.SupplicantState;
import android.app.Activity;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.thingclips.smart.home.sdk.ThingHomeSdk;
import com.thingclips.smart.optimus.sdk.ThingOptimusSdk;
import com.facebook.drawee.backends.pipeline.Fresco;
// The login callback interface (adjust the package if needed):
//import com.thingclips.smart.home.sdk.api.ILoginCallback;
import com.thingclips.smart.android.user.api.ILoginCallback;
import com.thingclips.smart.android.user.bean.User;
import com.thingclips.smart.android.user.api.ILogoutCallback;
import com.thingclips.smart.sdk.api.IResultCallback;
import com.thingclips.smart.sdk.enums.TempUnitEnum;
import com.thingclips.smart.android.user.api.IReNickNameCallback;
import com.thingclips.smart.home.sdk.bean.HomeBean;
import com.thingclips.smart.home.sdk.callback.IThingHomeResultCallback;
import com.thingclips.smart.home.sdk.callback.IThingGetHomeListCallback;
import com.thingclips.smart.sdk.bean.DeviceBean;
import com.thingclips.smart.sdk.ThingSdk;
import com.thingclips.smart.sdk.api.IThingActivatorGetToken;
import com.thingclips.smart.home.sdk.builder.ActivatorBuilder;
import com.thingclips.smart.sdk.api.IThingActivator;
import com.thingclips.smart.sdk.api.IThingSmartActivatorListener;
import com.thingclips.smart.sdk.enums.ActivatorModelEnum;
import com.thingclips.smart.home.sdk.builder.ThingApActivatorBuilder;
import com.thingclips.smart.sdk.api.IThingOptimizedActivator;
import com.thingclips.smart.sdk.bean.ApQueryBuilder;
import com.thingclips.smart.home.sdk.callback.IThingResultCallback;
import com.thingclips.smart.home.sdk.bean.WiFiInfoBean;
import com.thingclips.smart.android.ble.api.LeScanSetting;
import com.thingclips.smart.android.ble.api.ScanType;
import com.thingclips.smart.android.ble.api.BleScanResponse;
import com.thingclips.smart.android.ble.api.ScanDeviceBean;
import com.thingclips.smart.sdk.bean.BleActivatorBean;
import com.thingclips.smart.sdk.api.IBleActivatorListener;
import com.thingclips.smart.sdk.bean.MultiModeActivatorBean;
import com.thingclips.smart.sdk.api.IMultiModeActivatorListener;
import com.thingclips.smart.sdk.api.IThingDevice;
import com.thingclips.smart.sdk.api.IDevListener;
import com.thingclips.smart.sdk.api.WifiSignalListener;
import com.thingclips.smart.home.sdk.callback.IThingRoomResultCallback;
import com.thingclips.smart.home.sdk.bean.RoomBean;
import com.thingclips.smart.home.sdk.callback.IThingGetRoomListCallback;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.embedding.android.FlutterActivity;

import com.thingclips.smart.sdk.api.IBleActivator;

import com.thingclips.smart.sdk.api.IMultiModeActivator;

import java.util.HashMap;
import java.util.Map;
import java.util.ArrayList;
import java.util.List;

import android.util.Log;

import org.jetbrains.annotations.Nullable;

/**
 * TuyaFlutterHaSdkPlugin
 */
public class TuyaFlutterHaSdkPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
    private MethodChannel channel;
    private Application appContext;
    IThingActivator mThingActivator;
    private Activity activity;
    private EventChannel eventChannel;
    private EventSink eventSink;

    private IBleActivator mBleActivator;

    private IMultiModeActivator mComboActivator;


    private String mBleActivatorUuid;

    private String mComboActivatorUuid;


    /**
     * Stop any ongoing BLE scan or activator so the next one
     * <p>
     * starts with a clean slate.
     */

    private void stopAnyPairingOrScan() {

        // stop any BLE scan

        ThingHomeSdk.getBleOperator().stopLeScan();


        // stop BLE-only activator

        if (mBleActivator != null && mBleActivatorUuid != null) {

            mBleActivator.stopActivator(mBleActivatorUuid);

            mBleActivator = null;

            mBleActivatorUuid = null;

        }

        // stop Combo (BLE→Wi-Fi) activator

        if (mComboActivator != null && mComboActivatorUuid != null) {

            mComboActivator.stopActivator(mComboActivatorUuid);

            mComboActivator = null;

            mComboActivatorUuid = null;

        }


    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        // 确保获取 Application Context
        Context context = binding.getApplicationContext();
        if (context instanceof Application) {
            appContext = (Application) context;
        } else {
            // 如果获取不到，记录错误
            Log.e("TuyaFlutterHaSdk", "Failed to get Application context from binding");
            // 尝试从 Activity 获取（如果可用）
            if (activity != null) {
                Context appCtx = activity.getApplicationContext();
                if (appCtx instanceof Application) {
                    appContext = (Application) appCtx;
                }
            }
        }
        
        if (appContext == null) {
            Log.e("TuyaFlutterHaSdk", "Warning: Application context is null. Some SDK operations may fail.");
        }
        
        channel = new MethodChannel(binding.getBinaryMessenger(), "tuya_flutter_ha_sdk");
        channel.setMethodCallHandler(this);
        eventChannel = new EventChannel(binding.getBinaryMessenger(), "tuya_flutter_ha_sdk/pairingEvents");
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
            }

            @Override
            public void onCancel(Object arguments) {
                eventSink = null;
            }
        });
        TuyaCameraPlugin tuyaCameraPlugin=new TuyaCameraPlugin();
        tuyaCameraPlugin.registerPlugin(binding);
    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();
        // 标记应用进入前台（仅用于调试前台状态与 MQTT/P2P 行为的关系）
        try {
            ThingUtil.setAppForeground(true);
        } catch (Throwable t) {
            Log.w("TuyaFlutterHaSdk", "ThingUtil.setAppForeground(true) failed", t);
        }
        // 如果 appContext 还是 null，尝试从 Activity 获取
        if (appContext == null && activity != null) {
            Context appCtx = activity.getApplicationContext();
            if (appCtx instanceof Application) {
                appContext = (Application) appCtx;
                Log.i("TuyaFlutterHaSdk", "Application context obtained from Activity");
            }
        }
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {
        this.activity = null;
        // 标记应用离开前台
        try {
            ThingUtil.setAppForeground(false);
        } catch (Throwable t) {
            Log.w("TuyaFlutterHaSdk", "ThingUtil.setAppForeground(false) failed", t);
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "getPlatformVersion":
                result.success("Android " + android.os.Build.VERSION.RELEASE);
                break;

            case "openNativeCamera": {
                // 仅在 Android 上，从 Flutter 打开原生 TuyaCameraPanelActivity
                String devId = call.argument("devId");
                if (devId == null || devId.isEmpty()) {
                    result.error("INVALID_ARGS", "devId is required", null);
                    break;
                }
                if (activity == null) {
                    result.error("NO_ACTIVITY", "Activity is null, cannot start native camera", null);
                    break;
                }
                try {
                    Intent intent = new Intent();
                    // 使用显式类名启动应用主 module 中的 TuyaCameraPanelActivity
                    intent.setClassName(activity.getPackageName(),
                            "com.zyg.w903.TuyaCameraPanelActivity");
                    intent.putExtra("devId", devId);
                    activity.startActivity(intent);
                    result.success(null);
                } catch (Throwable t) {
                    Log.e("TuyaFlutterHaSdk", "Failed to start TuyaCameraPanelActivity", t);
                    result.error("START_FAILED", t.getMessage(), null);
                }
                break;
            }

            case "prewarmNativeCamera": {
                // Android 端透明预热：启动 PrewarmCameraActivity，短暂建立一次 P2P + 预览后自动退出
                String devId = call.argument("devId");
                if (devId == null || devId.isEmpty()) {
                    result.error("INVALID_ARGS", "devId is required", null);
                    break;
                }
                if (activity == null) {
                    result.error("NO_ACTIVITY", "Activity is null, cannot start prewarm", null);
                    break;
                }
                try {
                    Intent intent = new Intent();
                    intent.setClassName(activity.getPackageName(),
                            "com.zyg.w903.PrewarmCameraActivity");
                    intent.putExtra("devId", devId);
                    activity.startActivity(intent);
                    // 预热为 fire-and-forget，不等待结果
                    result.success(null);
                } catch (Throwable t) {
                    Log.e("TuyaFlutterHaSdk", "Failed to start PrewarmCameraActivity", t);
                    result.error("START_FAILED", t.getMessage(), null);
                }
                break;
            }

            case "tuyaSdkInit":
                // init method of Tuya SDK is called along with appKey and appSecret to initialize the SDK
                String appKey = call.argument("appKey");
                String appSecret = call.argument("appSecret");
                boolean isDebug = call.argument("isDebug");
                if (appKey == null || appSecret == null) {
                    result.error("MISSING_ARGS", "appKey and appSecret are required", null);
                    return;
                }
                
                // 检查 appContext 是否为 null
                if (appContext == null) {
                    // 尝试重新获取
                    if (activity != null) {
                        Context appCtx = activity.getApplicationContext();
                        if (appCtx instanceof Application) {
                            appContext = (Application) appCtx;
                        }
                    }
                }
                
                if (appContext == null) {
                    result.error("CONTEXT_NULL", 
                        "Application context is not available. Please ensure the app is fully initialized.", 
                        null);
                    return;
                }
                
                // Initialize Tuya SDK using the Application instance
                try {
                    // 1. Home SDK（与 homesdk_sample BaseApplication 一致）
                    ThingHomeSdk.init(appContext, appKey, appSecret);
                    ThingHomeSdk.setDebugMode(isDebug);

                    // 2. Optimus SDK：用于锁等扩展能力，在 demo 中也在 Application 级别初始化
                    ThingOptimusSdk.init(appContext);

                    // 3. Fresco：相机/消息等模块依赖的图片库，对齐 CameraUtils.init 内部的 Fresco 初始化
                    try {
                        Fresco.initialize(appContext);
                    } catch (Throwable t) {
                        Log.w("TuyaFlutterHaSdk", "Fresco.initialize failed or already initialized: " + t.getMessage());
                    }

                    result.success(null);
                } catch (Exception e) {
                    Log.e("TuyaFlutterHaSdk", "SDK initialization failed", e);
                    result.error("INIT_ERROR", "SDK initialization failed: " + e.getMessage(), null);
                }
                break;

            case "loginWithUid":
                // loginOrRegisterWithUid function of the Tuya SDK is called with the passed on data
                String countryCode = call.argument("countryCode");
                String uid = call.argument("uid");
                String password = call.argument("password");
                Boolean createHome = call.argument("createHome");
                if (countryCode == null || uid == null || password == null || createHome == null) {
                    result.error("MISSING_ARGS", "countryCode, uid, password, createHome required", null);
                    return;
                }
                
                // 检查 appContext 是否为 null
                if (appContext == null) {
                    if (activity != null) {
                        Context appCtx = activity.getApplicationContext();
                        if (appCtx instanceof Application) {
                            appContext = (Application) appCtx;
                        }
                    }
                }
                
                if (appContext == null) {
                    result.error("CONTEXT_NULL", 
                        "Application context is not available. Please ensure the app is fully initialized.", 
                        null);
                    return;
                }
                
                Log.i("TuyaFlutterHaSdk", "Login attempt - CountryCode: " + countryCode + ", UID: " + uid);
                Log.i("TuyaFlutterHaSdk", "CreateHome: " + createHome);
                
                // Use loginOrRegisterWithUid with ILoginCallback
                // Note: createHome parameter is not directly supported in this method signature
                // but will be handled by the SDK internally based on user registration status
                ThingHomeSdk.getUserInstance().loginOrRegisterWithUid(
                        countryCode,
                        uid,
                        password,
                        new ILoginCallback() {
                            @Override
                            public void onSuccess(User user) {
                                Log.i("TuyaFlutterHaSdk", "Login successful - UID: " + (user != null ? user.getUid() : "null"));
                                // Return minimal response - full user info can be retrieved via getCurrentUser
                                Map<String, Object> resp = new HashMap<>();
                                if (user != null) {
                                    resp.put("uid", user.getUid() != null ? user.getUid() : "");
                                    // Use correct method names from User class (matching getCurrentUser implementation)
                                    resp.put("userName", user.getUsername() != null ? user.getUsername() : "");
                                    resp.put("countryCode", user.getPhoneCode() != null ? user.getPhoneCode() : "");
                                    resp.put("timezoneId", user.getTimezoneId() != null ? user.getTimezoneId() : "");
                                }
                                result.success(resp);
                            }

                            @Override
                            public void onError(String code, String error) {
                                Log.e("TuyaFlutterHaSdk", "Login failed - Code: " + code + ", Error: " + error);
                                result.error("LOGIN_FAILED", error + " (code: " + code + ")", null);
                            }
                        }
                );
                break;
            case "checkLogin":
                // return the value of isLogin of the user instance of Tuya SDK
                try {
                    // 检查 appContext 是否为 null
                    if (appContext == null) {
                        // 尝试重新获取
                        if (activity != null) {
                            Context appCtx = activity.getApplicationContext();
                            if (appCtx instanceof Application) {
                                appContext = (Application) appCtx;
                            }
                        }
                    }
                    
                    if (appContext == null) {
                        result.error("CONTEXT_NULL", 
                            "Application context is not available. Please ensure the app is fully initialized.", 
                            null);
                        return;
                    }
                    
                    result.success(ThingHomeSdk.getUserInstance().isLogin());
                } catch (Exception e) {
                    Log.e("TuyaFlutterHaSdk", "checkLogin failed", e);
                    result.error("CHECK_LOGIN_ERROR", "Failed to check login status: " + e.getMessage(), null);
                }
                break;
            case "getCurrentUser":
                // returns the user info available in the user instance of Tuya SDK
                User user = ThingHomeSdk.getUserInstance().getUser();
                if (user != null) {
                    HashMap<String, Object> info = new HashMap<>();
                    info.put("uid", (user.getUid() != null) ? user.getUid() : "");
                    info.put("userName", (user.getUsername() != null) ? user.getUsername() : "");
                    info.put("email", (user.getEmail() != null) ? user.getEmail() : "");
                    info.put("phoneNumber", (user.getMobile() != null) ? user.getMobile() : "");
                    info.put("countryCode", (user.getPhoneCode() != null) ? user.getPhoneCode() : "");
                    info.put("regionCode", (user.getDomain().getRegionCode() != null) ? user.getDomain().getRegionCode() : "");
                    info.put("headIconUrl", (user.getHeadPic() != null) ? user.getHeadPic() : "");
                    info.put("tempUnit", String.valueOf(user.getTempUnit()));
                    info.put("timezoneId", (user.getTimezoneId() != null) ? user.getTimezoneId() : "");
                    info.put("snsNickname", (user.getNickName() != null) ? user.getNickName() : "");
                    info.put("regFrom", String.valueOf(user.getRegFrom()));

                    result.success(info);
                } else {
                    result.error("NO_USER", "No user is currently logged in", "");
                }
                break;
            case "userLogout":
                // logout function of the Tuya SDK is called
                ThingHomeSdk.getUserInstance().logout(new ILogoutCallback() {
                    @Override
                    public void onSuccess() {
                        result.success(null);

                    }

                    @Override
                    public void onError(String errorCode, String errorMsg) {
                        result.error("LOGOUT_FAILED", errorMsg, "");
                    }
                });
                break;
            case "deleteAccount":
                // cancelAccount function of the Tuya SDK is called
                ThingHomeSdk.getUserInstance().cancelAccount(new IResultCallback() {
                    @Override
                    public void onError(String code, String error) {
                        result.error("DELETE_FAILED", error, "");
                    }

                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }
                });
                break;
            case "updateTimeZone":
                // updateTimeZone function of the Tuya SDK is called
                String timezoneId = call.argument("timeZoneId");
                ThingHomeSdk.getUserInstance().updateTimeZone(
                        timezoneId,
                        new IResultCallback() {
                            @Override
                            public void onSuccess() {
                                result.success(null);
                            }

                            @Override
                            public void onError(String code, String error) {
                                result.error("UPDATE_TIMEZONE_FAILED", error, "");
                            }
                        });
                break;
            case "updateTempUnit":
                // setTempUnit of the Tuya SDK is called
                Number tempUnit = call.argument("tempUnit");
                ThingHomeSdk.getUserInstance().setTempUnit((tempUnit.intValue() == 1) ? TempUnitEnum.Celsius : TempUnitEnum.Fahrenheit, new IResultCallback() {
                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }

                    @Override
                    public void onError(@Nullable String code, @Nullable String error) {
                        result.error("UPDATE_TEMPUNIT_FAILED", error, "");
                    }
                });
                break;
            case "updateNickname":
                // updateNickName of the Tuya SDK is called
                String nickName = call.argument("nickname");
                ThingHomeSdk.getUserInstance().updateNickName(nickName,
                        new IReNickNameCallback() {
                            @Override
                            public void onSuccess() {
                                result.success(null);
                            }

                            @Override
                            public void onError(String code, String error) {
                                result.error("UPDATE_NICKNAME_FAILED", error, "");
                            }
                        });
                break;
            case "createHome":
                // return the homeId from createHome function of Tuya SDK is called
                String homeName = call.argument("name");
                String geoName = call.argument("geoName");
                double lat = call.argument("latitude");
                double lng = call.argument("longitude");
                ArrayList<String> rooms = call.argument("rooms");
                ThingHomeSdk.getHomeManagerInstance().createHome(
                        homeName,
                        lng,
                        lat,
                        (geoName != null) ? geoName : "",
                        (rooms != null) ? rooms : new ArrayList<>(),

                        new IThingHomeResultCallback() {
                            @Override
                            public void onSuccess(HomeBean bean) {
                                result.success(bean.getHomeId());
                            }

                            @Override
                            public void onError(String errorCode, String errorMsg) {
                                result.error("CREATE_HOME_FAILED", errorMsg, "");
                            }
                        }
                );
                break;
            case "getHomeList":
                // return a list of home from queryHomeList function of Tuya SDK is called
                ThingHomeSdk.getHomeManagerInstance().queryHomeList(new IThingGetHomeListCallback() {
                    @Override
                    public void onSuccess(List<HomeBean> homeBeans) {
                        ArrayList<HashMap<String, Object>> homeList = new ArrayList<>();
                        for (int i = 0; i < homeBeans.size(); i++) {
                            HashMap<String, Object> homeDetails = new HashMap<>();
                            homeDetails.put("name", homeBeans.get(i).getName());
                            homeDetails.put("background", homeBeans.get(i).getBackground());
                            homeDetails.put("lon", homeBeans.get(i).getLon());
                            homeDetails.put("lat", homeBeans.get(i).getLat());
                            homeDetails.put("geoName", homeBeans.get(i).getGeoName());
                            homeDetails.put("homeId", homeBeans.get(i).getHomeId());
                            homeDetails.put("admin", homeBeans.get(i).isAdmin());
                            homeDetails.put("inviteName", homeBeans.get(i).getInviteName());
                            homeDetails.put("homeStatus", homeBeans.get(i).getHomeStatus());
                            homeDetails.put("role", homeBeans.get(i).getRole());
                            homeDetails.put("managementStatus", homeBeans.get(i).managmentStatus());
                            List<RoomBean> roomBeans = homeBeans.get(i).getRooms();
                            Log.i("rooms size", String.valueOf(roomBeans.size()));
                            List<String> homeRoomIds = new ArrayList<>();
                            for (int j = 0; j < roomBeans.size(); j++) {
                                homeRoomIds.add(String.valueOf(roomBeans.get(j).getRoomId()));
                            }
                            homeDetails.put("roomIds", String.join(",", homeRoomIds));
                            homeList.add(homeDetails);
                        }
                        result.success(homeList);
                    }

                    @Override
                    public void onError(String errorCode, String error) {
                        result.error("GET_HOME_LIST_FAILED", error, "");
                    }
                });
                break;
            case "updateHomeInfo":
                // updateHome function of Tuya SDK is called
                Number homeId = call.argument("homeId");
                String newName = call.argument("homeName");
                String newGeoName = call.argument("geoName");
                double newLat = (call.argument("latitude") != null) ? call.argument("latitude") : 0.0;
                double newLng = (call.argument("longitude") != null) ? call.argument("longitude") : 0.0;
                //List<String> updateRooms = (List<String>) call.argument("rooms");
                //if (updateRooms == null) updateRooms = new ArrayList<>();
                Log.i("Lat", String.valueOf(newLat));
                Log.i("Lng", String.valueOf(newLng));
                ThingHomeSdk.newHomeInstance(homeId.intValue()).updateHome(newName, newLng, newLat, newGeoName, new IResultCallback() {
                    @Override
                    public void onError(String code, String error) {
                        result.error("UPDATE_HOME_FAILED", error, "");
                    }

                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }
                });
                break;
            case "deleteHome":
                // dismissHome function of the Tuya SDK is called
                Number delHomeId = call.argument("homeId");
                ThingHomeSdk.newHomeInstance(delHomeId.intValue()).dismissHome(new IResultCallback() {
                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }

                    @Override
                    public void onError(String code, String error) {
                        result.error("DELETE_HOME_FAILED", error, "");
                    }
                });
                break;
            case "getHomeDevices":
                // return a list of devices from getDeviceList function of Tuya SDK is called
                Number devHomeId = call.argument("homeId");
                ThingHomeSdk.newHomeInstance(devHomeId.intValue()).getHomeDetail(new IThingHomeResultCallback() {
                    @Override
                    public void onSuccess(HomeBean homeBean) {
                        ArrayList<DeviceBean> devices = (ArrayList) homeBean.getDeviceList();
                        ArrayList<HashMap<String, Object>> deviceList = new ArrayList<>();
                        for (int i = 0; i < devices.size(); i++) {
                            HashMap<String, Object> deviceDetails = new HashMap<>();
                            deviceDetails.put("devId", devices.get(i).getDevId());
                            deviceDetails.put("name", devices.get(i).getName());
                            deviceDetails.put("productId", devices.get(i).getProductId());
                            deviceDetails.put("uuid", devices.get(i).getUuid());
                            deviceDetails.put("iconUrl", devices.get(i).getIconUrl());
                            deviceDetails.put("isOnline", devices.get(i).getIsOnline());
                            deviceDetails.put("isCloudOnline", devices.get(i).isCloudOnline());
                            deviceDetails.put("homeId", "not available");
                            deviceDetails.put("roomId", "not available");

                            deviceDetails.put("mac", devices.get(i).getMac());
                            deviceDetails.put("bleType", "Not available");
                            deviceDetails.put("bleProtocolV", "Not available");
                            deviceDetails.put("support5G", "Not available");
                            deviceDetails.put("isProductKey", "Not available");
                            deviceDetails.put("isSupportMutliUserShare", devices.get(i).getIsShare());
                            deviceDetails.put("isActive", "Not available");
                            deviceDetails.put("dps", devices.get(i).getDps());
                            deviceList.add(deviceDetails);
                        }

                        result.success(deviceList);
                    }

                    @Override
                    public void onError(String errorCode, String errorMsg) {
                        result.error("GET_HOME_DEVICES_FAILED", errorMsg, "");
                    }
                });
                break;
            case "discoverDeviceInfo":
                // return the device info from startLeScan function of Tuya SDK
                checkPermission();
                stopAnyPairingOrScan();
                
                
                LeScanSetting scanSetting = new LeScanSetting.Builder()
                        .setTimeout(10_000) // The duration of the scanning. Unit: milliseconds.
                        .addScanType(ScanType.SINGLE) // ScanType.SINGLE: scans for Bluetooth LE devices.
                        .build();

                ThingHomeSdk.getBleOperator().startLeScan(scanSetting, new BleScanResponse() {
                    @Override
                    public void onResult(ScanDeviceBean bean) {
                        // 记录所有扫描到的设备信息，用于调试
                        Log.i("TuyaFlutterHaSdk", "发现设备: name=" + (bean.getName() != null ? bean.getName() : "null") +
                                ", productId=" + (bean.getProductId() != null ? bean.getProductId() : "null") +
                                ", uuid=" + (bean.getUuid() != null ? bean.getUuid() : "null") +
                                ", mac=" + (bean.getMac() != null ? bean.getMac() : "null") +
                                ", address=" + (bean.getAddress() != null ? bean.getAddress() : "null") +
                                ", providerName=" + (bean.getProviderName() != null ? bean.getProviderName() : "null") +
                                ", flag=" + bean.getFlag() +
                                ", deviceType=" + bean.getDeviceType());
                        
                        HashMap<String, Object> deviceDetails = new HashMap<>();
                        deviceDetails.put("name", bean.getName());
                        deviceDetails.put("productId", bean.getProductId());
                        deviceDetails.put("uuid", bean.getUuid());
                        deviceDetails.put("mac", bean.getMac());
                        deviceDetails.put("providerName", bean.getProviderName());
                        deviceDetails.put("flag", bean.getFlag());
                        deviceDetails.put("address", bean.getAddress());
                        deviceDetails.put("bleType", bean.getDeviceType());
                        deviceDetails.put("deviceType", bean.getDeviceType());
                        deviceDetails.put("configType", bean.getConfigType());
                        
                        Log.i("TuyaFlutterHaSdk", "✅ 返回设备信息给Flutter");
                        result.success(deviceDetails);
                        ThingHomeSdk.getBleOperator().stopLeScan();
                    }
                });
                
                break;
            case "getSSID":
                // Uses the WifiManager to return the ssid
                WifiManager wifiManager = (WifiManager) appContext.getSystemService(Context.WIFI_SERVICE);
                WifiInfo wifiInfo;

                wifiInfo = wifiManager.getConnectionInfo();
                if (wifiInfo.getSupplicantState() == SupplicantState.COMPLETED) {
                    String ssid = wifiInfo.getSSID();
                    result.success(ssid);
                }
                break;
            case "updateLocation":
                // setLatAndLong function of Tuya SDK is called
                double updateLat = call.argument("latitude");
                double updateLng = call.argument("longitude");
                ThingSdk.setLatAndLong(String.valueOf(updateLat), String.valueOf(updateLng));
                result.success(null);
                break;
            case "getToken":
                // returns token from getActivatorToken function of the Tuya SDK is called
                Number tokenHomeId = call.argument("homeId");
                ThingHomeSdk.getActivatorInstance().getActivatorToken(tokenHomeId.intValue(),
                        new IThingActivatorGetToken() {

                            @Override
                            public void onSuccess(String token) {
                                result.success(token);
                            }

                            @Override
                            public void onFailure(String s, String s1) {
                                result.error(s, s1, "");
                            }
                        });
                break;
            case "startConfigWiFi":
                // returns the device info from Activator start function of Tuya SDK
                String configSSID = call.argument("ssid");
                String configPassword = call.argument("password");
                String configMode = call.argument("mode");
                Number configTimeOut = call.argument("timeout");
                String configToken = call.argument("token");
                ActivatorBuilder builder = new ActivatorBuilder()
                        .setContext(activity)
                        .setSsid(configSSID)
                        .setPassword(configPassword)
                        .setActivatorModel((configMode.equals("EZ")) ? ActivatorModelEnum.THING_EZ : ActivatorModelEnum.THING_AP)
                        .setTimeOut(configTimeOut.intValue())
                        .setToken(configToken)
                        .setListener(new IThingSmartActivatorListener() {

                                         @Override
                                         public void onError(String errorCode, String errorMsg) {
                                             result.error("CONFIG_ERROR", errorMsg, "");
                                         }

                                         @Override
                                         public void onActiveSuccess(DeviceBean devResp) {
                                             HashMap<String, Object> deviceDetails = new HashMap<>();
                                             deviceDetails.put("devId", devResp.getDevId());
                                             deviceDetails.put("name", devResp.getName());
                                             deviceDetails.put("productId", devResp.getProductId());
                                             deviceDetails.put("uuid", devResp.getUuid());
                                             deviceDetails.put("iconUrl", devResp.getIconUrl());
                                             deviceDetails.put("isOnline", devResp.getIsOnline());
                                             deviceDetails.put("isCloudOnline", devResp.isCloudOnline());
                                             deviceDetails.put("homeId", "not available");
                                             deviceDetails.put("roomId", "not available");
                                             result.success(deviceDetails);
                                             Log.i("Device_Details", deviceDetails.toString());
                                         }

                                         @Override
                                         public void onStep(String step, Object data) {
                                             Log.i("ON_STEP", step + ":" + data);
                                         }
                                     }
                        );
                mThingActivator = ThingHomeSdk.getActivatorInstance().newActivator(builder);
                mThingActivator.start();
                break;
            case "stopConfigWiFi":
                // calls the Activator stop function of Tuya SDK
                if (mThingActivator != null) {
                    mThingActivator.stop();
                    result.success(null);
                } else {
                    result.error("CONFIG_ERROR", "Configurator not started", "");
                }
                break;
            case "connectDeviceAndQueryWifiList":
                // returns the wifi info from the queryDeviceConfigState function of Tuya SDK
                Number apConfigTimeOut = call.argument("timeout");
                ThingApActivatorBuilder apActivatorBuilder = new ThingApActivatorBuilder().setContext(activity);
                IThingOptimizedActivator mThingActivator = ThingHomeSdk.getActivatorInstance().newOptimizedActivator(apActivatorBuilder);

                ApQueryBuilder queryBuilder = new ApQueryBuilder.Builder().setContext(activity).setTimeout(apConfigTimeOut != null ? apConfigTimeOut.intValue() * 1000 : 120).build();
                mThingActivator.queryDeviceConfigState(queryBuilder, new IThingResultCallback<List<WiFiInfoBean>>() {
                    @Override
                    public void onSuccess(List<WiFiInfoBean> resultIB) {
                        // The list of Wi-Fi networks is obtained.
                        result.success(String.valueOf(resultIB.size()));
                        Log.i("WIFI_INFO_BEAN", String.valueOf(resultIB.size()));
                    }

                    @Override
                    public void onError(String errorCode, String errorMessage) {
                        // Failed to get the list of Wi-Fi networks.
                        result.error("WIFI_LIST_ERROR", errorMessage, "");
                    }
                });

                break;
            case "pairBleDevice":

                // returns device info from startActivator function of Tuya SDK
                checkPermission();
                stopAnyPairingOrScan();
                BleActivatorBean bleActivatorBean = new BleActivatorBean();
                Number pairHomeId = call.argument("homeId");
                if (pairHomeId != null) bleActivatorBean.homeId = pairHomeId.intValue();
                bleActivatorBean.uuid = call.argument("uuid");
                bleActivatorBean.productId = call.argument("productId"); // The product ID.

                Number pairDeviceType = call.argument("deviceType");
                if (pairDeviceType != null && pairDeviceType.intValue() != 0) bleActivatorBean.deviceType = pairDeviceType.intValue();
                String pairAddress = call.argument("address");
                if (pairAddress != null) bleActivatorBean.address = pairAddress;

                Number pairDeviceTimeout = call.argument("timeout");
                if (pairDeviceTimeout != null && pairDeviceTimeout.intValue() > 0) bleActivatorBean.timeout = pairDeviceTimeout.intValue() * 1000;
                Number pairDeviceFlag = call.argument("flag");
                if (pairDeviceFlag != null && pairDeviceFlag.intValue() == 9) {
                    result.error("BLE_UNPAIRABLE",
                            "Beacon (flag 9) – pairing not supported", null);
                    return;
                }
                Log.i("Pairing homeId", String.valueOf(pairHomeId));
                mBleActivator = ThingHomeSdk.getActivator().newBleActivator();
                mBleActivator.startActivator(bleActivatorBean, new IBleActivatorListener() {
                    @Override
                    public void onSuccess(DeviceBean deviceBean) {
                        Log.i("Pairing success", deviceBean.getDevId());
                        HashMap<String, Object> deviceDetails = new HashMap<>();
                        deviceDetails.put("devId", deviceBean.getDevId());
                        deviceDetails.put("name", deviceBean.getName());
                        deviceDetails.put("productId", deviceBean.getProductId());
                        deviceDetails.put("uuid", deviceBean.getUuid());
                        deviceDetails.put("iconUrl", deviceBean.getIconUrl());
                        deviceDetails.put("isOnline", deviceBean.getIsOnline());
                        deviceDetails.put("isCloudOnline", deviceBean.isCloudOnline());
                        deviceDetails.put("homeId", "not available");
                        deviceDetails.put("roomId", "not available");
                        deviceDetails.put("mac", deviceBean.getMac());
                        deviceDetails.put("bleType", "Not available");
                        deviceDetails.put("bleProtocolV", "Not available");
                        deviceDetails.put("support5G", "Not available");
                        deviceDetails.put("isProductKey", "Not available");
                        deviceDetails.put("isSupportMutliUserShare", deviceBean.getIsShare());
                        deviceDetails.put("isActive", "Not available");
                        deviceDetails.put("dps", deviceBean.getDps());
                        result.success(deviceDetails);
                        stopAnyPairingOrScan();
                    }

                    @Override
                    public void onFailure(int code, String msg, Object handle) {
                        // Failed to pair the device.
                        Log.i("Pairing failure", msg);
                        result.error("BLE_QUERY_FAILED", msg, "");
                        stopAnyPairingOrScan();
                    }
                });
                break;
            case "startComboPairing":

                // returns device info from startActivator function of Tuya SDK
                checkPermission();
                stopAnyPairingOrScan();
                MultiModeActivatorBean multiModeActivatorBean = new MultiModeActivatorBean();
                multiModeActivatorBean.uuid = call.argument("uuid"); // The UUID of the device.
                multiModeActivatorBean.ssid = call.argument("ssid"); // The SSID of the target Wi-Fi network.
                multiModeActivatorBean.pwd = call.argument("password"); // The password of the target Wi-Fi network.
                String cPairProductId = call.argument("productId");
                Number cPairHomeId = call.argument("homeId");
                if (cPairHomeId != null) multiModeActivatorBean.homeId = cPairHomeId.longValue(); // The value of `homeId` for the current home.

                Number cPairTimeout = call.argument("timeout");
                if (cPairTimeout != null && cPairTimeout.intValue() > 0) multiModeActivatorBean.timeout = cPairTimeout.intValue() * 1000; // The timeout value.

                multiModeActivatorBean.token = call.argument("token"); // The pairing token.
                Number cPairDeviceType = call.argument("deviceType");
                if (cPairDeviceType != null) multiModeActivatorBean.deviceType = cPairDeviceType.intValue(); // The type of device.

                String cPairAddress = call.argument("address");
                if (cPairAddress != null) {
                    multiModeActivatorBean.address = cPairAddress; // The IP address of the device.
                    multiModeActivatorBean.mac = cPairAddress;
                }
                Number cPairDeviceFlag = call.argument("flag");
                if (cPairDeviceFlag != null && cPairDeviceFlag.intValue() == 9) {
                    result.error("BLE_UNPAIRABLE",
                            "Beacon (flag 9) – pairing not supported", null);
                    return;
                }
                mComboActivator = ThingHomeSdk.getActivator().newMultiModeActivator();
                mComboActivator.startActivator(multiModeActivatorBean, new IMultiModeActivatorListener() {
                    @Override
                    public void onSuccess(DeviceBean deviceBean) {
                        HashMap<String, Object> deviceDetails = new HashMap<>();
                        deviceDetails.put("devId", deviceBean.getDevId());
                        deviceDetails.put("name", deviceBean.getName());
                        deviceDetails.put("productId", deviceBean.getProductId());
                        deviceDetails.put("uuid", deviceBean.getUuid());
                        deviceDetails.put("iconUrl", deviceBean.getIconUrl());
                        deviceDetails.put("isOnline", deviceBean.getIsOnline());
                        deviceDetails.put("isCloudOnline", deviceBean.isCloudOnline());
                        deviceDetails.put("homeId", "not available");
                        deviceDetails.put("roomId", "not available");
                        deviceDetails.put("mac", deviceBean.getMac());
                        deviceDetails.put("bleType", "Not available");
                        deviceDetails.put("bleProtocolV", "Not available");
                        deviceDetails.put("support5G", "Not available");
                        deviceDetails.put("isProductKey", "Not available");
                        deviceDetails.put("isSupportMutliUserShare", deviceBean.getIsShare());
                        deviceDetails.put("isActive", "Not available");
                        result.success(deviceDetails);
                    }

                    @Override
                    public void onFailure(int code, String msg, Object handle) {
                        result.error("COMBO_PAIR_FAILED", msg, "");
                        stopAnyPairingOrScan();
                    }
                });
                break;
            case "initDevice":
                // calls the registerDevListener function of Tuya SDK
                String initDeviceId = call.argument("devId");
                Log.i("TuyaFlutterHaSdk", "初始化设备: " + initDeviceId);
                IThingDevice mDevice = ThingHomeSdk.newDeviceInstance(initDeviceId);
                mDevice.registerDevListener(new IDevListener() {
                    @Override
                    public void onDpUpdate(String devId, String dpStr) {
                        if (eventSink != null) {
                            eventSink.success("onDpUpdate:" + dpStr);
                        }
                    }

                    @Override
                    public void onRemoved(String devId) {
                        if (eventSink != null) {
                            eventSink.success("onRemoved");
                        }
                    }

                    @Override
                    public void onStatusChanged(String devId, boolean online) {
                        if (eventSink != null) {
                            eventSink.success("onStatusChanged:" + String.valueOf(online));
                        }
                    }

                    @Override
                    public void onNetworkStatusChanged(String devId, boolean status) {
                        if (eventSink != null) {
                            eventSink.success("onNetworkStatusChanged:" + String.valueOf(status));
                        }
                    }

                    @Override
                    public void onDevInfoUpdate(String devId) {
                        if (eventSink != null) {
                            eventSink.success("onDevInfoUpdate");
                        }
                    }
                });
                Log.i("TuyaFlutterHaSdk", "✅ 设备初始化完成: " + initDeviceId);
                result.success(null);
                break;
            case "queryDeviceInfo":
                // returns device information from DeviceBean
                String queryDeviceId = call.argument("devId");
                List<String> dpIds = call.argument("dpIds");
                
                try {
                    // 从 DataInstance 获取设备信息
                    DeviceBean deviceBean = ThingHomeSdk.getDataInstance().getDeviceBean(queryDeviceId);
                    if (deviceBean == null) {
                        result.error("DEVICE_INFO_FAILED", "Device not found", null);
                        return;
                    }
                    
                    // 构建设备信息 Map（只使用 DeviceBean 中确定存在的方法）
                    Map<String, Object> deviceInfo = new HashMap<>();
                    deviceInfo.put("devId", deviceBean.getDevId());
                    deviceInfo.put("name", deviceBean.getName());
                    deviceInfo.put("productId", deviceBean.getProductId());
                    deviceInfo.put("uuid", deviceBean.getUuid());
                    deviceInfo.put("iconUrl", deviceBean.getIconUrl());
                    deviceInfo.put("isOnline", deviceBean.getIsOnline());
                    deviceInfo.put("isCloudOnline", deviceBean.isCloudOnline());
                    deviceInfo.put("mac", deviceBean.getMac());
                    deviceInfo.put("isSupportMutliUserShare", deviceBean.getIsShare());
                    // 添加 DPS 信息（如果可用）
                    if (deviceBean.getDps() != null) {
                        deviceInfo.put("dps", deviceBean.getDps());
                    }
                    
                    // 如果有 dps 参数，尝试获取 DP 信息
                    if (dpIds != null && !dpIds.isEmpty()) {
                        IThingDevice queryDevice = ThingHomeSdk.newDeviceInstance(queryDeviceId);
                        // 注册监听器（如果需要）
                        queryDevice.registerDevListener(new IDevListener() {
                            @Override
                            public void onDpUpdate(String devId, String dpStr) {
                                if (eventSink != null) {
                                    eventSink.success("onDpUpdate:" + dpStr);
                                }
                            }

                            @Override
                            public void onRemoved(String devId) {
                                if (eventSink != null) {
                                    eventSink.success("onRemoved");
                                }
                            }

                            @Override
                            public void onStatusChanged(String devId, boolean online) {
                                if (eventSink != null) {
                                    eventSink.success("onStatusChanged:" + String.valueOf(online));
                                }
                            }

                            @Override
                            public void onNetworkStatusChanged(String devId, boolean status) {
                                if (eventSink != null) {
                                    eventSink.success("onNetworkStatusChanged:" + String.valueOf(status));
                                }
                            }

                            @Override
                            public void onDevInfoUpdate(String devId) {
                                if (eventSink != null) {
                                    eventSink.success("onDevInfoUpdate");
                                }
                            }
                        });
                        
                        // 尝试获取 DP 列表（异步操作，但不阻塞返回基本信息）
                        queryDevice.getDpList(dpIds, new IResultCallback() {
                            @Override
                            public void onError(String code, String error) {
                                Log.w("TuyaFlutterHaSdk", "获取 DP 列表失败: " + error);
                            }

                            @Override
                            public void onSuccess() {
                                Log.i("TuyaFlutterHaSdk", "DP 列表获取成功");
                            }
                        });
                    }
                    
                    // 返回设备信息
                    result.success(deviceInfo);
                } catch (Exception e) {
                    Log.e("TuyaFlutterHaSdk", "获取设备信息失败: " + e.getMessage());
                    result.error("DEVICE_INFO_FAILED", e.getMessage(), null);
                }

                break;
            case "renameDevice":
                // calls renameDevice of Tuya SDK
                String renameDeviceId = call.argument("devId");
                String renameName = call.argument("name");
                IThingDevice renameDevice = ThingHomeSdk.newDeviceInstance(renameDeviceId);
                renameDevice.renameDevice(renameName, new IResultCallback() {
                    @Override
                    public void onError(String code, String error) {
                        result.error("RENAME_FAILED", error, "");
                    }

                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }
                });

                break;
            case "removeDevice":
                // removeDevice function of Tuya SDK is called
                String removeDeviceId = call.argument("devId");
                IThingDevice removeDevice = ThingHomeSdk.newDeviceInstance(removeDeviceId);
                removeDevice.removeDevice(new IResultCallback() {
                    @Override
                    public void onError(String errorCode, String errorMsg) {
                        result.error("REMOVE_DEVICE_FAILED", errorMsg, "");
                    }

                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }
                });

                break;
            case "restoreFactoryDefaults":
                // resetFactory function of Tuya SDK is called
                String restoreDeviceId = call.argument("devId");
                IThingDevice restoreDevice = ThingHomeSdk.newDeviceInstance(restoreDeviceId);
                restoreDevice.resetFactory(new IResultCallback() {
                    @Override
                    public void onError(String errorCode, String errorMsg) {
                        result.error("RESET_FAILED", errorMsg, "");
                    }

                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }
                });

                break;
            case "queryDeviceWiFiStrength":
                // returns data from requestWifiSignal function of Tuya SDK
                String strengthDeviceId = call.argument("devId");
                IThingDevice strengthDevice = ThingHomeSdk.newDeviceInstance(strengthDeviceId);
                // 使用标志确保 result 只被调用一次
                final boolean[] resultCalled = {false};
                strengthDevice.requestWifiSignal(new WifiSignalListener() {

                    @Override
                    public void onSignalValueFind(String signal) {
                        synchronized (resultCalled) {
                            if (!resultCalled[0]) {
                                resultCalled[0] = true;
                                result.success(signal);
                            } else {
                                Log.w("TuyaFlutterHaSdk", "⚠️ queryDeviceWiFiStrength result already called, ignoring duplicate callback");
                            }
                        }
                    }

                    @Override
                    public void onError(String errorCode, String errorMsg) {
                        synchronized (resultCalled) {
                            if (!resultCalled[0]) {
                                resultCalled[0] = true;
                                result.error("QUERY_STRENGTH_FAILED", errorMsg, "");
                            } else {
                                Log.w("TuyaFlutterHaSdk", "⚠️ queryDeviceWiFiStrength result already called, ignoring duplicate error");
                            }
                        }
                    }
                });
                break;
            case "querySubDeviceList":
                // This functionality not available in Android
                result.error("Sub Device List", "Not available", "");
                break;
            case "getRoomList":
                // retuns a list of room from queryRoomList function of Tuya SDK
                Number getRoomsHomeId = call.argument("homeId");
                ThingHomeSdk.newHomeInstance(getRoomsHomeId.intValue()).queryRoomList(new IThingGetRoomListCallback() {
                    @Override
                    public void onSuccess(List<RoomBean> roomBeans) {
                        Log.i("rooms", String.valueOf(roomBeans.size()));
                        ArrayList<HashMap<String, String>> homeList = new ArrayList<>();

                        for (int j = 0; j < roomBeans.size(); j++) {
                            HashMap<String, String> roomsList = new HashMap<>();
                            roomsList.put("id", String.valueOf(roomBeans.get(j).getRoomId()));
                            roomsList.put("name", String.valueOf(roomBeans.get(j).getName()));
                            //homeRoomIds.add(String.valueOf(roomBeans.getRoomId()));
                            homeList.add(roomsList);
                        }
                        Log.i("rooms added", String.valueOf(homeList.size()));
                        //Log.i("homeList",String.join(",",homeList));
                        result.success(homeList);
                    }

                    @Override
                    public void onError(String errorCode, String errorMsg) {
                        result.error("ADD_ROOM_FAILED", errorMsg, "");
                    }
                });
                break;
            case "addRoom":
                // addRoom function of Tuya SDK is called
                Number addRoomHomeId = call.argument("homeId");
                String addRoomName = call.argument("roomName");
                ThingHomeSdk.newHomeInstance(addRoomHomeId.intValue()).addRoom(addRoomName, new IThingRoomResultCallback() {
                    @Override
                    public void onSuccess(RoomBean bean) {
                        result.success(null);
                    }

                    @Override
                    public void onError(String errorCode, String errorMsg) {
                        result.error("ADD_ROOM_FAILED", errorMsg, "");
                    }
                });

                break;
            case "removeRoom":
                // removeRoom function of Tuya SDK is called
                Number remRoomHomeId = call.argument("homeId");
                Number remRoomId = call.argument("roomId");
                ThingHomeSdk.newHomeInstance(remRoomHomeId.intValue()).removeRoom(remRoomId.intValue(), new IResultCallback() {
                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }

                    @Override
                    public void onError(String code, String error) {
                        result.error("REMOVE_ROOM_FAILED", error, "");
                    }
                });

                break;
            case "sortRooms":
                // sortRoom function of Tuya SDK is called
                Number sortRoomHomeId = call.argument("homeId");
                List<Long> sortRoomIds = call.argument("roomIds");
                ThingHomeSdk.newHomeInstance(sortRoomHomeId.intValue()).sortRoom(sortRoomIds, new IResultCallback() {
                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }

                    @Override
                    public void onError(String code, String error) {
                        result.error("SORT_ROOM_FAILED", error, "");
                    }
                });

                break;
            case "updateRoomName":
                // updateRoom function of Tuya SDK is called
                Number updateRoomId = call.argument("roomId");
                String updateRoomName = call.argument("roomName");
                ThingHomeSdk.newRoomInstance(updateRoomId.intValue()).updateRoom(updateRoomName, new IResultCallback() {
                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }

                    @Override
                    public void onError(String code, String error) {
                        result.error("UPDATE_ROOM_FAILED", error, "");
                    }
                });

                break;
            case "addDeviceToRoom":
                // addDevie function of Tuya SDK is called
                Number addDevRoomId = call.argument("roomId");
                String addDevRoomDevId = call.argument("devId");
                ThingHomeSdk.newRoomInstance(addDevRoomId.intValue()).addDevice(addDevRoomDevId, new IResultCallback() {
                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }

                    @Override
                    public void onError(String code, String error) {
                        result.error("ADD_DEVICE_FAILED", error, "");
                    }
                });

                break;
            case "removeDeviceFromRoom":
                // removeDevice function of Tuya SDK is called
                Number remDevRoomId = call.argument("roomId");
                String remDevRoomDevId = call.argument("devId");
                ThingHomeSdk.newRoomInstance(remDevRoomId.intValue()).removeDevice(remDevRoomDevId, new IResultCallback() {
                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }

                    @Override
                    public void onError(String code, String error) {
                        result.error("REMOVE_DEVICE_FAILED", error, "");
                    }
                });

                break;
            case "addGroupToRoom":
                // addGroup function of Tuya SDK is called
                Number addGroupRoomId = call.argument("roomId");
                Number addGroupId = call.argument("groupId");
                ThingHomeSdk.newRoomInstance(addGroupRoomId.intValue()).addGroup(addGroupId.intValue(), new IResultCallback() {
                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }

                    @Override
                    public void onError(String code, String error) {
                        result.error("ADD_GROUP_FAILED", error, "");
                    }
                });

                break;
            case "removeGroupFromRoom":
                // removeGroup function of Tuya SDK is called
                Number remGroupRoomId = call.argument("roomId");
                Number remGroupId = call.argument("groupId");
                ThingHomeSdk.newRoomInstance(remGroupRoomId.intValue()).removeGroup(remGroupId.longValue(), new IResultCallback() {
                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }

                    @Override
                    public void onError(String code, String error) {
                        result.error("REMOVE_GROUP_FAILED", error, "");
                    }
                });

                break;
            case "unlockBLELock":
            case "lockBLELock":
            case "unlockWifiLock":
            case "dynamicWifiLockPassword":
                // 锁相关功能已从精简版插件中移除
                result.error("LOCK_FEATURE_REMOVED", "Lock features are not supported in this build.", null);
                break;
            case "checkIfMatter":
                //isMatter function of Tuya SDK is called
                String checkMatterDevId = call.argument("devId");
                DeviceBean deviceBean = ThingHomeSdk.getDataInstance().getDeviceBean(checkMatterDevId);
                if(deviceBean != null) {
                    boolean isMatter = deviceBean.isMatter();
                    result.success(isMatter);
                }else {
                    result.error("MATTER_CHECK_ERROR","Device not initiated","");
                }
                break;
            case "controlMatter":
                //publishDps function of Tuya SDK is called
                String setDpDevId = call.argument("devId");
                HashMap<String, Object> setDps = (HashMap<String, Object>) call.argument("dps");

                StringBuilder mapAsString = new StringBuilder("{");
                for (String key : setDps.keySet()) {
                    mapAsString.append('"'+key + "\":" + setDps.get(key) + ", ");
                }
                mapAsString.delete(mapAsString.length()-2, mapAsString.length()).append("}");
                Log.i("dps",mapAsString.toString());
                IThingDevice dpDevice = ThingHomeSdk.newDeviceInstance(setDpDevId);
                dpDevice.publishDps(mapAsString.toString(), new IResultCallback() {
                    @Override
                    public void onError(String code, String error) {
                        result.error("SET_DEVICE_CONFIG_FAILED", error, "");
                        // The error code 11001 is returned due to the following causes:
                        // 1: Data has been sent in an incorrect format. For example, the data of String type has been sent in the format of Boolean data.
                        // 2: Read-only DPs cannot be sent. For more information, see SchemaBean getMode. `ro` indicates the read-only type.
                        // 3: Data of Raw type has been sent in a format rather than a hexadecimal string.
                    }
                    @Override
                    public void onSuccess() {
                        result.success(null);
                    }
                });
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void checkPermission() {
        if (ContextCompat.checkSelfPermission(activity, "android.permission.BLUETOOTH_SCAN") != 0 || ContextCompat.checkSelfPermission(activity, "android.permission.ACCESS_FINE_LOCATION") != 0 || ContextCompat.checkSelfPermission(activity, "android.permission.BLUETOOTH_CONNECT") != 0) {
            ActivityCompat.requestPermissions(activity, new String[]{"android.permission.BLUETOOTH_SCAN", "android.permission.ACCESS_FINE_LOCATION", "android.permission.BLUETOOTH_CONNECT"}, 1001);
        }
    }
}
