allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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

subprojects {
    val configureNamespace: () -> Unit = {
        if (plugins.hasPlugin("com.android.library") || plugins.hasPlugin("com.android.application")) {
            try {
                val android = extensions.findByName("android")
                if (android != null) {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                    if (getNamespace.invoke(android) == null) {
                        val manifestFile = file("src/main/AndroidManifest.xml")
                        var packageName: String? = null
                        if (manifestFile.exists()) {
                            val text = manifestFile.readText()
                            val match = Regex("""package\s*=\s*["']([^"']+)["']""").find(text)
                            packageName = match?.groupValues?.get(1)
                        }
                        if (packageName == null) {
                            val cleanName = project.name.toLowerCase().replace(Regex("[^a-z0-9_]"), "_")
                            packageName = "com.example.$cleanName"
                        }
                        setNamespace.invoke(android, packageName)
                    }
                }
            } catch (e: Exception) {
                // Safe fallback for older AGP versions or reflection errors
            }
        }
    }

    if (state.executed) {
        configureNamespace()
    } else {
        afterEvaluate {
            configureNamespace()
        }
    }
}


