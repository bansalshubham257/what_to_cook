# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.embedding.** { *; }

# Riverpod
-keep class dev.riverpod.** { *; }
-keep class io.flutter.plugins.** { *; }

# Dio/Retrofit
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }
-keep class com.google.gson.** { *; }

# SharedPreferences
-keep class com.example.what_to_cook.** { *; }

# Keep serialization
-keep class * implements com.google.gson.JsonSerializer { *; }
-keep class * implements com.google.gson.JsonDeserializer { *; }

# Image picker
-keep class ywu.kiwi.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }

# Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# URL launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# Cached network image
-keep class io.flutter.plugins.cachednetworkimage.** { *; }

# Google fonts
-keep class com.google.fonts.** { *; }

# Play Core - for dynamic feature modules
-keep class com.google.android.play.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.play.**

# Keep all enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}