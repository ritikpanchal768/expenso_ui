package com.example.expenso

import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import androidx.annotation.NonNull
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()
{
    private val CHANNEL = "sms_limited"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getLimitedSMS") {
                val smsList = getLimitedSMS(300)  // Fetch only 300 messages
                result.success(smsList)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getLimitedSMS(limit: Int): List<Map<String, String>> {
        val smsList = mutableListOf<Map<String, String>>()
        val uri = Uri.parse("content://sms/inbox")
        val projection = arrayOf("body", "date")
        val cursor: Cursor? = contentResolver.query(uri, projection, null, null, "date DESC LIMIT $limit")

        cursor?.use {
            val bodyIndex = it.getColumnIndex("body")
            val dateIndex = it.getColumnIndex("date")

            while (it.moveToNext()) {
                val sms = mapOf(
                    "body" to it.getString(bodyIndex),
                    "date" to it.getString(dateIndex)
                )
                smsList.add(sms)
            }
        }
        cursor?.close()
        return smsList
    }
}
