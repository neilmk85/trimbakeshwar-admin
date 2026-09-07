package com.example.trimbakeshwar_admin.calldetect

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * No-op beyond existing: some OEMs (notably Xiaomi/MIUI, Oppo, Vivo) only
 * keep a manifest receiver's other intent-filters active across reboots if
 * the app also declares a BOOT_COMPLETED receiver, even when that receiver
 * does nothing itself — CallStateReceiver needs no boot-time setup since it
 * is stateless and reads CallIntegrationPrefs fresh on every broadcast.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Intentionally empty.
    }
}
