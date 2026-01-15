package us.kpmsg.tuya_flutter_ha_sdk;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

import com.thingclips.smart.home.sdk.callback.IThingHomeResultCallback;
import com.thingclips.smart.home.sdk.bean.HomeBean;
import com.thingclips.smart.sdk.bean.DeviceBean;
import com.thingclips.smart.home.sdk.ThingHomeSdk;
import com.thingclips.smart.android.camera.sdk.ThingIPCSdk;
import com.thingclips.smart.android.camera.sdk.api.IThingIPCCore;
import com.thingclips.smart.sdk.api.IThingDevice;
import com.thingclips.smart.android.camera.sdk.api.IThingCameraMessage;
import com.thingclips.smart.android.camera.sdk.api.IThingIPCMsg;
import com.thingclips.smart.home.sdk.callback.IThingResultCallback;
import com.thingclips.smart.android.camera.sdk.api.IThingIPCDpHelper;
import com.thingclips.smart.sdk.api.IResultCallback;
import com.thingclips.smart.camera.middleware.widget.ThingCameraView;
import com.thingclips.smart.camera.middleware.p2p.IThingSmartCameraP2P;
import com.thingclips.smart.camera.ipccamerasdk.p2p.ICameraP2P;
import com.thingclips.smart.camera.middleware.widget.AbsVideoViewCallback;
import com.thingclips.smart.camera.camerasdk.thingplayer.callback.OperationDelegateCallBack;
import com.thingclips.smart.android.camera.sdk.bean.IPCSnapshotConfig;
import com.thingclips.smart.sdk.api.IThingDataCallback;
import com.thingclips.smart.sdk.bean.message.MessageListBean;
import com.thingclips.smart.sdk.bean.push.PushType;
import com.thingclips.smart.android.device.bean.SchemaBean;
import com.facebook.drawee.backends.pipeline.Fresco;

import android.app.Application;
import android.content.Context;
import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import android.view.View;
import android.widget.TextView;
import android.os.Build;
import android.os.Environment;

import androidx.annotation.Nullable;

import android.view.LayoutInflater;
import android.view.View;
import android.util.Log;

import java.io.File;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.TimeZone;
import java.nio.ByteBuffer;

