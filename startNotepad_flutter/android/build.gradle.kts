allprojects {
    repositories {
        // Mirrors first (fallback to official repos). Helps when dl.google.com TLS handshake fails.
        maven(url = "https://maven.aliyun.com/repository/google")
        maven(url = "https://maven.aliyun.com/repository/central")
        maven(url = "https://mirrors.tencent.com/nexus/repository/maven-public/")

        google()
        mavenCentral()
    }
}

subprojects {
    // Some Flutter plugins still use legacy `buildscript {}` classpath resolution.
    // Ensure they also use mirrors; otherwise Gradle may try dl.google.com and fail TLS handshake.
    buildscript {
        repositories {
            maven(url = "https://maven.aliyun.com/repository/google")
            maven(url = "https://maven.aliyun.com/repository/central")
            maven(url = "https://mirrors.tencent.com/nexus/repository/maven-public/")

            google()
            mavenCentral()
            gradlePluginPortal()
        }
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
