package com.example.trimbakeshwar_admin.calldetect

import android.content.Context
import android.net.Uri
import android.provider.CallLog
import android.provider.ContactsContract
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.concurrent.TimeUnit

/**
 * Queries Android's own CallLog for the definitive outcome of the call
 * [CallStateReceiver] just saw end, then hands off to [CallEventWorker] —
 * uniquely keyed by CallLog's own row id, so a retried/duplicate broadcast
 * can never cause the same call to be reported (and potentially messaged)
 * twice.
 */
class CallLogLookupWorker(appContext: Context, params: WorkerParameters) :
    CoroutineWorker(appContext, params) {

    companion object {
        const val KEY_NUMBER = "number"
    }

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val number = inputData.getString(KEY_NUMBER) ?: return@withContext Result.failure()

        val projection = arrayOf(
            CallLog.Calls._ID,
            CallLog.Calls.NUMBER,
            CallLog.Calls.TYPE,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION,
            CallLog.Calls.CACHED_NAME,
        )

        var callLogId: Long? = null
        var callType: String? = null
        var timestampMillis = 0L
        var durationSeconds = 0
        var cachedName: String? = null

        try {
            applicationContext.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                projection,
                null,
                null,
                "${CallLog.Calls.DATE} DESC LIMIT 5",
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    val rowNumber = cursor.getString(cursor.getColumnIndexOrThrow(CallLog.Calls.NUMBER)) ?: continue
                    if (!numbersMatch(rowNumber, number)) continue

                    val type = cursor.getInt(cursor.getColumnIndexOrThrow(CallLog.Calls.TYPE))
                    val mapped = when (type) {
                        CallLog.Calls.MISSED_TYPE -> "missed"
                        CallLog.Calls.REJECTED_TYPE -> "rejected"
                        CallLog.Calls.INCOMING_TYPE -> "received"
                        else -> null // outgoing or a type we don't act on
                    }
                    if (mapped == null) continue

                    callLogId = cursor.getLong(cursor.getColumnIndexOrThrow(CallLog.Calls._ID))
                    callType = mapped
                    timestampMillis = cursor.getLong(cursor.getColumnIndexOrThrow(CallLog.Calls.DATE))
                    durationSeconds = cursor.getInt(cursor.getColumnIndexOrThrow(CallLog.Calls.DURATION))
                    cachedName = cursor.getString(cursor.getColumnIndexOrThrow(CallLog.Calls.CACHED_NAME))
                    break
                }
            }
        } catch (e: SecurityException) {
            return@withContext Result.failure() // READ_CALL_LOG revoked — retrying won't help
        }

        val resolvedCallLogId = callLogId
        val resolvedCallType = callType
        if (resolvedCallLogId == null || resolvedCallType == null) {
            // The provider may not have written the row yet, or this was an
            // outgoing/unsupported type. A few retries cheaply cover the
            // former; WorkManager gives up eventually either way.
            return@withContext Result.retry()
        }

        val contactName = cachedName?.takeIf { it.isNotBlank() } ?: resolveContactName(number)

        val work = OneTimeWorkRequestBuilder<CallEventWorker>()
            .setInputData(
                Data.Builder()
                    .putLong(CallEventWorker.KEY_CALL_LOG_ID, resolvedCallLogId)
                    .putString(CallEventWorker.KEY_NUMBER, number)
                    .putString(CallEventWorker.KEY_NAME, contactName ?: "")
                    .putString(CallEventWorker.KEY_CALL_TYPE, resolvedCallType)
                    .putLong(CallEventWorker.KEY_TIMESTAMP_MILLIS, timestampMillis)
                    .putInt(CallEventWorker.KEY_DURATION_SECONDS, durationSeconds)
                    .build()
            )
            .setConstraints(
                Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build()
            )
            .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
            .build()

        WorkManager.getInstance(applicationContext).enqueueUniqueWork(
            "call-event-$resolvedCallLogId",
            ExistingWorkPolicy.KEEP,
            work,
        )

        Result.success()
    }

    /** Compares the last 10 digits so +91/leading-zero/formatting differences
     * between the broadcast's number and the CallLog's stored number don't
     * cause a false mismatch. */
    private fun numbersMatch(a: String, b: String): Boolean {
        fun digitsOnly(s: String) = s.filter { it.isDigit() }
        val da = digitsOnly(a)
        val db = digitsOnly(b)
        val shortLen = minOf(da.length, db.length, 10)
        if (shortLen == 0) return false
        return da.takeLast(shortLen) == db.takeLast(shortLen)
    }

    private fun resolveContactName(number: String): String? {
        val uri = Uri.withAppendedPath(
            ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
            Uri.encode(number),
        )
        return try {
            applicationContext.contentResolver.query(
                uri,
                arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME),
                null,
                null,
                null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(cursor.getColumnIndexOrThrow(ContactsContract.PhoneLookup.DISPLAY_NAME))
                } else null
            }
        } catch (e: SecurityException) {
            null
        }
    }
}
