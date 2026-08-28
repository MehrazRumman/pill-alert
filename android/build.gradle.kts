allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

/**
 * Pin every module — the app and every plugin — to compileSdk 36.
 *
 * The SDK manager installs API 37 into a directory called `android-37.0` (Android's new
 * minor-version platform naming), but a module asking for `compileSdk = 37` looks for the hash
 * string `android-37` and fails to find it. Plugins that have already moved to 37 therefore break
 * the build on a machine where 37 is installed. 36 is present, is what the Kotlin build compiles
 * against, and every plugin here compiles cleanly on it.
 */
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.api.dsl.LibraryExtension>("android") {
            compileSdk = 36
        }
    }
    plugins.withId("com.android.application") {
        extensions.configure<com.android.build.api.dsl.ApplicationExtension>("android") {
            compileSdk = 36
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