public class TuyaCameraPlugin implements FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, Application.ActivityLifecycleCallbacks {
    private MethodChannel channel;
    private Application appContext;
    private Activity activity;
    private EventChannel eventChannel;
    private EventSink eventSink;
    private TuyaCameraViewFactory tuyaCameraViewFactory;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        appContext = (Application) binding.getApplicationContext();
        // 注册全局 Activity 生命周期回调，用于标记前后台状态
        try {
            appContext.registerActivityLifecycleCallbacks(this);
        } catch (Throwable t) {
            Log.w("CAMERA", "registerActivityLifecycleCallbacks failed", t);
        }
        channel = new MethodChannel(binding.getBinaryMessenger(), "tuya_flutter_ha_sdk/camera");
        channel.setMethodCallHandler(this);
        eventChannel = new EventChannel(binding.getBinaryMessenger(), "tuya_flutter_ha_sdk/notifications");
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
                Log.i("CAMERA", "✅ EventChannel 监听已启动");
                // 将 EventSink 传递给 TuyaCameraViewFactory
                if (tuyaCameraViewFactory != null) {
                    tuyaCameraViewFactory.setEventSink(eventSink);
                }
            }

            @Override
            public void onCancel(Object arguments) {
                Log.i("CAMERA", "⚠️ EventChannel 监听已取消");
                eventSink = null;
                // 清除 TuyaCameraViewFactory 的 EventSink
                if (tuyaCameraViewFactory != null) {
                    tuyaCameraViewFactory.setEventSink(null);
                }
            }
        });
    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
        activity = activityPluginBinding.getActivity();
    }

    @Override
    public void onReattachedToActivityForConfigChanges(ActivityPluginBinding activityPluginBinding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        if (appContext != null) {
            try {
                appContext.unregisterActivityLifecycleCallbacks(this);
            } catch (Throwable t) {
                Log.w("CAMERA", "unregisterActivityLifecycleCallbacks failed", t);
            }
        }
    }

    public void registerPlugin(FlutterPluginBinding binding) {
        appContext = (Application) binding.getApplicationContext();
        // 确保通过旧的 registerPlugin 路径也能注册生命周期回调
        try {
            appContext.registerActivityLifecycleCallbacks(this);
        } catch (Throwable t) {
            Log.w("CAMERA", "registerActivityLifecycleCallbacks (legacy) failed", t);
        }
        channel = new MethodChannel(binding.getBinaryMessenger(), "tuya_flutter_ha_sdk/camera");
        channel.setMethodCallHandler(this);
        eventChannel = new EventChannel(binding.getBinaryMessenger(), "tuya_flutter_ha_sdk/notifications");
        eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                eventSink = events;
                Log.i("CAMERA", "✅ EventChannel 监听已启动 (registerPlugin)");
                // 将 EventSink 传递给 TuyaCameraViewFactory
                if (tuyaCameraViewFactory != null) {
                    tuyaCameraViewFactory.setEventSink(eventSink);
                }
            }

            @Override
            public void onCancel(Object arguments) {
                Log.i("CAMERA", "⚠️ EventChannel 监听已取消 (registerPlugin)");
                eventSink = null;
                // 清除 TuyaCameraViewFactory 的 EventSink
                if (tuyaCameraViewFactory != null) {
                    tuyaCameraViewFactory.setEventSink(null);
                }
            }
        });
        tuyaCameraViewFactory = new TuyaCameraViewFactory();
        binding.getPlatformViewRegistry().registerViewFactory("tuya_camera_view", tuyaCameraViewFactory);
    }

    // ===== Application.ActivityLifecycleCallbacks 实现，用于标记前后台 =====

    @Override
    public void onActivityCreated(@NonNull Activity activity, Bundle savedInstanceState) {
    }

    @Override
    public void onActivityStarted(@NonNull Activity activity) {
        // 任意 Activity 启动时认为 app 进入前台
        try {
            ThingUtil.setAppForeground(true);
        } catch (Throwable t) {
            Log.w("CAMERA", "ThingUtil.setAppForeground(true) in onActivityStarted failed", t);
        }
    }

    @Override
    public void onActivityResumed(@NonNull Activity activity) {
    }

    @Override
    public void onActivityPaused(@NonNull Activity activity) {
    }

    @Override
    public void onActivityStopped(@NonNull Activity activity) {
        // 所有 Activity 停止时，最终会收到 onActivityStopped，可在此标记离开前台
        try {
            ThingUtil.setAppForeground(false);
        } catch (Throwable t) {
            Log.w("CAMERA", "ThingUtil.setAppForeground(false) in onActivityStopped failed", t);
        }
    }

    @Override
    public void onActivitySaveInstanceState(@NonNull Activity activity, @NonNull Bundle outState) {
    }

    @Override
    public void onActivityDestroyed(@NonNull Activity activity) {
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "listCameras":
                //isIPCDevice function of the Tuya SDK is called
                Number devHomeId = call.argument("homeId");
                ThingHomeSdk.newHomeInstance(devHomeId.intValue()).getHomeDetail(new IThingHomeResultCallback() {
                    @Override
                    public void onSuccess(HomeBean homeBean) {
                        IThingIPCCore cameraInstance = ThingIPCSdk.getCameraInstance();

                        ArrayList<DeviceBean> devices = (ArrayList) homeBean.getDeviceList();
                        ArrayList<HashMap<String, Object>> deviceList = new ArrayList<>();
                        for (int i = 0; i < devices.size(); i++) {
                            HashMap<String, Object> deviceDetails = new HashMap<>();
                            if (cameraInstance != null) {

                                if (cameraInstance.isIPCDevice(devices.get(i).getDevId())) {
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
                            }


                        }

                        result.success(deviceList);
                    }

                    @Override
                    public void onError(String errorCode, String errorMsg) {
                        result.error("LIST_CAMERAS_FAILED", errorMsg, "");
                    }
                });
                break;
            case "getCameraCapabilities":
                //getP2PType function of Tuya SDK is called
                String devId = call.argument("deviceId");
                IThingIPCCore cameraInstance = ThingIPCSdk.getCameraInstance();
                HashMap<String, Object> deviceDetails = new HashMap<>();

                if (cameraInstance != null) {
                    var p2pType = cameraInstance.getP2PType(devId);
                    DeviceBean mDevice = ThingHomeSdk.getDataInstance().getDeviceBean(devId);
                    deviceDetails.put("isCamera", true);
                    deviceDetails.put("p2pType", String.valueOf(p2pType));
                    deviceDetails.put("uuid", mDevice.getUuid());
                    deviceDetails.put("productId", mDevice.getProductId());
                    deviceDetails.put("deviceName", mDevice.getName());
                    deviceDetails.put("isOnline", mDevice.getIsOnline());
                    deviceDetails.put("isCloudOnline", mDevice.isCloudOnline());
                    result.success(deviceDetails);
                }

                break;
            case "startLiveStream":
                //startCamera function of Platform view is called
                result.success(null);
                tuyaCameraViewFactory.startCamera();

                break;
            case "stopLiveStream":
                //stopCamera function of Platform view is called
                tuyaCameraViewFactory.stopCamera();
                result.success(null);
                break;
            case "connectP2P":
                String connectDevId = call.argument("devId");
                if (tuyaCameraViewFactory != null && connectDevId != null) {
                    tuyaCameraViewFactory.connectP2P(connectDevId);
                }
                result.success(null);
                break;
            case "disconnectP2P":
                if (tuyaCameraViewFactory != null) {
                    tuyaCameraViewFactory.disconnectP2P();
                }
                result.success(null);
                break;
            case "startPreview":
                Number clarity = call.argument("clarity");
                int clarityValue = clarity != null ? clarity.intValue() : 0;
                if (tuyaCameraViewFactory != null) {
                    tuyaCameraViewFactory.startPreview(clarityValue);
                }
                result.success(null);
                break;
            case "stopPreview":
                if (tuyaCameraViewFactory != null) {
                    tuyaCameraViewFactory.stopPreview();
                }
                result.success(null);
                break;
            case "startTalk":
                if (tuyaCameraViewFactory != null) {
                    tuyaCameraViewFactory.startTalk();
                }
                result.success(null);
                break;
            case "stopTalk":
                if (tuyaCameraViewFactory != null) {
                    tuyaCameraViewFactory.stopTalk();
                }
                result.success(null);
                break;
            case "snapshot":
                String snapshotDir = call.argument("directory");
                if (tuyaCameraViewFactory != null) {
                    tuyaCameraViewFactory.snapshot(snapshotDir, result);
                } else {
                    result.error("CAMERA_VIEW_NOT_READY", "TuyaCameraViewFactory is null", null);
                }
                break;
            case "snapshotWithConfig":
                String cfgDir = call.argument("directory");
                String fileName = call.argument("fileName");
                Number rotateModeNum = call.argument("rotateMode");
                Boolean saveToAlbum = call.argument("saveToAlbum");
                int rotateMode = rotateModeNum != null ? rotateModeNum.intValue() : 0;
                boolean saveAlbum = saveToAlbum != null && saveToAlbum;
                if (tuyaCameraViewFactory != null) {
                    tuyaCameraViewFactory.snapshotWithConfig(cfgDir, fileName, rotateMode, saveAlbum, result);
                } else {
                    result.error("CAMERA_VIEW_NOT_READY", "TuyaCameraViewFactory is null", null);
                }
                break;
            case "setLoudSpeakerStatus":
                Boolean speakerEnable = call.argument("enable");
                boolean enable = speakerEnable != null && speakerEnable;
                if (tuyaCameraViewFactory != null) {
                    tuyaCameraViewFactory.setLoudSpeakerStatus(enable);
                }
                result.success(null);
                break;
            case "setMute":
                Number muteStatus = call.argument("status");
                int status = muteStatus != null ? muteStatus.intValue() : 0;
                if (tuyaCameraViewFactory != null) {
                    tuyaCameraViewFactory.setMute(status);
                }
                result.success(null);
                break;
            case "saveVideoToGallery":
                // startLocalRecording of Tuya SDK is called
                String picPath = call.argument("filePath");
                tuyaCameraViewFactory.startLocalRecording(picPath);
                result.success(null);
                break;
            case "stopSaveVideoToGallery":
                // stopLocalRecording of Tuya SDK is called
                tuyaCameraViewFactory.stopLocalRecording();
                result.success(null);
                break;
            case "getDeviceAlerts":
                //queryMotionDaysByMonth function is called
                String alertsDevId = call.argument("deviceId");
                Number alertYear = call.argument("year");
                Number alertMonth = call.argument("month");
                IThingCameraMessage cameraMessage;

                IThingIPCMsg message = ThingIPCSdk.getMessage();
                if (message != null) {
                    cameraMessage = message.createCameraMessage();
                    cameraMessage.queryMotionDaysByMonth(alertsDevId, alertYear.intValue(), alertMonth.intValue(), TimeZone.getDefault().getID(), new IThingResultCallback<List<String>>() {
                        @Override
                        public void onSuccess(List<String> resultMsg) {
                            result.success(resultMsg);
                        }

                        @Override
                        public void onError(String errorCode, String errorMessage) {
                            result.error("GET_DEVICE_ALERTS_FAILED", errorMessage, "");
                        }
                    });
                }

                break;

            case "setDeviceDpConfigs":
                // publishDps function of Tuya SDK is called
                String setDpDevId = call.argument("deviceId");
                HashMap<String, Object> setDps = (HashMap<String, Object>) call.argument("dps");

                // 根据设备 Schema 和当前 DPS 规范化每个 DP 的值
                DeviceBean schemaDevice = ThingHomeSdk.getDataInstance().getDeviceBean(setDpDevId);
                Map<String, SchemaBean> schemaMap = schemaDevice != null ? schemaDevice.getSchemaMap() : null;
                Map<String, Object> currentDps = schemaDevice != null ? schemaDevice.getDps() : null;

                StringBuilder mapAsString = new StringBuilder("{");
                for (String key : setDps.keySet()) {
                    Object raw = setDps.get(key);
                    Object normalized = raw;

                    SchemaBean schemaBean = null;
                    String schemaType = null; // bool / enum / value / string / raw
                    if (schemaMap != null) {
                        schemaBean = schemaMap.get(key);
                        if (schemaBean != null) {
                            schemaType = schemaBean.getType();
                        }
                    }

                    boolean treatAsBool = false;
                    // 1) schema 明确标记为 bool
                    if ("bool".equalsIgnoreCase(schemaType)) {
                        treatAsBool = true;
                    }
                    // 2) 即使 schema 没写 bool，只要当前 dps 中是 Boolean，也按 bool 处理
                    if (!treatAsBool && currentDps != null && currentDps.get(key) instanceof Boolean) {
                        treatAsBool = true;
                    }

                    if (treatAsBool) {
                        // 规范化为布尔类型，兼容 0/1、"0"/"1"、"true"/"false"
                        boolean boolVal = false;
                        if (raw instanceof Boolean) {
                            boolVal = (Boolean) raw;
                        } else if (raw instanceof Number) {
                            boolVal = ((Number) raw).intValue() != 0;
                        } else if (raw instanceof String) {
                            String s = ((String) raw).toLowerCase();
                            boolVal = "1".equals(s) || "true".equals(s);
                        }
                        normalized = Boolean.valueOf(boolVal);
                    } else if ("value".equalsIgnoreCase(schemaType)) {
                        // 数值型 DP（如亮度 158）：发送为数字，避免被 SDK 当成字符串导致类型错误
                        if (raw instanceof Number) {
                            normalized = raw;
                        } else if (raw instanceof String) {
                            String s = (String) raw;
                            try {
                                // 优先按整数解析，失败再按浮点数
                                if (s.contains(".")) {
                                    normalized = Double.parseDouble(s);
                                } else {
                                    normalized = Integer.parseInt(s);
                                }
                            } catch (NumberFormatException e) {
                                // 解析失败则退回字符串，由 SDK 自己处理
                                normalized = s;
                            }
                        }
                    } else {
                        // 非 bool 类型：先看当前 dps 是否是 0/1（字符串或数字），如果是则按 0/1 字符串规范化
                        Object current = currentDps != null ? currentDps.get(key) : null;
                        boolean currentIsZeroOne = false;

                        // 只有在 schema 类型已知且不是数值型(value)时，才根据当前值 0/1 推断为开关型 DP，
                        // 避免像 231 这种实际为数值区间的 DP 在当前值为 0/1 时被误判为 bool。
                        // 注意：DP 235 是枚举型 0/1/2/3，不能按布尔推断，否则发送 "2" 会被错误归一化为 "0"。
                        if (!"235".equals(key) && schemaType != null && !"value".equalsIgnoreCase(schemaType)) {
                            if (current instanceof String) {
                                String cs = (String) current;
                                currentIsZeroOne = "0".equals(cs) || "1".equals(cs);
                            } else if (current instanceof Number) {
                                int cv = ((Number) current).intValue();
                                currentIsZeroOne = (cv == 0 || cv == 1);
                            }
                        }

                        if (currentIsZeroOne && (raw instanceof Boolean || raw instanceof String)) {
                            // 这种 DP（例如 106）在设备上是用 0/1 表示的开关，且本次下发值是布尔语义
                            boolean boolVal = false;
                            if (raw instanceof Boolean) {
                                boolVal = (Boolean) raw;
                            } else if (raw instanceof String) {
                                String s = ((String) raw).toLowerCase();
                                boolVal = "1".equals(s) || "true".equals(s);
                            }
                            normalized = boolVal ? "1" : "0";
                        } else {
                            // 其它类型：
                            // 如果原始值本身是数字，并且当前 DP 的值看起来也是数字字符串，则按数值发送，
                            // 避免像 231 这种实际为数值型的 DP 被当成字符串，导致 SDK 侧 ClassCastException。
                            boolean handled = false;
                            if (raw instanceof Number) {
                                if (current instanceof String) {
                                    String cs = (String) current;
                                    try {
                                        // 当前值能成功解析为数字，说明设备侧期望的是数值类型
                                        Double.parseDouble(cs);
                                        normalized = raw;
                                        handled = true;
                                    } catch (NumberFormatException ignore) {
                                        // ignore and fallback
                                    }
                                } else if (current instanceof Number) {
                                    // 当前值本身就是数字，直接保持数值类型
                                    normalized = raw;
                                    handled = true;
                                }
                            }

                            if (!handled) {
                                // 其它情况统一转成字符串，让 SDK 自己按 schema 解析
                                normalized = String.valueOf(raw);
                            }
                        }
                    }

                    mapAsString.append("\"").append(key).append("\"").append(":");

                    if (normalized instanceof String) {
                        String s = (String) normalized;
                        s = s.replace("\\", "\\\\").replace("\"", "\\\"");
                        mapAsString.append("\"").append(s).append("\"");
                    } else {
                        mapAsString.append(String.valueOf(normalized));
                    }
                    mapAsString.append(", ");
                }
                if (mapAsString.length() > 1) {
                    mapAsString.delete(mapAsString.length() - 2, mapAsString.length());
                }
                mapAsString.append("}");
                Log.i("dps", mapAsString.toString());

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
                        // 返回 true 给 Flutter，表示设置成功
                        result.success(true);
                    }
                });

                break;
            case "getDeviceDpConfigs":
                //getDps function of Tuya SDK is called
                String getDpsdevId = call.argument("deviceId");
                DeviceBean mDevice = ThingHomeSdk.getDataInstance().getDeviceBean(getDpsdevId);
                Map<String,SchemaBean> schemaBeanMap =mDevice.getSchemaMap();
                ArrayList<HashMap<String, Object>> dpConfigs = new ArrayList<>();
                Map<String,Object> dps=mDevice.getDps();
                schemaBeanMap.forEach((key,value)->{
                    String valueStr="null";
                    if(dps.get(key)!=null){
                        valueStr=String.valueOf(dps.get(key));
                    }

                    // 针对 DP 235 打印设备当前值，便于与设置时的发送值对比
                    if ("235".equals(key)) {
                        Log.i("dps", "235原生设备当前值:" + valueStr);
                    }
                    HashMap<String, Object> dpDetails = new HashMap<>();
                    dpDetails.put("dpId",key);
                    dpDetails.put("code",value.getCode());
                    dpDetails.put("name",value.getName());
                    dpDetails.put("type",value.getType());
                    dpDetails.put("value",valueStr);

                    dpConfigs.add(dpDetails);
                });

                result.success(dpConfigs);
                break;
            case "registerPush":
                //setPushStatusByType function of Tuya SDK is called
                Number pushTypeInt = call.argument("type");
                Boolean checked = call.argument("isOpen");
                PushType pushType = PushType.values()[pushTypeInt.intValue()];
                Log.i("pushType", pushType.toString());
                ThingHomeSdk.getPushInstance().setPushStatusByType(pushType, checked, new IThingDataCallback<Boolean>() {
                    @Override
                    public void onSuccess(Boolean setup) {
                        result.success(null);
                    }

                    @Override
                    public void onError(String errorCode, String errorMessage) {
                        result.error("REGISTER_PUSH_FAILED", errorMessage, "");
                    }
                });

                break;
            case "getAllMessages":
                //getMessageList function of Tuya SDK is called
                int offset = 0;
                int limit = 30;
                ThingHomeSdk.getMessageInstance().getMessageList(offset, limit, new IThingDataCallback<MessageListBean>() {
                    @Override
                    public void onSuccess(MessageListBean listBean) {
                        ArrayList<HashMap<String, Object>> messageList = new ArrayList<>();
                        for (int i = 0; i < listBean.getTotalCount()-1; i++) {
                            HashMap<String, Object> messageDetails = new HashMap<>();
                            messageDetails.put("msgType",listBean.getDatas().get(i).getMsgType());
                            messageDetails.put("msgContent",listBean.getDatas().get(i).getMsgContent());
                            messageList.add(messageDetails);
                        }
                        result.success(messageList);
                    }

                    @Override
                    public void onError(String errorCode, String errorMessage) {
                        result.error("GET_MESSAGES_FAILED", errorMessage, "");
                    }
                });

                break;

        }
    }
}

