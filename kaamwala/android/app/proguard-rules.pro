# KaamWala release keep rules

# Razorpay native checkout uses reflection extensively.
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Firebase messaging entry points invoked from the background.
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.**

# Flutter engine + plugins accessed reflectively.
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }

# Preserve line numbers for readable Crashlytics stack traces.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
