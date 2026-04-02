package com.serene.logcal.util;

/**
 * Encodes a gallery/camera [Uri] string to raw JPEG base64 for [FirebaseMealRepository] / `logMeal`.
 * Matches iOS behavior (JPEG, scaled down, reasonable quality) to keep payload size in check.
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000$\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c7\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0018\u0010\b\u001a\u0004\u0018\u00010\u00072\u0006\u0010\t\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\u0007R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0082T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0007X\u0082T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\f"}, d2 = {"Lcom/serene/logcal/util/MealImageEncoder;", "", "()V", "JPEG_QUALITY", "", "MAX_DIMENSION_PX", "TAG", "", "encodeUriToJpegBase64", "context", "Landroid/content/Context;", "uriString", "app_debug"})
public final class MealImageEncoder {
    @org.jetbrains.annotations.NotNull()
    private static final java.lang.String TAG = "MealImageEncoder";
    private static final int MAX_DIMENSION_PX = 2048;
    private static final int JPEG_QUALITY = 85;
    @org.jetbrains.annotations.NotNull()
    public static final com.serene.logcal.util.MealImageEncoder INSTANCE = null;
    
    private MealImageEncoder() {
        super();
    }
    
    /**
     * @return raw base64 (no `data:` prefix) or null on failure
     */
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String encodeUriToJpegBase64(@org.jetbrains.annotations.NotNull()
    android.content.Context context, @org.jetbrains.annotations.NotNull()
    java.lang.String uriString) {
        return null;
    }
}