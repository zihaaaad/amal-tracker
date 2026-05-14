plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.amaltracker.amal_tracker"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Default ID (fallback)
        applicationId = "com.amaltracker.amal_tracker"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions.add("app")
    productFlavors {
        create("client") {
            dimension = "app"
            applicationId = "com.amaltracker.app"
            versionNameSuffix = "-client"
            manifestPlaceholders["appName"] = "Amal Tracker"
            manifestPlaceholders["authScheme"] = "com.amaltracker.auth"
        }
        create("admin") {
            dimension = "app"
            applicationId = "com.amaltracker.admin"
            versionNameSuffix = "-admin"
            manifestPlaceholders["appName"] = "Foundation Admin"
            manifestPlaceholders["authScheme"] = "com.amaltracker.admin.auth"
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
