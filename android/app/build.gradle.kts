import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 키스토어 설정 로드
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "app.picom.team.pi_com"
    compileSdk = 36  // ⭐️ 최신 Android 15

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
        targetSdk = 36  // Android 15

        versionCode = 7
        versionName = "1.0.6"

        // ⭐️ MultiDex 지원
        multiDexEnabled = true

        // ⭐️ NDK 설정 (debug symbol strip 오류 해결)
        ndk {
            debugSymbolLevel = "SYMBOL_TABLE"
        }
    }

    // 릴리즈 서명 설정
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // ✅ 릴리즈 서명 설정 적용
            signingConfig = signingConfigs.getByName("release")

            // ⭐️ ProGuard 난독화 및 코드 최적화 활성화
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
