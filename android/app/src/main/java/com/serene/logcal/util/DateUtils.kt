package com.serene.logcal.util

import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter

object DateUtils {
    private val displayFormatter: DateTimeFormatter = DateTimeFormatter.ofPattern("MMM d, yyyy")

    fun formatMillis(millis: Long): String {
        val local = Instant.ofEpochMilli(millis).atZone(ZoneId.systemDefault()).toLocalDate()
        return local.format(displayFormatter)
    }

    fun localDateToMillis(date: LocalDate): Long {
        return date.atStartOfDay(ZoneId.systemDefault()).toInstant().toEpochMilli()
    }
}

