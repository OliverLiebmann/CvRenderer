plugins {
    id("java")
    id("com.github.johnrengelman.shadow") version "8.1.1"
}

group = "org.example"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
    maven {
        name = "GitHubPackages"
        url = uri("https://maven.pkg.github.com/talentbasis/JavaCV")
        credentials {
            username = "Oliver"
            password = "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"
//				username = System.getenv("GITHUB_ACTOR")
//                password = System.getenv("GITHUB_TOKEN")
        }
    }
}

dependencies {
    implementation("com.amazonaws:aws-lambda-java-core:1.2.2")
    implementation("com.amazonaws:aws-lambda-java-events:3.11.1")
    implementation("tech.talentbase.cv:cv-rendering-engine:1.2.18")
    runtimeOnly("com.amazonaws:aws-lambda-java-log4j2:1.5.1")
}