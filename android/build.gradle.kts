allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.extra.set("compileSdk", 35)
rootProject.extra.set("minSdk", 23)
rootProject.extra.set("targetSdk", 35)
rootProject.extra.set("javaVersion", JavaVersion.VERSION_17)

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
