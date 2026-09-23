package com.harjeet.phytosense

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import io.flutter.plugin.common.MethodChannel

/** Short, user-started speech sessions. No recording files or background mic. */
class IlaiSpeech(private val activity: Activity, private val channel: MethodChannel) {
    private var pending: MethodChannel.Result? = null
    private var recognizer: SpeechRecognizer? = null
    private var language = "en-IN"
    private var generation = 0
    private val handler = Handler(Looper.getMainLooper())
    companion object { const val PERMISSION = 8410 }
    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "listen" -> {
                    if (pending != null) {
                        result.error("busy", "Already listening", null)
                    } else if (!SpeechRecognizer.isRecognitionAvailable(activity)) {
                        result.error("unavailable", "Speech recognition is unavailable", null)
                    } else {
                        pending = result
                        language = if (call.argument<String>("language") == "ta") "ta-IN" else "en-IN"
                        if (activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                            activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), PERMISSION)
                        } else start()
                    }
                }
                "cancel" -> { cancel(); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }
    fun permissionResult(code: Int, results: IntArray): Boolean {
        if (code != PERMISSION) return false
        if (pending != null) {
            if (results.isNotEmpty() && results[0] == PackageManager.PERMISSION_GRANTED) start()
            else finish(error = "permission")
        }
        return true
    }
    private fun start() {
        val ticket = ++generation
        try {
            val speech = SpeechRecognizer.createSpeechRecognizer(activity)
            recognizer = speech
            speech.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) {
                    if (ticket == generation) channel.invokeMethod("state", "listening")
                }
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {
                    if (ticket == generation) channel.invokeMethod("state", "processing")
                }
                override fun onError(error: Int) {
                    if (ticket == generation) finish(error = when (error) {
                        SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "permission"
                        SpeechRecognizer.ERROR_NO_MATCH, SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "no_speech"
                        else -> "unavailable"
                    })
                }
                override fun onResults(results: Bundle?) {
                    if (ticket == generation) finish(text = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.take(500))
                }
                override fun onPartialResults(partialResults: Bundle?) {}
                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
            speech.startListening(Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
                putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
                putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            })
            handler.postDelayed({ if (ticket == generation) finish(error = "no_speech") }, 20000)
        } catch (_: Exception) { finish(error = "unavailable") }
    }
    private fun finish(text: String? = null, error: String? = null) {
        val result = pending
        pending = null
        generation++
        handler.removeCallbacksAndMessages(null)
        val speech = recognizer
        recognizer = null
        try { speech?.cancel(); speech?.destroy() } catch (_: Exception) {}
        if (error == null) result?.success(text) else result?.error(error, error, null)
    }
    fun cancel() { finish() }
    fun dispose() { cancel(); channel.setMethodCallHandler(null) }
}
