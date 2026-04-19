allprojects {
    repositories {
        google()
        mavenCentral()
    }
    configurations.all {
        resolutionStrategy {
            force("androidx.core:core:1.13.1")
            force("androidx.core:core-ktx:1.13.1")
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

subprojects {
    // Fix for AGP 8.x: Inject namespace for plugins that don't specify it
    // And handle legacy v1 embedding support
    if (project.name != "app") {
        project.afterEvaluate {
            if (project.hasProperty("android")) {
                val androidExtension = project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
                // Force compileSdk AFTER the plugin evaluates itself to prevent it overwriting us back to SDK 28
                // Using 36 to support modern plugins requiring VANILLA_ICE_CREAM (API 35) while fixing AAPT lStar
                androidExtension.compileSdk = 36
            }
        }
        project.plugins.whenPluginAdded {
            if (this is com.android.build.gradle.LibraryPlugin) {
                val androidExtension = project.extensions.getByType(com.android.build.gradle.LibraryExtension::class.java)
                
                // 1. Fix Namespace
                val getNamespace = androidExtension.javaClass.getMethod("getNamespace")
                val setNamespace = androidExtension.javaClass.getMethod("setNamespace", String::class.java)
                
                val currentNamespace = getNamespace.invoke(androidExtension)
                if (currentNamespace == null) {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val xml = groovy.xml.XmlParser().parse(manifestFile)
                        val packageName = xml.attribute("package")?.toString()
                        if (packageName != null) {
                            println("Injecting namespace $packageName for plugin ${project.name}")
                            setNamespace.invoke(androidExtension, packageName)
                        }
                    }
                }
                
                // 2. Fix for v1 embedding (Registrar)
                // We provide the local flutter.jar from the SDK to plugins that need it
                val properties = java.util.Properties()
                val localPropertiesFile = project.rootProject.file("local.properties")
                if (localPropertiesFile.exists()) {
                    localPropertiesFile.inputStream().use { properties.load(it) }
                }
                val flutterRoot = properties.getProperty("flutter.sdk") ?: (rootProject.projectDir.path + "/../..")
                val engineArtifactsDir = "$flutterRoot/bin/cache/artifacts/engine/android-arm-release"
                val flutterJar = project.file("$engineArtifactsDir/flutter.jar")
                
                if (flutterJar.exists()) {
                    project.dependencies.add("compileOnly", project.files(flutterJar))
                } else {
                    // Fallback to a generic dependency if local jar is not found for some reason
                    project.dependencies.add("compileOnly", "io.flutter:flutter_embedding_release:1.0.0-e672b006455c717056008779836967b57ad49141")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
