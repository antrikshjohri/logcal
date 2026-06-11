package com.serene.logcal.util

import java.text.NumberFormat
import java.util.Locale

object NumberUtils {
    private val formatter: NumberFormat = NumberFormat.getIntegerInstance(Locale.getDefault())

    fun formatNumber(value: Int): String {
        return formatter.format(value)
    }

    fun formatNumber(value: Double): String {
        return formatter.format(value)
    }
    
    fun formatNumber(value: Long): String {
        return formatter.format(value)
    }
}
