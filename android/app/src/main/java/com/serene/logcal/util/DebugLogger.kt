package com.serene.logcal.util

import android.util.Log

object DebugLogger {
    private const val TAG = "LogCalAndroid"

    fun d(message: String) {
        Log.d(TAG, message)
    }

    fun w(message: String, throwable: Throwable? = null) {
        if (throwable != null) {
            Log.w(TAG, message, throwable)
        } else {
            Log.w(TAG, message)
        }
    }

    fun e(message: String, throwable: Throwable? = null) {
        if (throwable != null) {
            Log.e(TAG, message, throwable)
        } else {
            Log.e(TAG, message)
        }
    }
}

