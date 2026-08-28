plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.nirbhor.flutter"
    // Pinned rather than taken from `flutter.compileSdkVersion`: the toolchain resolves that to
    // API 37, whose platform installs under the directory name `android-37.0`, and Gradle then
    // fails to find a target with the hash string `android-37`. 36 is installed and is what the
    // Kotlin build compiles against.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications schedules with java.time, which needs desugaring below API 26
        // APIs even though minSdk is 26.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Distinct from the Kotlin build's com.nirbhor.app so both can sit on one device while
        // the port is compared against the original.
        applicationId = "com.nirbhor.flutter"
        // Matches the Kotlin build: variable-font weight axes and the alarm/notification APIs the
        // app relies on all need 26.
        minSdk = 26
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
