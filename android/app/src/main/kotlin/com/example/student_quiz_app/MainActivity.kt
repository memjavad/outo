package com.example.student_quiz_app

import android.media.MediaPlayer
import android.content.res.AssetFileDescriptor
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.student_quiz_app/audio"
    private var ambientPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playAmbient" -> {
                    val assetPath = call.argument<String>("asset")
                    val volume = call.argument<Double>("volume")?.toFloat() ?: 1f
                    if (assetPath != null) {
                        try {
                            if (ambientPlayer == null) {
                                ambientPlayer = MediaPlayer()
                            } else {
                                ambientPlayer?.reset()
                            }
                            val descriptor: AssetFileDescriptor = context.assets.openFd("flutter_assets/$assetPath")
                            ambientPlayer?.setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                            descriptor.close()
                            
                            ambientPlayer?.isLooping = true
                            ambientPlayer?.setVolume(volume, volume)
                            ambientPlayer?.prepareAsync()
                            ambientPlayer?.setOnPreparedListener { mp -> mp.start() }
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("AUDIO_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Missing asset argument", null)
                    }
                }
                "playSfx" -> {
                    val assetPath = call.argument<String>("asset")
                    val volume = call.argument<Double>("volume")?.toFloat() ?: 1f
                    if (assetPath != null) {
                        try {
                            val mp = MediaPlayer()
                            val descriptor: AssetFileDescriptor = context.assets.openFd("flutter_assets/$assetPath")
                            mp.setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                            descriptor.close()
                            
                            mp.isLooping = false
                            mp.setVolume(volume, volume)
                            mp.prepareAsync()
                            mp.setOnPreparedListener { it.start() }
                            mp.setOnCompletionListener { it.release() }
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SFX_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Missing asset argument", null)
                    }
                }
                "stopAmbient" -> {
                    ambientPlayer?.stop()
                    ambientPlayer?.release()
                    ambientPlayer = null
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        ambientPlayer?.release()
    }
}
