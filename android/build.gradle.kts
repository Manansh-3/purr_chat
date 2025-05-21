import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

// Buildscript block to add Google Services classpath
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Make sure to use the latest version of google-services plugin
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Custom build directory outside the project folder
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)

    evaluationDependsOn(":app")
}

// Clean task to delete the new build directory
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
