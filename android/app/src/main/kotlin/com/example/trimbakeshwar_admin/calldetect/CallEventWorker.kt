package com.example.trimbakeshwar_admin.calldetect

import android.content.Context
import android.telephony.SmsManager
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/**
 * Acts on one already-classified call event: sends a local SMS if the
 * Guruji checked that box for this call type, and always reports the call
 * to the backend (which logs it and, only if [CallIntegrationPrefs.whatsappEnabled]
 * was set for this call type, sends the WhatsApp follow-up itself).
 */
class CallEventWorker(appContext: Context, params: WorkerParameters) :
    CoroutineWorker(appContext, params) {

    companion object {
        const val KEY_CALL_LOG_ID = "call_log_id"
        const val KEY_NUMBER = "number"
        const val KEY_NAME = "name"
        const val KEY_CALL_TYPE = "call_type"
        const val KEY_TIMESTAMP_MILLIS = "timestamp_millis"
        const val KEY_DURATION_SECONDS = "duration_seconds"
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val callLogId = inputData.getLong(KEY_CALL_LOG_ID, -1L)
        val number = inputData.getString(KEY_NUMBER) ?: return@withContext Result.failure()
        val name = inputData.getString(KEY_NAME) ?: ""
        val callType = inputData.getString(KEY_CALL_TYPE) ?: return@withContext Result.failure()
        val timestampMillis = inputData.getLong(KEY_TIMESTAMP_MILLIS, System.currentTimeMillis())
        val durationSeconds = inputData.getInt(KEY_DURATION_SECONDS, 0)
        if (callLogId < 0) return@withContext Result.failure()

        val context = applicationContext

        if (CallIntegrationPrefs.smsEnabled(context, callType)) {
            sendSms(number, callType)
        }

        val whatsappRequested = CallIntegrationPrefs.whatsappEnabled(context, callType)
        val reported = reportToBackend(
            context = context,
            callLogId = callLogId,
            number = number,
            name = name,
            callType = callType,
            timestampMillis = timestampMillis,
            durationSeconds = durationSeconds,
            whatsappRequested = whatsappRequested,
        )

        if (!reported) Result.retry() else Result.success()
    }

    private fun sendSms(number: String, callType: String) {
        val message = when (callType) {
            "missed" -> "Namaskar, we noticed we missed your call. Please let us know how we can help with your pooja booking at Trimbakeshwar."
            "rejected" -> "Namaskar, sorry we could not take your call right now. Please share your query and we will get back to you shortly."
            "received" -> "Namaskar, thank you for calling regarding your pooja at Trimbakeshwar. Do let us know if you need any further assistance."
            else -> return
        }
        try {
            val smsManager = SmsManager.getDefault()
            val parts = smsManager.divideMessage(message)
            smsManager.sendMultipartTextMessage(number, null, parts, null, null)
        } catch (e: Exception) {
            // Best-effort: SMS failures aren't retried since a WorkManager
            // retry would risk sending the same SMS twice.
        }
    }

    private fun reportToBackend(
        context: Context,
        callLogId: Long,
        number: String,
        name: String,
        callType: String,
        timestampMillis: Long,
        durationSeconds: Int,
        whatsappRequested: Boolean,
    ): Boolean {
        val gurujiPhone = CallIntegrationPrefs.gurujiPhone(context)
        val deviceKey = CallIntegrationPrefs.deviceKey(context)
        if (gurujiPhone.isBlank() || deviceKey.isBlank()) return true // not configured — nothing to report

        return try {
            val url = URL("${CallIntegrationPrefs.apiBaseUrl(context)}/call-logs")
            val connection = url.openConnection() as HttpURLConnection
            connection.requestMethod = "POST"
            connection.setRequestProperty("Content-Type", "application/json")
            connection.setRequestProperty("X-Device-Key", deviceKey)
            connection.doOutput = true
            connection.connectTimeout = 15_000
            connection.readTimeout = 15_000

            val body = JSONObject().apply {
                put("gurujiPhone", gurujiPhone)
                put("callerPhone", number)
                put("callerName", name)
                put("callType", callType)
                put("callTimestamp", formatTimestamp(timestampMillis))
                put("durationSeconds", durationSeconds)
                put("deviceCallLogId", callLogId)
                put("sendWhatsappRequested", whatsappRequested)
            }

            connection.outputStream.use { it.write(body.toString().toByteArray()) }
            val code = connection.responseCode
            connection.disconnect()
            code in 200..299
        } catch (e: Exception) {
            false
        }
    }

    private fun formatTimestamp(millis: Long): String {
        val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
        format.timeZone = TimeZone.getTimeZone("Asia/Kolkata")
        return format.format(Date(millis))
    }
}
