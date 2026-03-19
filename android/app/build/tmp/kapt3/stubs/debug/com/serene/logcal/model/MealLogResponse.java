package com.serene.logcal.model;

@kotlinx.serialization.Serializable()
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000N\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\u0006\n\u0002\b\u0004\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b$\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\b\u0087\b\u0018\u0000 ?2\u00020\u0001:\u0002>?Bs\b\u0011\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\n\b\u0001\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u0012\b\b\u0001\u0010\u0006\u001a\u00020\u0007\u0012\b\u0010\b\u001a\u0004\u0018\u00010\u0007\u0012\b\u0010\t\u001a\u0004\u0018\u00010\u0007\u0012\b\u0010\n\u001a\u0004\u0018\u00010\u0007\u0012\u000e\u0010\u000b\u001a\n\u0012\u0004\u0012\u00020\r\u0018\u00010\f\u0012\b\b\u0001\u0010\u000e\u001a\u00020\u000f\u0012\n\b\u0001\u0010\u0010\u001a\u0004\u0018\u00010\u0005\u0012\b\u0010\u0011\u001a\u0004\u0018\u00010\u0012\u00a2\u0006\u0002\u0010\u0013B_\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u0012\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\u0007\u0012\n\b\u0002\u0010\t\u001a\u0004\u0018\u00010\u0007\u0012\n\b\u0002\u0010\n\u001a\u0004\u0018\u00010\u0007\u0012\u000e\b\u0002\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\r0\f\u0012\b\b\u0002\u0010\u000e\u001a\u00020\u000f\u0012\n\b\u0002\u0010\u0010\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\u0002\u0010\u0014J\t\u0010(\u001a\u00020\u0005H\u00c6\u0003J\t\u0010)\u001a\u00020\u0007H\u00c6\u0003J\u0010\u0010*\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0016J\u0010\u0010+\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0016J\u0010\u0010,\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0016J\u000f\u0010-\u001a\b\u0012\u0004\u0012\u00020\r0\fH\u00c6\u0003J\t\u0010.\u001a\u00020\u000fH\u00c6\u0003J\u000b\u0010/\u001a\u0004\u0018\u00010\u0005H\u00c6\u0003Jl\u00100\u001a\u00020\u00002\b\b\u0002\u0010\u0004\u001a\u00020\u00052\b\b\u0002\u0010\u0006\u001a\u00020\u00072\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\u00072\n\b\u0002\u0010\t\u001a\u0004\u0018\u00010\u00072\n\b\u0002\u0010\n\u001a\u0004\u0018\u00010\u00072\u000e\b\u0002\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\r0\f2\b\b\u0002\u0010\u000e\u001a\u00020\u000f2\n\b\u0002\u0010\u0010\u001a\u0004\u0018\u00010\u0005H\u00c6\u0001\u00a2\u0006\u0002\u00101J\u0013\u00102\u001a\u00020\u000f2\b\u00103\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u00104\u001a\u00020\u0003H\u00d6\u0001J\t\u00105\u001a\u00020\u0005H\u00d6\u0001J&\u00106\u001a\u0002072\u0006\u00108\u001a\u00020\u00002\u0006\u00109\u001a\u00020:2\u0006\u0010;\u001a\u00020<H\u00c1\u0001\u00a2\u0006\u0002\b=R\u0015\u0010\t\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\n\n\u0002\u0010\u0017\u001a\u0004\b\u0015\u0010\u0016R\u001e\u0010\u0010\u001a\u0004\u0018\u00010\u00058\u0006X\u0087\u0004\u00a2\u0006\u000e\n\u0000\u0012\u0004\b\u0018\u0010\u0019\u001a\u0004\b\u001a\u0010\u001bR\u0015\u0010\n\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\n\n\u0002\u0010\u0017\u001a\u0004\b\u001c\u0010\u0016R\u0017\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\r0\f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001d\u0010\u001eR\u001c\u0010\u0004\u001a\u00020\u00058\u0006X\u0087\u0004\u00a2\u0006\u000e\n\u0000\u0012\u0004\b\u001f\u0010\u0019\u001a\u0004\b \u0010\u001bR\u001c\u0010\u000e\u001a\u00020\u000f8\u0006X\u0087\u0004\u00a2\u0006\u000e\n\u0000\u0012\u0004\b!\u0010\u0019\u001a\u0004\b\"\u0010#R\u0015\u0010\b\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\n\n\u0002\u0010\u0017\u001a\u0004\b$\u0010\u0016R\u001c\u0010\u0006\u001a\u00020\u00078\u0006X\u0087\u0004\u00a2\u0006\u000e\n\u0000\u0012\u0004\b%\u0010\u0019\u001a\u0004\b&\u0010\'\u00a8\u0006@"}, d2 = {"Lcom/serene/logcal/model/MealLogResponse;", "", "seen1", "", "mealType", "", "totalCalories", "", "protein", "carbs", "fat", "items", "", "Lcom/serene/logcal/model/MealItem;", "needsClarification", "", "clarifyingQuestion", "serializationConstructorMarker", "Lkotlinx/serialization/internal/SerializationConstructorMarker;", "(ILjava/lang/String;DLjava/lang/Double;Ljava/lang/Double;Ljava/lang/Double;Ljava/util/List;ZLjava/lang/String;Lkotlinx/serialization/internal/SerializationConstructorMarker;)V", "(Ljava/lang/String;DLjava/lang/Double;Ljava/lang/Double;Ljava/lang/Double;Ljava/util/List;ZLjava/lang/String;)V", "getCarbs", "()Ljava/lang/Double;", "Ljava/lang/Double;", "getClarifyingQuestion$annotations", "()V", "getClarifyingQuestion", "()Ljava/lang/String;", "getFat", "getItems", "()Ljava/util/List;", "getMealType$annotations", "getMealType", "getNeedsClarification$annotations", "getNeedsClarification", "()Z", "getProtein", "getTotalCalories$annotations", "getTotalCalories", "()D", "component1", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "copy", "(Ljava/lang/String;DLjava/lang/Double;Ljava/lang/Double;Ljava/lang/Double;Ljava/util/List;ZLjava/lang/String;)Lcom/serene/logcal/model/MealLogResponse;", "equals", "other", "hashCode", "toString", "write$Self", "", "self", "output", "Lkotlinx/serialization/encoding/CompositeEncoder;", "serialDesc", "Lkotlinx/serialization/descriptors/SerialDescriptor;", "write$Self$app_debug", "$serializer", "Companion", "app_debug"})
public final class MealLogResponse {
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String mealType = null;
    private final double totalCalories = 0.0;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.Double protein = null;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.Double carbs = null;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.Double fat = null;
    @org.jetbrains.annotations.NotNull()
    private final java.util.List<com.serene.logcal.model.MealItem> items = null;
    private final boolean needsClarification = false;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String clarifyingQuestion = null;
    @org.jetbrains.annotations.NotNull()
    public static final com.serene.logcal.model.MealLogResponse.Companion Companion = null;
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component1() {
        return null;
    }
    
