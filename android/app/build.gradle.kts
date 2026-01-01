plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.facereq_mobile"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.facereq_mobile"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

   buildTypes {
    debug {
        isMinifyEnabled = false
        isShrinkResources = false
    }

    release {
        isMinifyEnabled = false
        isShrinkResources = false
        signingConfig = signingConfigs.getByName("debug")
    }
}

    aaptOptions {
        noCompress += listOf("tflite", "task")
    }

    packaging {
        resources {
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt"
            )
        }
    }
}

dependencies {

    // 🔥 MediaPipe Vision (Face landmark / liveness)
    implementation("com.google.mediapipe:tasks-vision:0.10.14") {
        exclude(group = "com.google.ai.edge.litert")
    }

    // 🔥 TensorFlow Lite (MobileFaceNet embedding)
    implementation("org.tensorflow:tensorflow-lite:2.14.0")

    // 🔥 CameraX
    val cameraxVersion = "1.3.4"
    implementation("androidx.camera:camera-core:$cameraxVersion")
    implementation("androidx.camera:camera-camera2:$cameraxVersion")
    implementation("androidx.camera:camera-lifecycle:$cameraxVersion")
    implementation("androidx.camera:camera-view:$cameraxVersion")

    // ❌ pastikan TIDAK ada litert masuk
    configurations.all {
        exclude(group = "com.google.ai.edge.litert")
    }
}

flutter {
    source = "../.."
}