class TuyaCameraViewFactory extends PlatformViewFactory {
    TuyaCameraPlatformView tuyaCameraPlatformView;
    private EventSink eventSink;

    TuyaCameraViewFactory() {
        super(StandardMessageCodec.INSTANCE);
    }

    public void setEventSink(EventSink eventSink) {
        this.eventSink = eventSink;
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.setEventSink(eventSink);
        }
    }

    @Override
    public PlatformView create(@NonNull Context context, int id, @Nullable Object args) {
        final Map<String, Object> creationParams = (Map<String, Object>) args;
        tuyaCameraPlatformView = new TuyaCameraPlatformView(context, id, creationParams, eventSink);
        return tuyaCameraPlatformView;
    }

    public void startCamera() {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.startCamera();
        }
    }

    public void stopCamera() {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.stopCamera();
        }
    }

    public void connectP2P(String devId) {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.connectP2P(devId);
        }
    }

    public void disconnectP2P() {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.disconnectP2P();
        }
    }

    public void startPreview(int clarity) {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.startPreview(clarity);
        }
    }

    public void stopPreview() {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.stopPreview();
        }
    }

    public void startTalk() {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.startTalk();
        }
    }

    public void stopTalk() {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.stopTalk();
        }
    }

    public void snapshot(String dirPath, MethodChannel.Result result) {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.snapshot(dirPath, result);
        } else {
            result.error("CAMERA_VIEW_NOT_READY", "TuyaCameraPlatformView is null", null);
        }
    }

    public void snapshotWithConfig(String dir, String fileName, int rotateMode, boolean saveToAlbum, MethodChannel.Result result) {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.snapshotWithConfig(dir, fileName, rotateMode, saveToAlbum, result);
        } else {
            result.error("CAMERA_VIEW_NOT_READY", "TuyaCameraPlatformView is null", null);
        }
    }

    public void setMute(int status) {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.setMute(status);
        }
    }

    public void setLoudSpeakerStatus(boolean enable) {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.setLoudSpeakerStatus(enable);
        }
    }

    public void startLocalRecording(String picPath) {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.startLocalRecording(picPath);
        }
    }

    public void stopLocalRecording() {
        if (tuyaCameraPlatformView != null) {
            tuyaCameraPlatformView.stopLocalRecording();
        }
    }
}

