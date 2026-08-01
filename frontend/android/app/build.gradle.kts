import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.whattocook.ai"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.whattocook.ai"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val keyProps = Properties()
    val keyPropsFile = File(project.rootDir, "app/key.properties")
    if (keyPropsFile.exists()) {
        keyProps.load(keyPropsFile.inputStream())
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProps["keyAlias"] as String? ?: ""
            keyPassword = keyProps["keyPassword"] as String? ?: ""
            storeFile = File(project.rootDir, "app/${keyProps["storeFile"] as String? ?: "key.jks"}")
            storePassword = keyProps["storePassword"] as String? ?: ""
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}