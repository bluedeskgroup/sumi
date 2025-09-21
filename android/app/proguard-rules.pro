# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepattributes *Annotation*

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.auth.api.gms.** { *; }

# Google Play Services
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# SMS Retriever
-keep class com.google.android.gms.auth.api.phone.** { *; }

# Prevent obfuscation of Firebase classes
-keepnames class com.google.firebase.** { *; }
-keepnames class com.google.android.gms.** { *; }

# Google Play Core (required for Flutter release builds)
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keepattributes *Annotation*

# Additional rules for plugins
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class dev.fluttercommunity.plus.wakelock.** { *; }

# RenderScript (for mobile_scanner)
-keep class android.renderscript.** { *; }

# Video compress
-keep class com.example.video_compress.** { *; }
