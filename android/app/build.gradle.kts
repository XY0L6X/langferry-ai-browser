plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.langferry.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = "21"
    }

    defaultConfig {
        applicationId = "com.langferry.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: 发布前创建 release keystore 并配置签名
            // 1. 运行: keytool -genkey -v -keystore release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
            // 2. 创建 android/key.properties 文件:
            //    storeFile=../release.keystore
            //    storePassword=你的密码
            //    keyAlias=release
            //    keyPassword=你的密码
            // 3. 取消下方注释并使用 signingConfigs.release
            // signingConfig = signingConfigs.release
        }
    }
}

flutter {
    source = "../.."
}