import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
var useReleaseSigning = false

if (keystorePropertiesFile.exists()) {
    try {
        FileInputStream(keystorePropertiesFile).use { stream ->
            keystoreProperties.load(stream)
        }
        val keyAlias = keystoreProperties["keyAlias"] as? String
        val keyPassword = keystoreProperties["keyPassword"] as? String
        val storeFilePath = keystoreProperties["storeFile"] as? String
        val storePassword = keystoreProperties["storePassword"] as? String

        if (!keyAlias.isNullOrEmpty() &&
            !keyPassword.isNullOrEmpty() &&
            !storeFilePath.isNullOrEmpty() &&
            !storePassword.isNullOrEmpty()
        ) {
            val keystoreFile = file(storeFilePath)
            if (keystoreFile.exists()) {
                useReleaseSigning = true
            } else {
                project.logger.warn("WARNING: Keystore file not found at '$storeFilePath'. Falling back to debug signing.")
            }
        } else {
            project.logger.warn("WARNING: key.properties is missing some required values. Falling back to debug signing.")
        }
    } catch (e: Exception) {
        project.logger.warn("WARNING: Failed to load key.properties: ${e.message}. Falling back to debug signing.")
    }
}

android {
    namespace = "com.igowisnu.kasir_cepat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.igowisnu.kasir_cepat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (useReleaseSigning) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (useReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