    public final double component2() {
        return 0.0;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double component3() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double component4() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double component5() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.serene.logcal.model.MealItem> component6() {
        return null;
    }
    
    public final boolean component7() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component8() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.serene.logcal.model.MealLogResponse copy(@org.jetbrains.annotations.NotNull()
    java.lang.String mealType, double totalCalories, @org.jetbrains.annotations.Nullable()
    java.lang.Double protein, @org.jetbrains.annotations.Nullable()
    java.lang.Double carbs, @org.jetbrains.annotations.Nullable()
    java.lang.Double fat, @org.jetbrains.annotations.NotNull()
    java.util.List<com.serene.logcal.model.MealItem> items, boolean needsClarification, @org.jetbrains.annotations.Nullable()
    java.lang.String clarifyingQuestion) {
        return null;
    }
    
    @java.lang.Override()
    public boolean equals(@org.jetbrains.annotations.Nullable()
    java.lang.Object other) {
        return false;
    }
    
    @java.lang.Override()
    public int hashCode() {
        return 0;
    }
    
    @java.lang.Override()
    @org.jetbrains.annotations.NotNull()
    public java.lang.String toString() {
        return null;
    }
    
    @kotlin.jvm.JvmStatic()
    public static final void write$Self$app_debug(@org.jetbrains.annotations.NotNull()
    com.serene.logcal.model.MealLogResponse self, @org.jetbrains.annotations.NotNull()
    kotlinx.serialization.encoding.CompositeEncoder output, @org.jetbrains.annotations.NotNull()
    kotlinx.serialization.descriptors.SerialDescriptor serialDesc) {
    }
    
    public MealLogResponse(@org.jetbrains.annotations.NotNull()
    java.lang.String mealType, double totalCalories, @org.jetbrains.annotations.Nullable()
    java.lang.Double protein, @org.jetbrains.annotations.Nullable()
    java.lang.Double carbs, @org.jetbrains.annotations.Nullable()
    java.lang.Double fat, @org.jetbrains.annotations.NotNull()
    java.util.List<com.serene.logcal.model.MealItem> items, boolean needsClarification, @org.jetbrains.annotations.Nullable()
    java.lang.String clarifyingQuestion) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getMealType() {
        return null;
    }
    
    @kotlinx.serialization.SerialName(value = "meal_type")
    @java.lang.Deprecated()
    public static void getMealType$annotations() {
    }
    
    public final double getTotalCalories() {
        return 0.0;
    }
    
    @kotlinx.serialization.SerialName(value = "total_calories")
    @java.lang.Deprecated()
    public static void getTotalCalories$annotations() {
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double getProtein() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double getCarbs() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double getFat() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.util.List<com.serene.logcal.model.MealItem> getItems() {
        return null;
    }
    
    public final boolean getNeedsClarification() {
        return false;
    }
    
    @kotlinx.serialization.SerialName(value = "needs_clarification")
    @java.lang.Deprecated()
    public static void getNeedsClarification$annotations() {
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getClarifyingQuestion() {
        return null;
    }
    
    @kotlinx.serialization.SerialName(value = "clarifying_question")
    @java.lang.Deprecated()
    public static void getClarifyingQuestion$annotations() {
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00006\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0011\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c7\u0002\u0018\u00002\b\u0012\u0004\u0012\u00020\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0003J\u0018\u0010\b\u001a\f\u0012\b\u0012\u0006\u0012\u0002\b\u00030\n0\tH\u00d6\u0001\u00a2\u0006\u0002\u0010\u000bJ\u0011\u0010\f\u001a\u00020\u00022\u0006\u0010\r\u001a\u00020\u000eH\u00d6\u0001J\u0019\u0010\u000f\u001a\u00020\u00102\u0006\u0010\u0011\u001a\u00020\u00122\u0006\u0010\u0013\u001a\u00020\u0002H\u00d6\u0001R\u0014\u0010\u0004\u001a\u00020\u00058VX\u00d6\u0005\u00a2\u0006\u0006\u001a\u0004\b\u0006\u0010\u0007\u00a8\u0006\u0014"}, d2 = {"com/serene/logcal/model/MealLogResponse.$serializer", "Lkotlinx/serialization/internal/GeneratedSerializer;", "Lcom/serene/logcal/model/MealLogResponse;", "()V", "descriptor", "Lkotlinx/serialization/descriptors/SerialDescriptor;", "getDescriptor", "()Lkotlinx/serialization/descriptors/SerialDescriptor;", "childSerializers", "", "Lkotlinx/serialization/KSerializer;", "()[Lkotlinx/serialization/KSerializer;", "deserialize", "decoder", "Lkotlinx/serialization/encoding/Decoder;", "serialize", "", "encoder", "Lkotlinx/serialization/encoding/Encoder;", "value", "app_debug"})
    @java.lang.Deprecated()
    public static final class $serializer implements kotlinx.serialization.internal.GeneratedSerializer<com.serene.logcal.model.MealLogResponse> {
        @org.jetbrains.annotations.NotNull()
        public static final com.serene.logcal.model.MealLogResponse.$serializer INSTANCE = null;
        
        @java.lang.Override()
        @org.jetbrains.annotations.NotNull()
        public kotlinx.serialization.KSerializer<?>[] childSerializers() {
            return null;
        }
        
        @java.lang.Override()
        @org.jetbrains.annotations.NotNull()
        public com.serene.logcal.model.MealLogResponse deserialize(@org.jetbrains.annotations.NotNull()
        kotlinx.serialization.encoding.Decoder decoder) {
            return null;
        }
        
        @java.lang.Override()
        @org.jetbrains.annotations.NotNull()
        public kotlinx.serialization.descriptors.SerialDescriptor getDescriptor() {
            return null;
        }
        
        @java.lang.Override()
        public void serialize(@org.jetbrains.annotations.NotNull()
        kotlinx.serialization.encoding.Encoder encoder, @org.jetbrains.annotations.NotNull()
        com.serene.logcal.model.MealLogResponse value) {
        }
        
        private $serializer() {
            super();
        }
        
        @java.lang.Override()
        @org.jetbrains.annotations.NotNull()
        public kotlinx.serialization.KSerializer<?>[] typeParametersSerializers() {
            return null;
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0016\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000f\u0010\u0003\u001a\b\u0012\u0004\u0012\u00020\u00050\u0004H\u00c6\u0001\u00a8\u0006\u0006"}, d2 = {"Lcom/serene/logcal/model/MealLogResponse$Companion;", "", "()V", "serializer", "Lkotlinx/serialization/KSerializer;", "Lcom/serene/logcal/model/MealLogResponse;", "app_debug"})
    public static final class Companion {
        
        @org.jetbrains.annotations.NotNull()
        public final kotlinx.serialization.KSerializer<com.serene.logcal.model.MealLogResponse> serializer() {
            return null;
        }
        
        private Companion() {
            super();
        }
    }
}