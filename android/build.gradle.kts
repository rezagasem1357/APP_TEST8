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

// حل مشکل تداخل Namespace ماژول‌های tflite در Kotlin DSL
subprojects {
    plugins.withId("com.android.library") {
        val android = extensions.findByType(com.android.build.gradle.LibraryExtension::class.java)
        if (android != null && android.namespace == null) {
            android.namespace = project.group.toString().ifEmpty { "com.fix.namespace.${project.name}" }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
