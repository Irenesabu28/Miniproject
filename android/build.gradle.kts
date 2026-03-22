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
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            try {
                // If namespace is null, set it based on the project path
                val namespaceMethod = android::class.java.getMethod("setNamespace", String::class.java)
                val currentNamespace = android::class.java.getMethod("getNamespace").invoke(android)
                if (currentNamespace == null) {
                    val namespace = project.group.toString().ifBlank { "io.github.ruslo.flutter_bluetooth_serial" }
                    namespaceMethod.invoke(android, namespace)
                }
            } catch (e: Exception) {
                // Fail silently if AGP version doesn't support this
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
