package com.screengenie.screengenie

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Handler
import android.os.Looper
import android.util.DisplayMetrics
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "screengenie/capture"
        private const val REQUEST_MEDIA_PROJECTION = 1001
    }

    private var projectionManager: MediaProjectionManager? = null
    private var mediaProjection: MediaProjection? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        projectionManager =
            getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "captureScreen" -> {
                    if (mediaProjection != null) {
                        captureScreen(result)
                    } else {
                        pendingResult = result
                        startActivityForResult(
                            projectionManager!!.createScreenCaptureIntent(),
                            REQUEST_MEDIA_PROJECTION
                        )
                    }
                }
                "hasProjection" -> {
                    result.success(mediaProjection != null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_MEDIA_PROJECTION) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                mediaProjection = projectionManager!!.getMediaProjection(resultCode, data)
                pendingResult?.let { captureScreen(it) }
            } else {
                pendingResult?.error("PERMISSION_DENIED", "MediaProjection permission denied", null)
            }
            pendingResult = null
        }
    }

    private fun captureScreen(result: MethodChannel.Result) {
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        windowManager.defaultDisplay.getMetrics(metrics)
        val width = metrics.widthPixels
        val height = metrics.heightPixels
        val density = metrics.densityDpi

        val imageReader = ImageReader.newInstance(width, height, PixelFormat.RGBA_8888, 2)
        val virtualDisplay: VirtualDisplay? = mediaProjection!!.createVirtualDisplay(
            "ScreenGenie",
            width, height, density,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader.surface, null, null
        )

        // Delay to allow the virtual display to render a frame
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                val image = imageReader.acquireLatestImage()
                if (image != null) {
                    val planes = image.planes
                    val buffer = planes[0].buffer
                    val pixelStride = planes[0].pixelStride
                    val rowStride = planes[0].rowStride
                    val rowPadding = rowStride - pixelStride * width

                    val bitmap = Bitmap.createBitmap(
                        width + rowPadding / pixelStride,
                        height,
                        Bitmap.Config.ARGB_8888
                    )
                    bitmap.copyPixelsFromBuffer(buffer)
                    image.close()

                    // Crop to actual screen size (remove padding)
                    val croppedBitmap = if (rowPadding > 0) {
                        Bitmap.createBitmap(bitmap, 0, 0, width, height).also {
                            bitmap.recycle()
                        }
                    } else {
                        bitmap
                    }

                    // Save to internal storage
                    val file = File(filesDir, "screenshot.png")
                    FileOutputStream(file).use { out ->
                        croppedBitmap.compress(Bitmap.CompressFormat.PNG, 85, out)
                    }
                    croppedBitmap.recycle()
                    virtualDisplay?.release()
                    imageReader.close()

                    result.success(file.absolutePath)
                } else {
                    virtualDisplay?.release()
                    imageReader.close()
                    result.error("CAPTURE_FAILED", "No image available", null)
                }
            } catch (e: Exception) {
                virtualDisplay?.release()
                imageReader.close()
                result.error("CAPTURE_ERROR", e.message, null)
            }
        }, 300)
    }
}