class TuyaCameraPlatformView implements PlatformView {
    private View view = null;
    private IThingSmartCameraP2P mCameraP2P = null;
    private String devId;
    private EventSink eventSink;
    private android.os.Handler mainHandler;

    private Context pluginContext;
    private ThingCameraView cameraView;
    private boolean isTalking = false;
    private boolean reConnect = false;
    // 是否正在播放预览流
    private boolean isPlay = false;
    // 当前预览静音状态
    private int previewMute = ICameraP2P.MUTE;
    // 当前视频清晰度
    private int videoClarity = ICameraP2P.HD;

    TuyaCameraPlatformView(Context context, int id, Map<String, Object> creationParams, EventSink eventSink) {
        this.eventSink = eventSink;
        this.mainHandler = new android.os.Handler(android.os.Looper.getMainLooper());

        // PlatformView 创建时标记为前台（仿照官方 demo，用于调试）
        try {
            ThingUtil.setAppForeground(true);
        } catch (Throwable t) {
            Log.w("CAMERA", "ThingUtil.setAppForeground(true) failed", t);
        }

        // 从 Flutter 传入的参数中获取设备 devId
        devId = (String) creationParams.get("deviceId");
        Log.i("Device Id", devId);
        // 记录插件上下文，用于本地录像等功能
        pluginContext = context.getApplicationContext();
        IThingIPCCore cameraInstance = ThingIPCSdk.getCameraInstance();
        if (cameraInstance != null) {
            // 1. 创建 P2P 相机实例（与官方 CameraPanelActivity 中 initData 一致）
            mCameraP2P = cameraInstance.createCameraP2P(devId);

            // 2. 创建并初始化 ThingCameraView，作为视频渲染 View
            view = LayoutInflater.from(context).inflate(R.layout.camera_video_view, null);
            cameraView = view.findViewById(R.id.camera_video_view);
            cameraView.setViewCallback(new AbsVideoViewCallback() {
                @Override
                public void onCreated(Object view) {
                    super.onCreated(view);
                    // 将底层解码后的画面绑定到 P2P 相机对象（等价于 demo 中 generateCameraView）
                    Log.i("CAMERA", "cameraView on created");
                    if (mCameraP2P != null) {
                        mCameraP2P.generateCameraView(view);
                        Log.i("CAMERA", "after generate camera view");
                    }
                }
            });
            // 以 devId 创建视频渲染视图（官方 demo 也是使用 devId）
            cameraView.createVideoView(devId);

            // 3. 注册 P2P 监听，用于回声数据（对讲）和会话状态（自动重连）
            mCameraP2P.registerP2PCameraListener(new com.thingclips.smart.camera.camerasdk.thingplayer.callback.AbsP2pCameraListener() {
                @Override
                public void onReceiveSpeakerEchoData(ByteBuffer pcm, int sampleRate) {
                    if (mCameraP2P == null) {
                        return;
                    }
                    int length = pcm.capacity();
                    Log.d("CAMERA", "receiveSpeakerEchoData pcmlength " + length + " sampleRate " + sampleRate);
                    byte[] pcmData = new byte[length];
                    pcm.get(pcmData, 0, length);
                    mCameraP2P.sendAudioTalkData(pcmData, length);
                }

                @Override
                public void onSessionStatusChanged(Object camera, int sessionId, int sessionStatus) {
                    super.onSessionStatusChanged(camera, sessionId, sessionStatus);
                    // 按照官方 Demo，在 -3 / -105（超时 / 鉴权失败）时仅重连一次，避免死循环
                    if (sessionStatus == -3 || sessionStatus == -105) {
                        if (!reConnect && mCameraP2P != null) {
                            reConnect = true;
                            Log.i("CAMERA", "P2P session status " + sessionStatus + ", auto reconnect once: " + devId);
                            mCameraP2P.connect(devId, new OperationDelegateCallBack() {
                                @Override
                                public void onSuccess(int i, int i1, String s) {
                                    Log.i("CAMERA", "P2P reconnect success after session status " + sessionStatus);
                                    Map<String, Object> successData = new HashMap<>();
                                    successData.put("repStatus", 0);
                                    sendEventToFlutter("connectP2PCallback", successData);
                                }

                                @Override
                                public void onFailure(int i, int i1, int i2) {
                                    Log.e("CAMERA", "P2P reconnect failed after session status " + sessionStatus + ", errCode=" + i2);
                                    Map<String, Object> errorData = new HashMap<>();
                                    errorData.put("repStatus", -1);
                                    errorData.put("errCode", i2);
                                    sendEventToFlutter("connectP2PCallback", errorData);
                                }
                            });
                        }
                    }
                }
            });

            // 默认设置为静音播放，和官方面板保持一致
            mCameraP2P.setMute(ICameraP2P.MUTE, new OperationDelegateCallBack() {
                @Override
                public void onSuccess(int sessionId, int requestId, String data) {
                    // data 为当前静音状态，记录下来
                    try {
                        previewMute = Integer.parseInt(data);
                    } catch (Exception e) {
                        Log.w("CAMERA", "setMute onSuccess parse error: " + data, e);
                    }
                }

                @Override
                public void onFailure(int sessionId, int requestId, int errCode) {
                }
            });
        }


    }

