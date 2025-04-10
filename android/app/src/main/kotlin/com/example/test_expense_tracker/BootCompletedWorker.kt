package com.example.test_expense_tracker

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters

class BootCompletedWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        Log.d("BootCompletedWorker", "Starting work after boot completed")

        try {
            // Launch the main activity
            val launchIntent = applicationContext.packageManager
                .getLaunchIntentForPackage(applicationContext.packageName)

            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                applicationContext.startActivity(launchIntent)
                Log.d("BootCompletedWorker", "Started main activity successfully")
                return Result.success()
            } else {
                Log.e("BootCompletedWorker", "Could not get launch intent")
                return Result.failure()
            }
        } catch (e: Exception) {
            Log.e("BootCompletedWorker", "Error starting app: ${e.message}")
            return Result.failure()
        }
    }
}