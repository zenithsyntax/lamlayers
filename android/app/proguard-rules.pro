# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# OkHttp rules to prevent R8 from removing classes
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

# Keep UCrop classes
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# Keep UCrop OkHttp client store
-keep class com.yalantis.ucrop.OkHttpClientStore { *; }

# Flutter/Dart specific rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep Hive classes for data persistence
-keep class **$**Adapter { *; }
-keep class hive.** { *; }
-dontwarn hive.**

# Keep model classes
-keep class * extends HiveObject { *; }
-keep class * implements HiveTypeAdapterFactory { *; }

# Keep serialization classes
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep all model classes in the lamlayers package
-keep class com.zenithsyntax.lamlayers.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve line numbers for easier debugging in release builds
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Prevent obfuscation of JSON serialization
-keepclassmembers class * {
    @hive.** <methods>;
}
-keep @hive.HiveType class *
-keep @hive.HiveField class *

