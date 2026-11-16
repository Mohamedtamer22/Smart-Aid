# Flutter and Dart JNI preservation
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Flutter Secure Storage and Android KeyStore
-keep class androidx.security.crypto.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Geolocator & Location services
-keep class com.baseflow.geolocator.** { *; }

# Remove sensitive line numbers and debug info in production
-renamesourcefileattribute SourceFile
-keepattributes SourceFile,LineNumberTable

# Suppress R8 missing classes warnings for Google Play deferred components
-dontwarn com.google.android.play.core.**

