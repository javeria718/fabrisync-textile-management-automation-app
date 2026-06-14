plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle plugin must always come AFTER Android + Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin") // Firebase plugin
}

android {
    namespace = "com.example.fabri_sync"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.fabri_sync"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        debug {
            // Ensure resource shrinking is off for debug builds.
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            // TODO: Replace with proper release signing before publishing
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
dependencies {
}