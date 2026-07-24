package com.example.tradplus_sdk_example;

import androidx.annotation.NonNull;

import com.tradplus.flutter.TradPlusSdk;

import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String REPRO_CHANNEL = "tradplus_sdk/multi_engine_repro";

    private FlutterEngine secondaryEngine;
    private MethodChannel reproChannel;
    private TradPlusSdk observedTradPlusSdk;
    private boolean secondaryEngineWasDestroyed;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        reproChannel = new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                REPRO_CHANNEL
        );
        reproChannel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "getState":
                    result.success(buildReproState());
                    break;
                case "createSecondaryEngine":
                    createSecondaryEngine(result);
                    break;
                case "destroySecondaryEngine":
                    destroySecondaryEngine(result);
                    break;
                default:
                    result.notImplemented();
                    break;
            }
        });
    }

    private void createSecondaryEngine(MethodChannel.Result result) {
        if (secondaryEngine != null || secondaryEngineWasDestroyed) {
            result.error(
                    "invalid_state",
                    "Restart the example before creating another secondary engine.",
                    null
            );
            return;
        }

        // The default constructor automatically registers every generated plugin.
        // No Dart entrypoint is needed to reproduce the TradPlus lifecycle conflict.
        secondaryEngine = new FlutterEngine(getApplicationContext());
        result.success(buildReproState());
    }

    private void destroySecondaryEngine(MethodChannel.Result result) {
        if (secondaryEngine == null) {
            result.error("invalid_state", "No secondary engine is running.", null);
            return;
        }

        secondaryEngine.destroy();
        secondaryEngine = null;
        secondaryEngineWasDestroyed = true;
        result.success(buildReproState());
    }

    private Map<String, Object> buildReproState() {
        if (observedTradPlusSdk == null) {
            observedTradPlusSdk = TradPlusSdk.getInstance();
        }

        Map<String, Object> state = new HashMap<>();
        state.put("secondaryEngineRunning", secondaryEngine != null);
        state.put("secondaryEngineDestroyed", secondaryEngineWasDestroyed);
        state.put("tradPlusActivityIsHost", observedTradPlusSdk.getActivity() == this);
        state.put(
                "observedTradPlusInstanceId",
                Integer.toHexString(System.identityHashCode(observedTradPlusSdk))
        );
        return state;
    }

    @Override
    public void cleanUpFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        if (reproChannel != null) {
            reproChannel.setMethodCallHandler(null);
            reproChannel = null;
        }
        super.cleanUpFlutterEngine(flutterEngine);
    }

    @Override
    protected void onDestroy() {
        if (secondaryEngine != null) {
            secondaryEngine.destroy();
            secondaryEngine = null;
        }
        super.onDestroy();
    }
}
