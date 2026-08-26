import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release keystore from android/key.properties (NEVER committed).
// Falls back to debug signing so `flutter run --release` always works.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}

android {
    namespace = "com.kaamwala.kaamwala"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Newer AGP defaults this to false; flavors use resValue for app_name.
    buildFeatures {
        resValues = true
    }

    defaultConfig {
        applicationId = "com.kaamwala.kaamwala"
        // firebase_messaging requires API 23+.
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Two store listings from one codebase (Swiggy / Swiggy Partner model).
    // Dart side: --flavor customer -t lib/main_customer.dart
    //            --flavor partner  -t lib/main_partner.dart
    flavorDimensions += "mode"
    productFlavors {
        create("customer") {
            dimension = "mode"
            applicationId = "com.kaamwala.kaamwala"
            resValue("string", "app_name", "KaamWala")
        }
        create("partner") {
            dimension = "mode"
            applicationId = "com.kaamwala.partner"
            resValue("string", "app_name", "KaamWala Partner")
        }
    }

    signingConfigs {
        if (keystoreProperties.isNotEmpty()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystoreProperties.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

// Firebase is OPTIONAL until google-services.json exists (Phase 4 6.2).
// Applied post-plugins because the plugins {} block cannot call file().
//
// Per-flavor configs live at android/app/src/<flavor>/google-services.json.
// We infer the requested flavor from the invoked Gradle tasks so building
// one binary without the other's Firebase config degrades gracefully
// (plugins skipped -> FCM/Analytics no-op) instead of failing the build
// on a package-id mismatch.
val taskNameBlob = gradle.startParameter.taskNames.joinToString(" ").lowercase()
val requestedFlavor = when {
    taskNameBlob.contains("customer") -> "customer"
    taskNameBlob.contains("partner") -> "partner"
    else -> null
}
val googleServicesJson = when (requestedFlavor) {
    null ->
        // No flavor in the task list (plain `gradlew`, CI checks): keep the
        // legacy root-file behavior.
        listOf(
            file("src/customer/google-services.json"),
            file("src/partner/google-services.json"),
            file("google-services.json"),
        ).firstOrNull { it.exists() }
    else ->
        file("src/$requestedFlavor/google-services.json").takeIf { it.exists() }
            // The legacy root json carries the customer package id.
            ?: file("google-services.json")
                .takeIf { it.exists() && requestedFlavor == "customer" }
}
if (googleServicesJson != null) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}