    @Override
    public View getView() {
        return view;
    }

    @Override
    public void dispose() {
        // PlatformView 销毁时标记为离开前台
        try {
            ThingUtil.setAppForeground(false);
        } catch (Throwable t) {
            Log.w("CAMERA", "ThingUtil.setAppForeground(false) failed", t);
        }

        // 释放 P2P 资源（直接调用 disconnect/destroy）
        try {
            if (mCameraP2P != null) {
                try {
                    mCameraP2P.removeOnP2PCameraListener();
                } catch (Exception ignore) {}
                try {
                    mCameraP2P.disconnect(new OperationDelegateCallBack() {
                        @Override
                        public void onSuccess(int sessionId, int requestId, String data) { }

                        @Override
                        public void onFailure(int sessionId, int requestId, int errCode) { }
                    });
                } catch (Exception ignore) {}
                try {
                    mCameraP2P.destroyP2P();
                } catch (Exception ignore) {}
            }
        } catch (Exception e) {
            Log.e("CAMERA", "⚠️ dispose 中释放 P2P 资源异常: " + e.getMessage(), e);
        }
        // 如果有需要，也可以在这里调用 cameraView.onDestroy()
    }

    public void setEventSink(EventSink eventSink) {
        this.eventSink = eventSink;
    }

    private void sendEventToFlutter(String eventType, Map<String, Object> data) {
        if (eventSink == null) {
            Log.w("CAMERA", "⚠️ EventSink 为空，无法发送事件: " + eventType);
            return;
        }
        
        mainHandler.post(() -> {
            try {
                Map<String, Object> event = new HashMap<>();
                event.put(eventType, data);
                eventSink.success(event);
                Log.i("CAMERA", "✅ 发送事件到 Flutter: " + eventType + ", data: " + data);
            } catch (Exception e) {
                Log.e("CAMERA", "❌ 发送事件到 Flutter 失败: " + e.getMessage(), e);
            }
        });
    }

