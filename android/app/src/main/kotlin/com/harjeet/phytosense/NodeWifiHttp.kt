package com.harjeet.phytosense

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

/**
 * Sends node requests (192.168.4.1 / home IP) over the Wi-Fi network.
 *
 * When the phone is on the node's own Wi-Fi "PhytoSense AI" (no internet),
 * Android keeps mobile data as the default network, so ordinary app requests
 * to 192.168.4.1 leave over mobile data and never arrive.
 *
 * Instead of binding the whole process to Wi-Fi (which would also push the
 * simultaneous Firebase write onto a network without internet), each node
 * request is opened on the Wi-Fi network individually with
 * Network.openConnection. Everything else keeps the default network.
 *
 * Replies {"wifi": false} when no Wi-Fi network exists, so Dart falls back
 * to its normal HTTP client.
 */
class NodeWifiHttp(private val context: Context, channel: MethodChannel) {
    private val executor = Executors.newFixedThreadPool(4)
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "get" -> {
                    val url = call.argument<String>("url")
                    val timeoutMs = call.argument<Int>("timeoutMs") ?: 1500
                    if (url == null) {
                        result.error("bad_args", "url missing", null)
                    } else {
                        executor.execute {
                            val reply = get(url, timeoutMs)
                            main.post { result.success(reply) }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun wifiNetwork(): Network? {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE)
            as? ConnectivityManager ?: return null
        return cm.allNetworks.firstOrNull { network ->
            cm.getNetworkCapabilities(network)
                ?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) == true
        }
    }

    private fun get(url: String, timeoutMs: Int): Map<String, Any?> {
        val network = try {
            wifiNetwork()
        } catch (_: Exception) {
            null
        } ?: return mapOf("wifi" to false)

        var connection: HttpURLConnection? = null
        return try {
            connection = network.openConnection(URL(url)) as HttpURLConnection
            connection.connectTimeout = timeoutMs
            connection.readTimeout = timeoutMs
            connection.useCaches = false
            connection.setRequestProperty("Accept", "application/json")
            val status = connection.responseCode
            val stream = if (status in 200..399) connection.inputStream else connection.errorStream
            val body = stream?.use { it.readBytes().toString(Charsets.UTF_8) } ?: ""
            mapOf("wifi" to true, "status" to status, "body" to body)
        } catch (e: Exception) {
            mapOf("wifi" to true, "error" to (e.message ?: e.javaClass.simpleName))
        } finally {
            connection?.disconnect()
        }
    }
}
