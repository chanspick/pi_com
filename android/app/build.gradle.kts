plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.picom.team.pi_com"
    compileSdk = 35  // ⭐️ 최신 Android 14
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "app.picom.team.pi_com"

        // ⭐️ Firebase Auth 요구사항: 최소 SDK 23
        minSdk = flutter.minSdkVersion  // Android 6.0

        // ⭐️ Google Play 요구사항
        targetSdk = 34  // Android 14

        versionCode = 1
        versionName = "1.0.0"

        // ⭐️ MultiDex 지원
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: 나중에 릴리즈용 signing config 추가
            signingConfig = signingConfigs.getByName("debug")

            // ⭐️ Kotlin DSL 문법: isMinifyEnabled
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }

        getByName("debug") {
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ⭐️ MultiDex 라이브러리
    implementation("androidx.multidex:multidex:2.0.1")
}