    public void startCamera() {
        if (mCameraP2P == null) {
            Log.e("CAMERA", "❌ mCameraP2P 为空，无法启动摄像头");
            Map<String, Object> errorData = new HashMap<>();
            errorData.put("repStatus", -1);
            errorData.put("errCode", -10001);
            errorData.put("errorMsg", "Camera P2P instance is null");
            sendEventToFlutter("connectP2PCallback", errorData);
            return;
        }

        // 等价于官方 demo 的 onResume：先让视频 View 进入可见状态
        if (cameraView != null) {
            try {
                cameraView.onResume();
            } catch (Exception e) {
                Log.w("CAMERA", "cameraView.onResume error: " + e.getMessage(), e);
            }
        }

        // 对低功耗门铃等设备，先尝试唤醒，再建立 P2P 连接
        try {
            IThingIPCCore ipcCore = ThingIPCSdk.getCameraInstance();
            if (ipcCore != null && ipcCore.isLowPowerDevice(devId)) {
                if (ThingIPCSdk.getDoorbell() != null) {
                    Log.i("CAMERA", "🔋 设备为低功耗设备，先进行无线唤醒: " + devId);
                    ThingIPCSdk.getDoorbell().wirelessWake(devId);
                } else {
                    Log.w("CAMERA", "⚠️ Doorbell 实例为空，无法唤醒低功耗设备: " + devId);
                }
            }
        } catch (Exception e) {
            Log.e("CAMERA", "⚠️ 尝试唤醒低功耗设备时异常: " + e.getMessage(), e);
        }

        Log.i("CAMERA", "📡 开始 P2P 连接: " + devId);
        mCameraP2P.connect(devId, new OperationDelegateCallBack() {
            @Override
            public void onSuccess(int sessionId, int requestId, String data) {
                // A P2P connection is created.
                Log.i("CAMERA", "✅ P2P 连接成功: sessionId=" + sessionId + ", requestId=" + requestId);
                
                // 发送 P2P 连接成功事件
                Map<String, Object> successData = new HashMap<>();
                successData.put("repStatus", 0);
                successData.put("sessionId", sessionId);
                successData.put("requestId", requestId);
                sendEventToFlutter("connectP2PCallback", successData);

                // P2P 连接成功后，按官方 demo 的逻辑自动开启预览
                Log.i("CAMERA", "📡 开始启动预览(videoClarity=" + videoClarity + ")...");
                internalStartPreview(videoClarity);
            }

            @Override
            public void onFailure(int sessionId, int requestId, int errCode) {
                // Failed to create a P2P connection.
                Log.e("CAMERA", "❌ P2P 连接失败: sessionId=" + sessionId + ", requestId=" + requestId + ", errCode=" + errCode);
                
                // 发送 P2P 连接失败事件
                Map<String, Object> errorData = new HashMap<>();
                errorData.put("repStatus", -1);
                errorData.put("errCode", errCode);
                errorData.put("errorMsg", "Failed to connect P2P, error code: " + errCode);
                
                // 根据错误代码提供更详细的错误信息
                String errorMsg = "P2P 连接失败";
                switch (errCode) {
                    case -3:
                        errorMsg = "网络超时，请检查网络连接后重试";
                        break;
                    case -1:
                        errorMsg = "网络连接失败，请检查网络设置";
                        break;
                    case -105:
                        errorMsg = "鉴权失败，建议重新连接";
                        break;
                    case -102:
                        errorMsg = "设备处于隐私模式，无法连接";
                        break;
                    default:
                        errorMsg = "P2P 连接失败 (错误代码: " + errCode + ")";
                        break;
                }
                errorData.put("errorMsg", errorMsg);
                sendEventToFlutter("connectP2PCallback", errorData);
            }
        });
    }

    // 独立暴露给 Flutter 的 P2P 连接方法（用于重试等场景）
    public void connectP2P(String devId) {
        if (mCameraP2P == null) {
            Log.e("CAMERA", "❌ mCameraP2P 为空，无法连接 P2P");
            Map<String, Object> errorData = new HashMap<>();
            errorData.put("repStatus", -1);
            errorData.put("errCode", -10001);
            errorData.put("errorMsg", "Camera P2P instance is null");
            sendEventToFlutter("connectP2PCallback", errorData);
            return;
        }

        // 对低功耗门铃等设备，参考 startCamera 先尝试唤醒
        try {
            IThingIPCCore ipcCore = ThingIPCSdk.getCameraInstance();
            if (ipcCore != null && ipcCore.isLowPowerDevice(devId)) {
                if (ThingIPCSdk.getDoorbell() != null) {
                    Log.i("CAMERA", "🔋 connectP2P: 设备为低功耗设备，先进行无线唤醒: " + devId);
                    ThingIPCSdk.getDoorbell().wirelessWake(devId);
                } else {
                    Log.w("CAMERA", "⚠️ connectP2P: Doorbell 实例为空，无法唤醒低功耗设备: " + devId);
                }
            }
        } catch (Exception e) {
            Log.e("CAMERA", "⚠️ connectP2P: 尝试唤醒低功耗设备时异常: " + e.getMessage(), e);
        }

        Log.i("CAMERA", "📡 调用 connectP2P(独立): " + devId);
        mCameraP2P.connect(devId, new OperationDelegateCallBack() {
            @Override
            public void onSuccess(int sessionId, int requestId, String data) {
                Log.i("CAMERA", "✅ P2P 连接成功(独立): sessionId=" + sessionId + ", requestId=" + requestId);
                Map<String, Object> successData = new HashMap<>();
                successData.put("repStatus", 0);
                successData.put("sessionId", sessionId);
                successData.put("requestId", requestId);
                sendEventToFlutter("connectP2PCallback", successData);
            }

            @Override
            public void onFailure(int sessionId, int requestId, int errCode) {
                Log.e("CAMERA", "❌ P2P 连接失败(独立): sessionId=" + sessionId + ", requestId=" + requestId + ", errCode=" + errCode);
                Map<String, Object> errorData = new HashMap<>();
                errorData.put("repStatus", -1);
                errorData.put("errCode", errCode);
                String errorMsg = "P2P 连接失败";
                switch (errCode) {
                    case -3:
                        errorMsg = "网络超时，请检查网络连接后重试";
                        break;
                    case -1:
                        errorMsg = "网络连接失败，请检查网络设置";
                        break;
                    case -105:
                        errorMsg = "鉴权失败，建议重新连接";
                        break;
                    case -102:
                        errorMsg = "设备处于隐私模式，无法连接";
                        break;
                    default:
                        errorMsg = "P2P 连接失败 (错误代码: " + errCode + ")";
                        break;
                }
                errorData.put("errorMsg", errorMsg);
                sendEventToFlutter("connectP2PCallback", errorData);
            }
        });
    }

