package com.example.trimbakeshwar_admin.calldetect

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import androidx.work.Data
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/**
 * Manifest-registered receiver for ACTION_PHONE_STATE — this fires even when
 * the app isn't running (ACTION_PHONE_STATE is exempt from Android 8+'s
 * implicit-broadcast background restrictions), which a runtime-registered
 * receiver could not guarantee.
 *
 * This receiver is purely a trigger: it only tracks whether a number was
 * ever seen RINGING (which is how an outgoing call — straight to OFFHOOK,
 * no RINGING — is distinguished from a genuine inbound call) and, once the
 * call ends, hands off to [CallLogLookupWorker] to determine the definitive
 * missed/received/rejected outcome from Android's own CallLog — a phone
 * ringing and then going straight to IDLE could be either a missed call or
 * a rejected one, and OFFHOOK fires identically whether the Guruji answered
 * or sent it to voicemail on some OEMs, so this receiver never guesses.
 */
class CallStateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return
        if (!CallIntegrationPrefs.isEnabled(context)) return

        when (intent.getStringExtra(TelephonyManager.EXTRA_STATE)) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
                if (!incomingNumber.isNullOrBlank()) {
                    CallIntegrationPrefs.setRingingNumber(context, incomingNumber)
                }
            }

            TelephonyManager.EXTRA_STATE_IDLE -> {
                val ringingNumber = CallIntegrationPrefs.ringingNumber(context)
                CallIntegrationPrefs.setRingingNumber(context, null)

                // Blank means this call never rang (an outgoing call goes
                // straight to OFFHOOK) — nothing to report.
                if (ringingNumber.isBlank()) return

                val work = OneTimeWorkRequestBuilder<CallLogLookupWorker>()
                    .setInitialDelay(3, TimeUnit.SECONDS) // let the CallLog provider finish writing the row
                    .setInputData(
                        Data.Builder()
                            .putString(CallLogLookupWorker.KEY_NUMBER, ringingNumber)
                            .build()
                    )
                    .build()
                WorkManager.getInstance(context).enqueue(work)
            }

            // EXTRA_STATE_OFFHOOK: nothing to do here — CallLog.Calls.TYPE
            // tells us the real outcome once the call has fully ended.
        }
    }
}
