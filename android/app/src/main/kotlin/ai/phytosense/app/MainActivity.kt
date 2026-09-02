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
import android.graphics.drawable.Icon
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
                            title = call.argument<String>("title") ?: "Plant intelligence update",
                            body = call.argument<String>("body")
                                ?: "PhytoSense detected a meaningful plant change.",
                            mode = call.argument<String>("mode") ?: "simulation",
                            severity = call.argument<String>("severity") ?: "warning",
                            sequence = call.argument<Int>("sequence") ?: 1,
                            summary = call.argument<String>("summary") ?: "Plant intelligence",
                            notificationTag = call.argument<String>("notificationTag")
                                ?: "phytosense:update",
                            actionLabel = call.argument<String>("actionLabel") ?: "Open PhytoSense",
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
        sequence: Int,
        summary: String,
        notificationTag: String,
        actionLabel: String,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val live = mode == "esp32"
        val channelId = if (live) {
            "phytosense_live_intelligence_v2"
        } else {
            "phytosense_simulation_intelligence_v2"
        }
        val channelName = if (live) {
            "PhytoSense Live Plant Intelligence"
        } else {
            "PhytoSense Simulation Intelligence"
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    channelId,
                    channelName,
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply {
                    description = if (live) {
                        "Important plant decisions from live ESP32 sensing"
                    } else {
                        "Important plant decisions from PhytoSense simulation"
                    }
                    enableVibration(true)
                    enableLights(true)
                    setShowBadge(true)
                    lockscreenVisibility = Notification.VISIBILITY_PRIVATE
                },
            )
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        launchIntent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        launchIntent.putExtra("phytosense_destination", "analysis")
        val requestCode = if (live) 4100 + sequence else 3100 + sequence
        val pendingIntent = PendingIntent.getActivity(
            this,
            requestCode,
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
            "critical" -> Color.rgb(239, 68, 68)
            "info" -> Color.rgb(22, 201, 107)
            else -> Color.rgb(245, 158, 11)
        }
        val safeTitle = title.replace("_", " ").trim()
        val safeBody = body.replace("_", " ").trim()
        val richStyle = Notification.BigTextStyle()
            .setBigContentTitle(safeTitle)
            .bigText(safeBody)
            .setSummaryText(summary)

        builder
            .setSmallIcon(R.drawable.ic_stat_phytosense)
            .setColor(accent)
            .setContentTitle(safeTitle)
            .setContentText(safeBody)
            .setSubText(summary)
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
            .setNumber(sequence)
            .addAction(0, actionLabel, pendingIntent)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            builder.setLargeIcon(
                Icon.createWithResource(this, R.drawable.ic_launcher_nova),
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            builder.setBadgeIconType(Notification.BADGE_ICON_SMALL)
            builder.setColorized(severity == "critical")
        } else {
            @Suppress("DEPRECATION")
            builder.setPriority(Notification.PRIORITY_HIGH)
            @Suppress("DEPRECATION")
            builder.setVibrate(longArrayOf(0, 180, 90, 180))
            @Suppress("DEPRECATION")
            builder.setLights(accent, 500, 1500)
        }

        // The tag is stable for each condition type. A later update to the same
        // condition replaces its older card instead of stacking duplicates.
        val notificationId = if (live) 2400 else 1400
        manager.notify(notificationTag, notificationId, builder.build())
    }
}
