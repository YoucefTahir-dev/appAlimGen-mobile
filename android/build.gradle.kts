allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.configureEach {
        resolutionStrategy.eachDependency {
            // Flutter's integration_test plugin still exposes dynamic AndroidX
            // versions. Pin them for deterministic and offline-friendly builds.
            when (requested.group to requested.name) {
                "androidx.test" to "runner" -> useVersion("1.3.0")
                "androidx.test" to "rules" -> useVersion("1.2.0")
                "androidx.test.espresso" to "espresso-core" -> useVersion("3.3.0")
            }
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
