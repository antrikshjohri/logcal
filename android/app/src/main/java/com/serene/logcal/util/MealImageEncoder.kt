package com.serene.logcal.util

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.util.Base64
import java.io.ByteArrayOutputStream

/**
 * Encodes a gallery/camera [Uri] string to raw JPEG base64 for [FirebaseMealRepository] / `logMeal`.
 * Matches iOS behavior (JPEG, scaled down, reasonable quality) to keep payload size in check.
 */
object MealImageEncoder {

    private const val TAG = "MealImageEncoder"
    private const val MAX_DIMENSION_PX = 2048
    private const val JPEG_QUALITY = 85

    /**
     * @return raw base64 (no `data:` prefix) or null on failure
     */
    fun encodeUriToJpegBase64(context: Context, uriString: String): String? {
        return try {
            val uri = Uri.parse(uriString)
            val resolver = context.applicationContext.contentResolver
            val bytes = resolver.openInputStream(uri)?.use { it.readBytes() }
            if (bytes == null || bytes.isEmpty()) {
                DebugLogger.w("$TAG openInputStream empty or null uri=$uriString")
                return null
            }
            var bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            if (bitmap == null) {
                DebugLogger.w("$TAG decodeByteArray returned null len=${bytes.size}")
                return null
            }
            try {
                val w = bitmap.width
                val h = bitmap.height
                val longest = maxOf(w, h)
                if (longest > MAX_DIMENSION_PX) {
                    val scale = MAX_DIMENSION_PX.toFloat() / longest
                    val nw = maxOf(1, (w * scale).toInt())
                    val nh = maxOf(1, (h * scale).toInt())
                    val scaled = Bitmap.createScaledBitmap(bitmap, nw, nh, true)
                    if (scaled != bitmap) {
                        bitmap.recycle()
                        bitmap = scaled
                    }
                    DebugLogger.d("$TAG scaled to ${bitmap.width}x${bitmap.height} from ${w}x${h}")
                }
                val out = ByteArrayOutputStream()
                if (!bitmap.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, out)) {
                    DebugLogger.w("$TAG JPEG compress returned false")
                    return null
                }
                val jpegBytes = out.toByteArray()
                val b64 = Base64.encodeToString(jpegBytes, Base64.NO_WRAP)
                DebugLogger.d("$TAG encoded jpegBytes=${jpegBytes.size} base64Len=${b64.length}")
                b64
            } finally {
                bitmap.recycle()
            }
        } catch (t: Throwable) {
            DebugLogger.e("$TAG encode failed uri=$uriString", t)
            null
        }
    }
}
