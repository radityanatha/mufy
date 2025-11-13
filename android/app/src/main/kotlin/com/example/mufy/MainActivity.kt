package com.example.mufy

import android.media.MediaScannerConnection
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.mufy/media_scanner"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scanFile" -> {
                    val filePath = call.argument<String>("path")
                    if (filePath != null) {
                        scanMediaFile(filePath)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "File path is null", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun scanMediaFile(filePath: String) {
        try {
            // Gunakan MediaScannerConnection untuk scan file ke MediaStore
            MediaScannerConnection.scanFile(
                this,
                arrayOf(filePath),
                arrayOf("audio/mpeg"),
                null
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
