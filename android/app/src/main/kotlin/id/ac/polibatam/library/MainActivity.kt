package id.ac.polibatam.library

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val SECURITY_CHANNEL = "id.ac.polibatam.library/security"
    private val BRIGHTNESS_CHANNEL = "id.ac.polibatam.library/brightness"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Security channel (FLAG_SECURE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECURITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setSecure" -> {
                    val secure = call.argument<Boolean>("secure") ?: false
                    if (secure) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Auto High Brightness channel for Barcode Scanner
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BRIGHTNESS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setMaxBrightness" -> {
                    val layout = window.attributes
                    layout.screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_FULL
                    window.attributes = layout
                    result.success(true)
                }
                "resetBrightness" -> {
                    val layout = window.attributes
                    layout.screenBrightness = WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                    window.attributes = layout
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
