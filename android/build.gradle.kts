// android/app/build.gradle.kts (DOĞRU DOSYA)

// Bu bloğun en başta olması önemlidir
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin'i
}

// Flutter'ın yerel özellikleri okuması için
fun localProperties(): Properties {
    val properties = Properties()
    val localPropertiesFile = rootProject.file("local.properties") // android/local.properties
    if (localPropertiesFile.exists()) {
        properties.load(localPropertiesFile.reader())
    }
    return properties
}
val flutterProperties = localProperties()
val flutterRoot: String = flutterProperties.getProperty("flutter.sdk")
    ?: throw GradleException("Flutter SDK not found. Define location with flutter.sdk in the local.properties file.")

// Android yapılandırma bloğu
android {
    // Uygulama kimliği (paket adı)
    namespace = "com.example.kitap_takas_app" // Kendi paket adınla değiştirmen gerekebilir

    // Flutter tarafından yönetilen SDK sürümleri
    compileSdk = flutter.compileSdkVersion // flutter değişkeni plugin sayesinde gelir

    // ----> NDK Sürümünü Buraya Ekle <----
    ndkVersion = "27.0.12077973"

    // Kotlin compile seçenekleri
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    // Kotlin seçenekleri
    kotlinOptions {
        jvmTarget = "1.8"
    }

    // Kaynak setleri (varsayılan)
    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    // Varsayılan yapılandırma
    defaultConfig {
        applicationId = "com.example.kitap_takas_app" // Kendi paket adınla değiştirmen gerekebilir
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterProperties.getProperty("flutter.versionCode")?.toInt() ?: 1
        versionName = flutterProperties.getProperty("flutter.versionName") ?: "1.0"

        // Test runner (varsayılan)
        // testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    // Build tipleri (Debug/Release)
    buildTypes {
        getByName("release") {
            // Flutter release build için kod küçültme ve gizleme
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug") // Geçici olarak debug kullan, release için ayrı config gerekir
        }
    }
}

// Flutter bağımlılıkları
flutter {
    source = "../.." // Flutter projesinin kök dizini
}

// Uygulama bağımlılıkları
dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.23") // Kotlin sürümü uyumlu olmalı
    // Diğer AndroidX veya eklenti bağımlılıkları buraya eklenebilir
    // implementation("androidx.core:core-ktx:1.9.0") vb.
}