package ai.phytosense.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "ai.phytosense.app/notifications"
        private const val REQUEST_NOTIFICATIONS = 7310
    }

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> requestNotificationPermission(result)
                    "showNotification" -> {
                        showNotification(
                            title = call.argument<String>("title") ?: "🌿 Plant update",
                            body = call.argument<String>("body") ?: "PhytoSense detected a meaningful change.",
                            mode = call.argument<String>("mode") ?: "simulation",
                            severity = call.argument<String>("severity") ?: "warning",
                            slot = call.argument<Int>("slot") ?: 1,
                            summary = call.argument<String>("summary") ?: "PhytoSense AI",
                        )
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestNotificationPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }

        if (pendingPermissionResult != null) {
            result.success(false)
            return
        }
        pendingPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_NOTIFICATIONS,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_NOTIFICATIONS) return
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
    }

    private fun showNotification(
        title: String,
        body: String,
        mode: String,
        severity: String,
        slot: Int,
        summary: String,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val live = mode == "esp32"
        val channelId = if (live) "phytosense_live" else "phytosense_simulation"
        val channelName = if (live) "PhytoSense Live" else "PhytoSense Simulation"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    channelId,
                    channelName,
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = if (live) {
                        "Important plant intelligence from live ESP32 values"
                    } else {
                        "Important plant intelligence from Simulation mode"
                    }
                    enableVibration(true)
                    setShowBadge(true)
                    lockscreenVisibility = Notification.VISIBILITY_PRIVATE
                },
            )
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        launchIntent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        val pendingIntent = PendingIntent.getActivity(
            this,
            if (live) 4100 + slot else 3100 + slot,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, channelId)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val accent = when (severity) {
            "critical" -> Color.rgb(244, 67, 54)
            "info" -> Color.rgb(22, 201, 107)
            else -> Color.rgb(25, 118, 210)
        }
        val safeTitle = title.replace("_", " ").trim()
        val safeBody = body.replace("_", " ").trim()
        val modeLabel = if (live) "Live value" else "Simulation"
        val richStyle = Notification.BigTextStyle()
            .setBigContentTitle(safeTitle)
            .bigText(safeBody)
            .setSummaryText("PhytoSense AI • $summary")

        builder
            .setSmallIcon(R.drawable.ic_stat_phytosense)
            .setColor(accent)
            .setContentTitle(safeTitle)
            .setContentText(safeBody)
            .setSubText("PhytoSense AI • $modeLabel")
            .setStyle(richStyle)
            .setCategory(Notification.CATEGORY_MESSAGE)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setVisibility(Notification.VISIBILITY_PRIVATE)
            .setGroup("phytosense.$mode")
            .setWhen(System.currentTimeMillis())
            .setShowWhen(true)
            .setTicker("$safeTitle — $safeBody")
            .setNumber(slot.coerceIn(1, 2))

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setBadgeIconType(Notification.BADGE_ICON_SMALL)
            builder.setColorized(false)
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            builder.setPriority(Notification.PRIORITY_HIGH)
        }

        val idBase = if (live) 2400 else 1400
        manager.notify(idBase + slot.coerceIn(1, 2), builder.build())
    }
}
