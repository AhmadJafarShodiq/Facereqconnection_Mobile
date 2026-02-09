package com.example.facereq_mobile

import android.graphics.*
import android.os.SystemClock
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.*
import com.google.mediapipe.tasks.components.containers.NormalizedLandmark
import org.tensorflow.lite.Interpreter
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.abs

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "face_recognition"

    private lateinit var liveFaceLandmarker: FaceLandmarker
    private lateinit var imageFaceLandmarker: FaceLandmarker
    private lateinit var interpreter: Interpreter

    // 🔥 MODE: register | absen
    private var mode: String = "register"

    private var blinkState = 0
    private var blinkPassed = false
    private var headPassed = false
    private var lastYaw: Float? = null

    private var lastLandmarks: List<NormalizedLandmark>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        interpreter = Interpreter(loadModel("mobilefacenet.tflite"))
        initLiveLandmarker()
        initImageLandmarker()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "setMode" -> {
                        mode = call.argument<String>("mode") ?: "register"
                        resetLiveness()
                        result.success(true)
                    }

                    "resetLiveness" -> {
                        resetLiveness()
                        result.success(true)
                    }

                    "processFrame" -> {
                        val bytes = call.argument<ByteArray>("image")
                            ?: return@setMethodCallHandler result.error("NO_IMAGE", null, null)

                        val bitmap = fixRotation(
                            BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                        )

                        processLiveness(bitmap)

                        val landmarks = lastLandmarks?.map {
                            mapOf("x" to it.x(), "y" to it.y())
                        }

                        val livenessOk = when (mode) {
                            "register" -> blinkPassed && headPassed
                            "absen" -> true
                            else -> false
                        }

                        result.success(
                            mapOf(
                                "blink" to blinkPassed,
                                "head" to headPassed,
                                "liveness" to livenessOk,
                                "landmarks" to landmarks
                            )
                        )
                    }

                    "getEmbedding" -> {
                        if (mode == "register" && !(blinkPassed && headPassed)) {
                            return@setMethodCallHandler result.error("LIVENESS_FAIL", null, null)
                        }

                        val bytes = call.argument<ByteArray>("image")
                            ?: return@setMethodCallHandler result.error("NO_IMAGE", null, null)

                        val bitmap = fixRotation(
                            BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                        )

                        val face = cropFace(bitmap)
                            ?: return@setMethodCallHandler result.error("NO_FACE", null, null)

                        result.success(mapOf("embedding" to getEmbedding(face)))
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // ================= LANDMARK =================

    private fun initLiveLandmarker() {
        liveFaceLandmarker = FaceLandmarker.createFromOptions(
            this,
            FaceLandmarker.FaceLandmarkerOptions.builder()
                .setBaseOptions(
                    BaseOptions.builder()
                        .setModelAssetPath("face_landmarker.task")
                        .build()
                )
                .setRunningMode(RunningMode.LIVE_STREAM)
                .setNumFaces(1)
                .setResultListener { result, _ -> handleLandmark(result) }
                .build()
        )
    }

    private fun initImageLandmarker() {
        imageFaceLandmarker = FaceLandmarker.createFromOptions(
            this,
            FaceLandmarker.FaceLandmarkerOptions.builder()
                .setBaseOptions(
                    BaseOptions.builder()
                        .setModelAssetPath("face_landmarker.task")
                        .build()
                )
                .setRunningMode(RunningMode.IMAGE)
                .setNumFaces(1)
                .build()
        )
    }

    private fun processLiveness(bitmap: Bitmap) {
        val image = BitmapImageBuilder(bitmap).build()
        liveFaceLandmarker.detectAsync(image, SystemClock.uptimeMillis())
    }

    private fun handleLandmark(result: FaceLandmarkerResult) {
        if (result.faceLandmarks().isEmpty()) return
        val l = result.faceLandmarks()[0]
        lastLandmarks = l

        if (mode == "register") {
            if (!blinkPassed) blinkPassed = checkBlink(l)
            if (!headPassed) headPassed = checkHeadMove(l)
        }
    }

    // ================= LIVENESS =================

    private fun checkBlink(l: List<NormalizedLandmark>): Boolean {
        val left = abs(l[159].y() - l[145].y())
        val right = abs(l[386].y() - l[374].y())
        val closed = left < 0.03f && right < 0.03f

        return when (blinkState) {
            0 -> { if (!closed) blinkState = 1; false }
            1 -> { if (closed) blinkState = 2; false }
            2 -> !closed
            else -> true
        }
    }

    private fun checkHeadMove(l: List<NormalizedLandmark>): Boolean {
        val yaw = abs(l[234].x() - l[454].x())
        if (lastYaw == null) {
            lastYaw = yaw
            return false
        }
        val moved = abs(yaw - lastYaw!!) > 0.03f
        lastYaw = yaw
        return moved
    }

    private fun resetLiveness() {
        blinkState = 0
        blinkPassed = false
        headPassed = false
        lastYaw = null
        lastLandmarks = null
    }

    // ================= FACE =================

   private fun cropFace(bitmap: Bitmap): Bitmap? {
    val image = BitmapImageBuilder(bitmap).build()
    val result = imageFaceLandmarker.detect(image)

    if (result.faceLandmarks().isEmpty()) {
        Log.e("CropFace", "No face detected")
        return null
    }

    val l = result.faceLandmarks()[0]
    var minX = 1f; var minY = 1f; var maxX = 0f; var maxY = 0f

    l.forEach {
        minX = minOf(minX, it.x())
        minY = minOf(minY, it.y())
        maxX = maxOf(maxX, it.x())
        maxY = maxOf(maxY, it.y())
    }

    val x = (minX * bitmap.width).toInt().coerceAtLeast(0)
    val y = (minY * bitmap.height).toInt().coerceAtLeast(0)
    val w = ((maxX - minX) * bitmap.width).toInt()
    val h = ((maxY - minY) * bitmap.height).toInt()

    // 🔥 CEK VALIDITAS
    if (w <= 0 || h <= 0 || x + w > bitmap.width || y + h > bitmap.height) {
        Log.e("CropFace", "Invalid bounding box: x=$x y=$y w=$w h=$h bitmapWidth=${bitmap.width} bitmapHeight=${bitmap.height}")
        return null
    }

    return Bitmap.createBitmap(bitmap, x, y, w, h)
}

    private fun fixRotation(bitmap: Bitmap): Bitmap {
        val matrix = Matrix().apply { postRotate(270f) }
        return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, matrix, true)
    }

    private fun loadModel(name: String): ByteBuffer =
        assets.open(name).readBytes().let {
            ByteBuffer.allocateDirect(it.size)
                .order(ByteOrder.nativeOrder())
                .put(it)
                .apply { rewind() }
        }

    private fun getEmbedding(bitmap: Bitmap): List<Double> {
        val input = ByteBuffer.allocateDirect(1 * 112 * 112 * 3 * 4)
            .order(ByteOrder.nativeOrder())

        val resized = Bitmap.createScaledBitmap(bitmap, 112, 112, true)

        for (y in 0 until 112)
            for (x in 0 until 112) {
                val p = resized.getPixel(x, y)
                input.putFloat(((p shr 16 and 0xFF) - 128f) / 128f)
                input.putFloat(((p shr 8 and 0xFF) - 128f) / 128f)
                input.putFloat(((p and 0xFF) - 128f) / 128f)
            }

        val output = Array(1) { FloatArray(192) }
        interpreter.run(input, output)
        return output[0].map { it.toDouble() }
    }
}
