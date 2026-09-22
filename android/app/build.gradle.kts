import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// La clé de publication ne vit jamais dans le dépôt : `android/key.properties`
// et le fichier .jks sont exclus par .gitignore. Quand le fichier est là, la
// variante release est signée avec ; quand il n'y est pas — intégration
// continue, machine neuve, contributeur de passage — on retombe sur la clé de
// debug pour que `flutter run --release` et `flutter build apk` continuent de
// marcher. Un bundle signé pour la boutique ne sort donc que d'une machine qui
// a la clé, et c'est voulu.
val cleDePublication = Properties().apply {
    val fichier = rootProject.file("key.properties")
    if (fichier.exists()) fichier.inputStream().use { load(it) }
}
val signeePourLaBoutique = cleDePublication.getProperty("storeFile") != null

android {
    namespace = "sn.palabre.president"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Le même identifiant que sur l'App Store : une seule application,
        // deux boutiques.
        applicationId = "sn.palabre.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (signeePourLaBoutique) {
            create("publication") {
                storeFile = rootProject.file(cleDePublication.getProperty("storeFile"))
                storePassword = cleDePublication.getProperty("storePassword")
                keyAlias = cleDePublication.getProperty("keyAlias")
                keyPassword = cleDePublication.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (signeePourLaBoutique) {
                signingConfigs.getByName("publication")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
