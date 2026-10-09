package com.harjeet.phytosense

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL_NAME = "ai.phytosense.app/notifications"
        private const val PERMISSION_REQUEST_CODE = 7206
    }

    private var carePlatform: CarePlatform? = null
    private var ilaiSpeech: IlaiSpeech? = null
    private var nodeWifiHttp: NodeWifiHttp? = null

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        PhytoNotifications.ensureChannels(this)
        carePlatform = CarePlatform(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.harjeet.phytosense/care"))
        ilaiSpeech = IlaiSpeech(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.harjeet.phytosense/speech"))
        nodeWifiHttp = NodeWifiHttp(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.harjeet.phytosense/node_http"))
        AppIntegrity.register(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.harjeet.phytosense/integrity"))

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> requestNotificationPermission(result)
                "notificationsEnabled" -> result.success(notificationsEnabled())
                "showNotification" -> {
                    PhytoNotifications.show(this, PlantAlert(
                        title = call.argument<String>("title") ?: "VayPulse",
                        body = call.argument<String>("body") ?: "Open VayPulse for details.",
                        severity = call.argument<String>("severity") ?: "warning",
                        summary = call.argument<String>("summary") ?: "",
                        sourceLabel = call.argument<String>("sourceLabel") ?: "",
                        actionLabel = call.argument<String>("actionLabel") ?: "Open VayPulse",
                        tag = call.argument<String>("notificationTag") ?: "phytosense:current",
                        healthScore = call.argument<Number>("healthScore")?.toInt()?.takeIf { it >= 0 },
                        tamil = call.argument<Boolean>("tamil") ?: false,
                        snoozed = false,
                    ))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (carePlatform?.onResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }
    override fun onStop() {
        ilaiSpeech?.cancel()
        carePlatform?.stopAudio()
        super.onStop()
    }

    override fun onDestroy() {
        ilaiSpeech?.dispose()
        super.onDestroy()
    }

    private fun notificationsEnabled(): Boolean {
        val manager = getSystemService(NotificationManager::class.java)
        if (!manager.areNotificationsEnabled()) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            PhytoNotifications.allChannels.all {
                manager.getNotificationChannel(it)?.importance == NotificationManager.IMPORTANCE_NONE
            }) return false
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(notificationsEnabled())
            return
        }

        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(notificationsEnabled())
            return
        }

        pendingPermissionResult?.success(false)
        pendingPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            PERMISSION_REQUEST_CODE,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (ilaiSpeech?.permissionResult(requestCode, grantResults) == true) return
        if (requestCode != PERMISSION_REQUEST_CODE) return

        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }
}