    public void stopCamera() {
        if (mCameraP2P == null) {
            Log.w("CAMERA", "⚠️ mCameraP2P 为空，无法停止摄像头");
            return;
        }
        //  demo 的 onPause：先暂停 View，再停止预览和断开连接
        if (cameraView != null) {
            try {
                cameraView.onPause();
            } catch (Exception e) {
                Log.w("CAMERA", "cameraView.onPause error: " + e.getMessage(), e);
            }
        }

        Log.i("CAMERA", "📡 停止预览: " + devId);
        mCameraP2P.stopPreview(new OperationDelegateCallBack() {
            @Override
            public void onSuccess(int sessionId, int requestId, String data) {
                Log.i("CAMERA", "✅ 预览停止成功: sessionId=" + sessionId + ", requestId=" + requestId);
                isPlay = false;

                // 发送预览停止成功事件
                Map<String, Object> successData = new HashMap<>();
                successData.put("repStatus", 0);
                successData.put("sessionId", sessionId);
                successData.put("requestId", requestId);
                sendEventToFlutter("stopPreviewCallback", successData);
                
                // 断开 P2P 连接
                Log.i("CAMERA", "📡 断开 P2P 连接...");
                mCameraP2P.disconnect(new OperationDelegateCallBack() {
                    @Override
                    public void onSuccess(int sessionId, int requestId, String data) {
                        Log.i("CAMERA", "✅ P2P 断开成功: sessionId=" + sessionId + ", requestId=" + requestId);
                        
                        // 发送 P2P 断开成功事件
                        Map<String, Object> disconnectData = new HashMap<>();
                        disconnectData.put("repStatus", 0);
                        disconnectData.put("sessionId", sessionId);
                        disconnectData.put("requestId", requestId);
                        sendEventToFlutter("disconnectP2PCallback", disconnectData);
                    }

                    @Override
                    public void onFailure(int sessionId, int requestId, int errCode) {
                        Log.e("CAMERA", "❌ P2P 断开失败: sessionId=" + sessionId + ", requestId=" + requestId + ", errCode=" + errCode);
                        
                        // 发送 P2P 断开失败事件
                        Map<String, Object> errorData = new HashMap<>();
                        errorData.put("repStatus", -1);
                        errorData.put("errCode", errCode);
                        errorData.put("errorMsg", "Failed to disconnect P2P, error code: " + errCode);
                        sendEventToFlutter("disconnectP2PCallback", errorData);
                    }
                });
            }

            @Override
            public void onFailure(int sessionId, int requestId, int errCode) {
                Log.e("CAMERA", "❌ 预览停止失败: sessionId=" + sessionId + ", requestId=" + requestId + ", errCode=" + errCode);
                
                // 发送预览停止失败事件
                Map<String, Object> errorData = new HashMap<>();
                errorData.put("repStatus", -1);
                errorData.put("errCode", errCode);
                errorData.put("errorMsg", "Failed to stop preview, error code: " + errCode);
                sendEventToFlutter("stopPreviewCallback", errorData);
            }
        });
    }

    // 独立暴露给 Flutter 的断开 P2P 方法
    public void disconnectP2P() {
        if (mCameraP2P == null) {
            Log.w("CAMERA", "⚠️ mCameraP2P 为空，无法断开 P2P");
            return;
        }

        Log.i("CAMERA", "📡 调用 disconnectP2P(独立): " + devId);
        mCameraP2P.disconnect(new OperationDelegateCallBack() {
            @Override
            public void onSuccess(int sessionId, int requestId, String data) {
                Log.i("CAMERA", "✅ P2P 断开成功(独立): sessionId=" + sessionId + ", requestId=" + requestId);
                Map<String, Object> disconnectData = new HashMap<>();
                disconnectData.put("repStatus", 0);
                disconnectData.put("sessionId", sessionId);
                disconnectData.put("requestId", requestId);
                sendEventToFlutter("disconnectP2PCallback", disconnectData);
            }

            @Override
            public void onFailure(int sessionId, int requestId, int errCode) {
                Log.e("CAMERA", "❌ P2P 断开失败(独立): sessionId=" + sessionId + ", requestId=" + requestId + ", errCode=" + errCode);
                Map<String, Object> errorData = new HashMap<>();
                errorData.put("repStatus", -1);
                errorData.put("errCode", errCode);
                errorData.put("errorMsg", "Failed to disconnect P2P, error code: " + errCode);
                sendEventToFlutter("disconnectP2PCallback", errorData);
            }
        });
    }

    // 独立暴露给 Flutter 的开始预览方法（clarity 目前只作为日志参数）
    public void startPreview(int clarity) {
        if (mCameraP2P == null) {
            Log.e("CAMERA", "❌ mCameraP2P 为空，无法启动预览");
            Map<String, Object> errorData = new HashMap<>();
            errorData.put("repStatus", -1);
            errorData.put("errCode", -10001);
            errorData.put("errorMsg", "Camera P2P instance is null");
            sendEventToFlutter("startPreviewCallback", errorData);
            return;
        }

        // 记录清晰度，并按官方 demo 使用带 clarity 的接口启动预览
        videoClarity = clarity;
        Log.i("CAMERA", "📡 调用 startPreview(独立), clarity=" + clarity + ", devId=" + devId);
        internalStartPreview(videoClarity);
    }

    // 独立暴露给 Flutter 的停止预览方法
    public void stopPreview() {
        if (mCameraP2P == null) {
            Log.w("CAMERA", "⚠️ mCameraP2P 为空，无法停止预览");
            return;
        }

        Log.i("CAMERA", "📡 调用 stopPreview(独立): " + devId);
        mCameraP2P.stopPreview(new OperationDelegateCallBack() {
            @Override
            public void onSuccess(int sessionId, int requestId, String data) {
                Log.i("CAMERA", "✅ 预览停止成功(独立): sessionId=" + sessionId + ", requestId=" + requestId);
                isPlay = false;
                Map<String, Object> successData = new HashMap<>();
                successData.put("repStatus", 0);
                successData.put("sessionId", sessionId);
                successData.put("requestId", requestId);
                sendEventToFlutter("stopPreviewCallback", successData);
            }

            @Override
            public void onFailure(int sessionId, int requestId, int errCode) {
                Log.e("CAMERA", "❌ 预览停止失败(独立): sessionId=" + sessionId + ", requestId=" + requestId + ", errCode=" + errCode);
                Map<String, Object> errorData = new HashMap<>();
                errorData.put("repStatus", -1);
                errorData.put("errCode", errCode);
                errorData.put("errorMsg", "Failed to stop preview, error code: " + errCode);
                sendEventToFlutter("stopPreviewCallback", errorData);
            }
        });
    }

    // 内部封装的预览启动逻辑，统一使用带清晰度参数的接口，复用给 startCamera / startPreview
    private void internalStartPreview(int clarity) {
        if (mCameraP2P == null) {
            Log.e("CAMERA", "internalStartPreview: mCameraP2P is null");
            return;
        }
        mCameraP2P.startPreview(clarity, new OperationDelegateCallBack() {
            @Override
            public void onSuccess(int sessionId, int requestId, String data) {
                Log.i("CAMERA", "✅ 预览启动成功: sessionId=" + sessionId + ", requestId=" + requestId + ", clarity=" + clarity);
                isPlay = true;
                Map<String, Object> previewSuccessData = new HashMap<>();
                previewSuccessData.put("repStatus", 0);
                previewSuccessData.put("sessionId", sessionId);
                previewSuccessData.put("requestId", requestId);
                sendEventToFlutter("startPreviewCallback", previewSuccessData);
            }

            @Override
            public void onFailure(int sessionId, int requestId, int errCode) {
                Log.e("CAMERA", "❌ 预览启动失败: sessionId=" + sessionId + ", requestId=" + requestId + ", errCode=" + errCode + ", clarity=" + clarity);
                isPlay = false;
                Map<String, Object> previewErrorData = new HashMap<>();
                previewErrorData.put("repStatus", -1);
                previewErrorData.put("errCode", errCode);
                previewErrorData.put("errorMsg", "Failed to start preview, error code: " + errCode);
                sendEventToFlutter("startPreviewCallback", previewErrorData);
            }
        });
    }

