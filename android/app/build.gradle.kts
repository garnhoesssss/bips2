import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// === RELEASE SIGNING: Load key.properties ===
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.bipoltracker.bipol_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bipoltracker.bipol_tracker"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // === KEAMANAN: Hanya arsitektur yang diperlukan ===
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }

    // === RELEASE SIGNING CONFIGURATION ===
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: "upload"
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: ""
            storePassword = keystoreProperties.getProperty("storePassword") ?: ""
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "upload-keystore.jks")
        }
    }

    buildTypes {
        release {
            // === USE RELEASE SIGNING (not debug) ===
            signingConfig = signingConfigs.getByName("release")

            // === R8 OBFUSCATION & SHRINKING ===
            isMinifyEnabled = true              // R8 full obfuscation + pengacakan kode
            isShrinkResources = true            // Hapus asset & resource tak terpakai
            
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // === ANTI-DEBUGGING & KEAMANAN ===
            isDebuggable = false                // WAJIB false untuk produksi
            isJniDebuggable = false             // Cegah native debugging
            isPseudoLocalesEnabled = false      // Matikan pseudo locales
            
            // Optimisasi APK
            ndk {
                abiFilters += listOf("arm64-v8a", "armeabi-v7a")
            }
        }
        
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
        }
    }

    // === PACKAGING OPTIONS KEAMANAN ===
    packaging {
        resources {
            excludes += listOf(
                "META-INF/NOTICE.txt",
                "META-INF/LICENSE.txt",
                "META-INF/DEPENDENCIES",
                "META-INF/*.kotlin_module"
            )
        }
    }
}

flutter {
    source = "../.."
}
