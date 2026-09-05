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
    // flutter_inappwebview_android uses the deprecated proguard-android.txt.
    // Suppress the AGP error so the build proceeds until the plugin is updated.
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.android.tools.build" && requested.name == "gradle") {
                because("suppress proguard-android.txt deprecation error in plugins")
            }
        }
    }
    if (project.name != "app") {
        afterEvaluate {
            val androidExt = extensions.findByName("android")
                as? com.android.build.api.dsl.CommonExtension
                ?: return@afterEvaluate
            androidExt.compileSdk = maxOf(androidExt.compileSdk ?: 0, 37)
            // Suppress the deprecated proguard-android.txt error in plugin subprojects
            (androidExt as? com.android.build.gradle.BaseExtension)
                ?.lintOptions
                ?.isAbortOnError = false
        }
    }
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
