package com.example.untitled2

import android.content.pm.ApplicationInfo
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "app.security/signals"
        ).setMethodCallHandler { call, result ->
            if (call.method == "getSecuritySignals") {
                result.success(
                    mapOf(
                        "is_emulator" to isProbablyEmulator(),
                        "is_rooted" to isProbablyRooted(),
                        "is_debuggable" to isDebuggableBuild(),
                    )
                )
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isDebuggableBuild(): Boolean {
        return (applicationContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }

    private fun isProbablyEmulator(): Boolean {
        return Build.FINGERPRINT.startsWith("generic") ||
            Build.FINGERPRINT.lowercase().contains("emulator") ||
            Build.MODEL.contains("Emulator") ||
            Build.MODEL.contains("Android SDK built for x86") ||
            Build.MANUFACTURER.contains("Genymotion") ||
            Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic") ||
            "google_sdk" == Build.PRODUCT
    }

    private fun isProbablyRooted(): Boolean {
        val tags = Build.TAGS ?: ""
        if (tags.contains("test-keys")) {
            return true
        }

        val rootPaths = listOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su"
        )
        return rootPaths.any { path -> java.io.File(path).exists() }
    }
}
