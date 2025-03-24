plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.madproject"
    compileSdk = 34 // Use the numeric value from local.properties
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.madproject"
        minSdk = 21 // Use numeric value from local.properties
        targetSdk = 34 // Use numeric value from local.properties
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}