    public void startLocalRecording(String picPath) {
        mCameraP2P.startRecordLocalMp4(picPath, pluginContext, new OperationDelegateCallBack() {
            @Override
            public void onSuccess(int sessionId, int requestId, String data) {

            }

            @Override
            public void onFailure(int sessionId, int requestId, int errCode) {

            }
        });
    }

    public void stopLocalRecording() {
        mCameraP2P.stopRecordLocalMp4(new OperationDelegateCallBack() {
            @Override
            public void onSuccess(int sessionId, int requestId, String data) {
                // The success callback.
            }

            @Override
            public void onFailure(int sessionId, int requestId, int errCode) {
                // The failure callback.
            }
        });
    }

    // 开始对讲
    public void startTalk() {
        if (mCameraP2P == null) {
            Log.w("CAMERA", "startTalk: mCameraP2P is null");
            return;
        }
        if (isTalking) {
            Log.i("CAMERA", "startTalk: already talking, ignore");
            return;
        }
        mCameraP2P.startAudioTalk(new OperationDelegateCallBack() {
            @Override
            public void onSuccess(int sessionId, int requestId, String data) {
                Log.i("CAMERA", "startAudioTalk success: " + data);
                isTalking = true;
            }

            @Override
            public void onFailure(int sessionId, int requestId, int errCode) {
                Log.e("CAMERA", "startAudioTalk failed: " + errCode);
                isTalking = false;
            }
        });
    }

    // 停止对讲
    public void stopTalk() {
        if (mCameraP2P == null) {
            Log.w("CAMERA", "stopTalk: mCameraP2P is null");
            return;
        }
        if (!isTalking) {
            Log.i("CAMERA", "stopTalk: not talking, ignore");
            return;
        }
        mCameraP2P.stopAudioTalk(new OperationDelegateCallBack() {
            @Override
            public void onSuccess(int sessionId, int requestId, String data) {
                Log.i("CAMERA", "stopAudioTalk success: " + data);
                isTalking = false;
            }

            @Override
            public void onFailure(int sessionId, int requestId, int errCode) {
                Log.e("CAMERA", "stopAudioTalk failed: " + errCode);
                isTalking = false;
            }
        });
    }

    // 设置静音
    public void setMute(int status) {
        if (mCameraP2P == null) {
            Log.w("CAMERA", "setMute: mCameraP2P is null");
            return;
        }
        mCameraP2P.setMute(status, new OperationDelegateCallBack() {
            @Override
            public void onSuccess(int sessionId, int requestId, String data) {
                Log.i("CAMERA", "setMute success: " + data);
            }

            @Override
            public void onFailure(int sessionId, int requestId, int errCode) {
                Log.e("CAMERA", "setMute failed: " + errCode);
            }
        });
    }

    public void setLoudSpeakerStatus(boolean enable) {
        if (mCameraP2P == null) {
            Log.w("CAMERA", "setLoudSpeakerStatus: mCameraP2P is null");
            return;
        }
        try {
            mCameraP2P.setLoudSpeakerStatus(enable);
        } catch (Throwable t) {
            Log.e("CAMERA", "setLoudSpeakerStatus failed", t);
        }
    }

    public void snapshot(String dirPath, MethodChannel.Result result) {
        if (mCameraP2P == null) {
            Log.w("CAMERA", "snapshot: mCameraP2P is null");
            result.error("CAMERA_P2P_NULL", "Camera P2P instance is null", null);
            return;
        }

        String targetDir = dirPath;
        if (targetDir == null || targetDir.isEmpty()) {
            // 默认使用应用私有的图片目录，避免外部存储权限问题
            try {
                File appDir = pluginContext.getExternalFilesDir(Environment.DIRECTORY_PICTURES);
                if (appDir == null) {
                    appDir = pluginContext.getFilesDir();
                }
                targetDir = new File(appDir, "Camera").getAbsolutePath() + "/";
            } catch (Throwable t) {
                Log.e("CAMERA", "snapshot: resolve default directory failed", t);
                result.error("SNAPSHOT_PATH_INVALID", "Resolve default directory failed", null);
                return;
            }
        }

        try {
            File file = new File(targetDir);
            if (!file.exists()) {
                file.mkdirs();
            }
        } catch (Throwable t) {
            Log.e("CAMERA", "snapshot: mkdirs failed", t);
        }

        String finalDir = targetDir;
        mCameraP2P.snapshot(finalDir, pluginContext, new OperationDelegateCallBack() {
            @Override
            public void onSuccess(int sessionId, int requestId, String data) {
                result.success(data);
            }

            @Override
            public void onFailure(int sessionId, int requestId, int errCode) {
                result.error("SNAPSHOT_FAILED", String.valueOf(errCode), null);
            }
        });
    }

    public void snapshotWithConfig(String dir, String fileName, int rotateMode, boolean saveToAlbum, MethodChannel.Result result) {
        if (mCameraP2P == null) {
            Log.w("CAMERA", "snapshotWithConfig: mCameraP2P is null");
            result.error("CAMERA_P2P_NULL", "Camera P2P instance is null", null);
            return;
        }

        String targetDir = dir;
        if (targetDir == null || targetDir.isEmpty()) {
            // 默认使用应用私有的图片目录，避免外部存储权限问题
            try {
                File appDir = pluginContext.getExternalFilesDir(Environment.DIRECTORY_PICTURES);
                if (appDir == null) {
                    appDir = pluginContext.getFilesDir();
                }
                targetDir = new File(appDir, "Camera").getAbsolutePath() + "/";
            } catch (Throwable t) {
                Log.e("CAMERA", "snapshotWithConfig: resolve default directory failed", t);
                result.error("SNAPSHOT_PATH_INVALID", "Resolve default directory failed", null);
                return;
            }
        }

        try {
            File file = new File(targetDir);
            if (!file.exists()) {
                file.mkdirs();
            }
        } catch (Throwable t) {
            Log.e("CAMERA", "snapshotWithConfig: mkdirs failed", t);
        }

        IPCSnapshotConfig config = new IPCSnapshotConfig();
        config.setDictionary(targetDir);
        if (fileName != null && !fileName.isEmpty()) {
            config.setFileName(fileName);
        }
        config.setRotateMode(rotateMode);
        config.setSaveToAlbum(saveToAlbum);

        mCameraP2P.snapshotWithConfig(pluginContext, config, new OperationDelegateCallBack() {
            @Override
            public void onSuccess(int sessionId, int requestId, String data) {
                result.success(data);
            }

            @Override
            public void onFailure(int sessionId, int requestId, int errCode) {
                result.error("SNAPSHOT_CONFIG_FAILED", String.valueOf(errCode), null);
            }
        });
    }
}
