package com.example.trimbakeshwar_admin

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import com.example.trimbakeshwar_admin.calldetect.CallIntegrationPrefs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "trimbakeshwar/call_integration"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSettings" -> result.success(currentSettings())

                "updateSettings" -> {
                    val args = call.arguments as? Map<*, *>
                    if (args == null) {
                        result.error("bad_args", "Expected a settings map", null)
                        return@setMethodCallHandler
                    }
                    applySettings(args)
                    result.success(null)
                }

                "isIgnoringBatteryOptimizations" -> {
                    val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                    result.success(pm.isIgnoringBatteryOptimizations(packageName))
                }

                "openBatteryOptimizationSettings" -> {
                    try {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("unavailable", e.message, null)
                    }
                }

                "deviceManufacturer" -> result.success("${Build.MANUFACTURER} ${Build.MODEL}")

                else -> result.notImplemented()
            }
        }
    }

    private fun currentSettings(): Map<String, Any> = mapOf(
        "enabled" to CallIntegrationPrefs.isEnabled(this),
        "gurujiPhone" to CallIntegrationPrefs.gurujiPhone(this),
        "smsMissed" to CallIntegrationPrefs.smsEnabled(this, "missed"),
        "smsReceived" to CallIntegrationPrefs.smsEnabled(this, "received"),
        "smsRejected" to CallIntegrationPrefs.smsEnabled(this, "rejected"),
        "waMissed" to CallIntegrationPrefs.whatsappEnabled(this, "missed"),
        "waReceived" to CallIntegrationPrefs.whatsappEnabled(this, "received"),
        "waRejected" to CallIntegrationPrefs.whatsappEnabled(this, "rejected"),
    )

    private fun applySettings(args: Map<*, *>) {
        (args["enabled"] as? Boolean)?.let { CallIntegrationPrefs.setEnabled(this, it) }
        (args["gurujiPhone"] as? String)?.let { CallIntegrationPrefs.setGurujiPhone(this, it) }
        (args["deviceKey"] as? String)?.let { CallIntegrationPrefs.setDeviceKey(this, it) }
        (args["apiBaseUrl"] as? String)?.let { CallIntegrationPrefs.setApiBaseUrl(this, it) }

        CallIntegrationPrefs.setChannelSettings(
            context = this,
            smsMissed = args["smsMissed"] as? Boolean ?: CallIntegrationPrefs.smsEnabled(this, "missed"),
            smsReceived = args["smsReceived"] as? Boolean ?: CallIntegrationPrefs.smsEnabled(this, "received"),
            smsRejected = args["smsRejected"] as? Boolean ?: CallIntegrationPrefs.smsEnabled(this, "rejected"),
            waMissed = args["waMissed"] as? Boolean ?: CallIntegrationPrefs.whatsappEnabled(this, "missed"),
            waReceived = args["waReceived"] as? Boolean ?: CallIntegrationPrefs.whatsappEnabled(this, "received"),
            waRejected = args["waRejected"] as? Boolean ?: CallIntegrationPrefs.whatsappEnabled(this, "rejected"),
        )
    }
}
