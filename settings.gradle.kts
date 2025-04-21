// android/settings.gradle.kts

// Gerekli importlar (Emin olmak için ekleyelim)
import java.util.Properties
import java.io.File // File için eklendi

pluginManagement {
    val flutterSdkPath = run {
        // Tam nitelikli isim kullanarak Properties nesnesi oluştur
        val properties = java.util.Properties()
        // Kök dizini 'settings' nesnesinden alıp 'local.properties' dosyasını bul
        // File() constructor'ını kullanarak path'i birleştirelim
        val localPropertiesFile = File(settings.rootDir, "local.properties")
        if (localPropertiesFile.exists()) {
            // 'use' bloğunda açık parametre adı kullanalım
            localPropertiesFile.inputStream().use { stream ->
                properties.load(stream)
            }
        }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // Bu sürümleri projenizin ihtiyaçlarına göre kontrol edin veya Flutter'ın önerdiği sürümleri kullanın
    id("com.android.application") version "8.2.2" apply false // Örnek sürüm
    id("org.jetbrains.kotlin.android") version "1.9.23" apply false // Örnek sürüm
}

include(":app")""