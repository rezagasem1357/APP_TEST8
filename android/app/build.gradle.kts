import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // پلاگین رسمی فلاتر
    id("dev.flutter.flutter-gradle-plugin")
}

// خواندن اطلاعات local.properties در صورت وجود
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    // تعیین دقیق Namespace برای جلوگیری از تداخل
    namespace = "com.example.object_counter_app"
    compileSdk = 34

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.object_counter_app"
        minSdk = 21
        targetSdk = 34
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
    }

    buildTypes {
        release {
            // استفاده از Debug Signing جهت ایجاد خروجی تست ریلیز بدون کلید اختصاصی
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
