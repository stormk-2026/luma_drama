package com.stormg.lumadrama

import android.content.Intent
import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val shareRequestCode = 9041
    private var pendingShare: MethodChannel.Result? = null
    private var pipChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.stormg.lumadrama/pip")
        pipChannel?.setMethodCallHandler { call, result ->
            if (call.method != "enter") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
                !packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)) {
                result.success(false)
                return@setMethodCallHandler
            }
            try {
                val params = PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(9, 16))
                    .build()
                result.success(enterPictureInPictureMode(params))
            } catch (_: Exception) {
                result.success(false)
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.stormg.lumadrama/share")
            .setMethodCallHandler { call, result ->
                if (call.method != "shareText") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val text = call.argument<String>("text")
                if (text.isNullOrBlank() || pendingShare != null) {
                    result.error("share_unavailable", "Share sheet is unavailable", null)
                    return@setMethodCallHandler
                }
                try {
                    val intent = Intent(Intent.ACTION_SEND).apply {
                        type = "text/plain"
                        putExtra(Intent.EXTRA_TEXT, text)
                    }
                    pendingShare = result
                    startActivityForResult(Intent.createChooser(intent, null), shareRequestCode)
                } catch (error: Exception) {
                    pendingShare = null
                    result.error("share_failed", error.message, null)
                }
            }
    }

    override fun onPictureInPictureModeChanged(isInPictureInPictureMode: Boolean, newConfig: Configuration) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("onPipChanged", isInPictureInPictureMode)
    }

    @Deprecated("Used for the system share chooser result")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == shareRequestCode) {
            pendingShare?.success(null)
            pendingShare = null
        }
    }
}
