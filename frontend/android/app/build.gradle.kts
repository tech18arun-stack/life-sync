import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.familytips.family_tips"
    compileSdk = flutter.compileSdkVersion

    repositories {
        flatDir {
            dirs("libs")
        }
    }

    lint {
        checkReleaseBuilds = false
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // REQUIRED for modern Android libraries
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.familytips.family_tips"
        minSdk = flutter.minSdkVersion   // ⚠️ IMPORTANT (Appwrite requires >=21)
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")

            isMinifyEnabled = false
            isShrinkResources = false

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // 🔥 Fix for duplicate META-INF issues (common with SDKs)
    packaging {
        resources {
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {

    // ✅ Required for Java 8+ APIs
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // ✅ Start.io Ads SDK
    implementation("com.startapp:inapp-sdk:4.10.8")

    // ✅ MultiDex
    implementation("androidx.multidex:multidex:2.0.1")

    // 🔥 (Optional but recommended) Chrome Custom Tabs for OAuth
    implementation("androidx.browser:browser:1.8.0")
}
