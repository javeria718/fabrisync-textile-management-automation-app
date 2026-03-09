plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle plugin must always come AFTER Android + Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")   // Firebase plugin
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
    // Import the BoM for the Firebase platform
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))

    // Add the dependency for the Firebase Authentication library
    // When using the BoM, you don't specify versions in Firebase library dependencies
    implementation("com.google.firebase:firebase-auth")

    // Also add the dependency for the Google Play services library and specify its version
    implementation("com.google.android.gms:play-services-auth:21.4.0")
}
