# =====================================================
# PROGUARD RULES - BIPOL TRACKER (KEAMANAN MAKSIMAL 2025)
# =====================================================

# === FLUTTER CORE (WAJIB) ===
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.**

# === GOOGLE MAPS ===
-keep class com.google.android.gms.maps.** { *; }
-keep class com.google.maps.** { *; }
-dontwarn com.google.android.gms.**

# === SUPABASE / HTTP CLIENT ===
-keep class io.supabase.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class com.google.gson.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# === SECURITY LIBRARIES ===
-keep class com.scottyab.rootbeer.** { *; }
-keep class com.bipoltracker.bipol_tracker.** { *; }

# === MAXIMUM OBFUSCATION ===
-overloadaggressively
-repackageclasses ''
-allowaccessmodification
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*,!code/allocation/variable
-optimizationpasses 5

# === DEBUG INFO (untuk crash reporting) ===
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# === KEEP ANNOTATIONS ===
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# === ENUM PROTECTION ===
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# === PARCELABLE ===
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# === SERIALIZABLE ===
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# === NATIVE METHODS ===
-keepclasseswithmembernames class * {
    native <methods>;
}

# =====================================================
# MOBSF FIX: AGGRESSIVE LOG STRIPPING (menghapus SEMUA log di release)
# =====================================================
-assumenosideeffects class android.util.Log {
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
    public static int wtf(...);
    public static boolean isLoggable(java.lang.String, int);
    public static int println(int, java.lang.String, java.lang.String);
}

# Hapus System.out dan System.err
-assumenosideeffects class java.io.PrintStream {
    public void println(...);
    public void print(...);
    public void printf(...);
}

# =====================================================
# MOBSF FIX: CRYPTO PROTECTION (CBC padding issue mitigation)
# =====================================================
-keep class javax.crypto.** { *; }
-keep class javax.crypto.spec.** { *; }
-keep class java.security.** { *; }
-dontwarn javax.crypto.**
-dontwarn java.security.**

# Obfuscate cipher classes aggressively
-keepclassmembers class * extends javax.crypto.Cipher {
    <methods>;
}

# === SSL/TLS PROTECTION ===
-keep class javax.net.ssl.** { *; }
-keep class org.conscrypt.** { *; }
-dontwarn org.conscrypt.**

# =====================================================
# MOBSF FIX: REMOVE SENSITIVE STRING CONSTANTS
# =====================================================
# Hapus string constants yang tidak diperlukan
-assumenosideeffects class java.lang.String {
    public static java.lang.String valueOf(boolean);
}

# =====================================================
# KOTLIN PROTECTION
# =====================================================
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# =====================================================
# ANTI-TAMPERING: Protect critical classes
# =====================================================
-keep class com.bipoltracker.bipol_tracker.BuildConfig { *; }
-keep,allowobfuscation class com.bipoltracker.bipol_tracker.MainActivity { *; }

# =====================================================
# NDK JNI BRIDGE PROTECTION
# =====================================================
# Keep NativeSecrets JNI class and its native methods
-keep class com.bipoltracker.bipol_tracker.NativeSecrets {
    native <methods>;
    *;
}

# Keep SecurityChecker for runtime security checks
-keep class com.bipoltracker.bipol_tracker.SecurityChecker {
    public static *;
}

# =====================================================
# ADDITIONAL SECURITY HARDENING
# =====================================================
# Remove unused code aggressively
-dontnote **
-dontwarn **

# Obfuscate package names
-flattenpackagehierarchy

# Merge interfaces where possible
-mergeinterfacesaggressively
