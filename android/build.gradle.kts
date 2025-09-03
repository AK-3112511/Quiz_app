// Top-level build.gradle.kts

plugins {
    // ✅ Android Gradle Plugin
    id("com.android.application") version "8.9.1" apply false
    id("com.android.library") apply false   // no version

    // ✅ Kotlin → let Flutter handle
    id("org.jetbrains.kotlin.android") apply false

    // ✅ Firebase Google Services → no version (avoid conflict)
    id("com.google.gms.google-services") apply false

    // ✅ Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = file("../build")

subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
    project.evaluationDependsOn(":app")
}


tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
