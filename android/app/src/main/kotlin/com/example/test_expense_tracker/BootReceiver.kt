package com.example.test_expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.ExistingWorkPolicy
import com.example.test_expense_tracker.MainActivity // Import your main activity class
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import java.util.concurrent.TimeUnit

class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
        private const val BOOT_WORK_NAME = "bootCheckServiceWork"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action
        Log.d(TAG, "Received intent with action: $action")

        if (action != null &&
            (action == Intent.ACTION_BOOT_COMPLETED ||
                    action == "android.intent.action.QUICKBOOT_POWERON")) {

            Log.d(TAG, "Boot completed event received. Starting service check.")

            // Use WorkManager to schedule a delayed start of your application
            val workRequest = OneTimeWorkRequestBuilder<BootCompletedWorker>()
                .setInitialDelay(15, TimeUnit.SECONDS)
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                BOOT_WORK_NAME,
                ExistingWorkPolicy.REPLACE,
                workRequest
            )

            Log.d(TAG, "Scheduled delayed app start via WorkManager.")
        }
    }
}