allprojects {
    repositories {
        google()
        mavenCentral()

        // ✅ Start.io SDK repo
        maven { url = uri("https://repo.start.io/artifactory/publisher-sdk") }
    }
}

// 🔥 Custom build directory (optional but fine)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

// Apply same build dir for subprojects
subprojects {
    layout.buildDirectory.value(newBuildDir.dir(name))
}

// Ensure app module builds first
subprojects {
    evaluationDependsOn(":app")
}

// Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}