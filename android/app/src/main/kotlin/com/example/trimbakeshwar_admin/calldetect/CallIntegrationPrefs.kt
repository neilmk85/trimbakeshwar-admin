package com.example.trimbakeshwar_admin.calldetect

import android.content.Context
import android.content.SharedPreferences

/**
 * App-owned SharedPreferences file for the call-detection feature. Kept
 * deliberately separate from the shared_preferences Flutter plugin's own
 * storage — that file's name/key format is a plugin implementation detail,
 * not a documented contract, so native code should never read it directly.
 * Flutter writes here via a single MethodChannel call after the setup
 * screen's permissions/checkboxes are confirmed.
 */
object CallIntegrationPrefs {
    private const val PREFS_NAME = "call_integration_prefs"
    private const val DEFAULT_API_BASE_URL = "https://app.trimbakeshwarpoojavidhi.in/api"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun isEnabled(context: Context): Boolean = prefs(context).getBoolean("enabled", false)
    fun setEnabled(context: Context, value: Boolean) {
        prefs(context).edit().putBoolean("enabled", value).apply()
    }

    fun gurujiPhone(context: Context): String = prefs(context).getString("guruji_phone", "") ?: ""
    fun setGurujiPhone(context: Context, value: String) {
        prefs(context).edit().putString("guruji_phone", value).apply()
    }

    fun deviceKey(context: Context): String = prefs(context).getString("device_key", "") ?: ""
    fun setDeviceKey(context: Context, value: String) {
        prefs(context).edit().putString("device_key", value).apply()
    }

    fun apiBaseUrl(context: Context): String =
        prefs(context).getString("api_base_url", DEFAULT_API_BASE_URL) ?: DEFAULT_API_BASE_URL
    fun setApiBaseUrl(context: Context, value: String) {
        prefs(context).edit().putString("api_base_url", value).apply()
    }

    /** Guruji-set checkbox: should this call type trigger an SMS? SMS is
     * sent entirely on-device — this backend-free decision is checked
     * directly by [com.example.trimbakeshwar_admin.calldetect.CallEventWorker]. */
    fun smsEnabled(context: Context, callType: String): Boolean =
        prefs(context).getBoolean("sms_$callType", false)

    /** Guruji-set checkbox: should this call type ask the backend to send a
     * WhatsApp follow-up? The backend still applies its own cooldown/devotee
     * matching on top of this request. */
    fun whatsappEnabled(context: Context, callType: String): Boolean =
        prefs(context).getBoolean("wa_$callType", false)

    fun setChannelSettings(
        context: Context,
        smsMissed: Boolean,
        smsReceived: Boolean,
        smsRejected: Boolean,
        waMissed: Boolean,
        waReceived: Boolean,
        waRejected: Boolean,
    ) {
        prefs(context).edit()
            .putBoolean("sms_missed", smsMissed)
            .putBoolean("sms_received", smsReceived)
            .putBoolean("sms_rejected", smsRejected)
            .putBoolean("wa_missed", waMissed)
            .putBoolean("wa_received", waReceived)
            .putBoolean("wa_rejected", waRejected)
            .apply()
    }

    // ── Scratch state for CallStateReceiver ──────────────────────────────────
    // Each broadcast delivery may construct a fresh BroadcastReceiver
    // instance, so the "call currently ringing" state must be persisted
    // rather than held in a field. Cleared as soon as it's consumed at IDLE.

    fun setRingingNumber(context: Context, number: String?) {
        prefs(context).edit().putString("ringing_number", number ?: "").apply()
    }

    fun ringingNumber(context: Context): String = prefs(context).getString("ringing_number", "") ?: ""
}
