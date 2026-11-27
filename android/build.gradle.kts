allprojects { repositories { google(); mavenCentral() } }
val sharedBuildDir = rootProject.layout.projectDirectory.dir("../build")
rootProject.layout.buildDirectory.set(sharedBuildDir)
subprojects { project.layout.buildDirectory.set(sharedBuildDir.dir(project.name)) }
subprojects { evaluationDependsOn(":app") }
tasks.register<Delete>("clean") { delete(rootProject.layout.buildDirectory) }
