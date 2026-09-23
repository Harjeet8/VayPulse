package com.harjeet.phytosense

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL_NAME = "ai.phytosense.app/notifications"
        private const val NOTIFICATION_CHANNEL_ID = "phytosense_plant_alerts"
        private const val NOTIFICATION_CHANNEL_NAME = "PhytoSense plant alerts"
        private const val PERMISSION_REQUEST_CODE = 7206
    }

    private var carePlatform: CarePlatform? = null
    private var ilaiSpeech: IlaiSpeech? = null

    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()
        carePlatform = CarePlatform(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.harjeet.phytosense/care"))
        ilaiSpeech = IlaiSpeech(this, MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.harjeet.phytosense/speech"))

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> requestNotificationPermission(result)
                "notificationsEnabled" -> result.success(notificationsEnabled())
                "showNotification" -> {
                    showNotification(
                        title = call.argument<String>("title") ?: "PhytoSense AI",
                        body = call.argument<String>("body") ?: "Open PhytoSense AI for details.",
                        severity = call.argument<String>("severity") ?: "warning",
                        summary = call.argument<String>("summary") ?: "",
                        sourceLabel = call.argument<String>("sourceLabel") ?: "",
                        actionLabel = call.argument<String>("actionLabel") ?: "Open PhytoSense",
                        notificationTag = call.argument<String>("notificationTag")
                            ?: "phytosense:current",
                    )
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
            manager.getNotificationChannel(NOTIFICATION_CHANNEL_ID)?.importance == NotificationManager.IMPORTANCE_NONE) return false
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

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            NOTIFICATION_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Plant health and sensor alerts from PhytoSense AI"
            enableVibration(true)
        }

        getSystemService(NotificationManager::class.java)
            .createNotificationChannel(channel)
    }

    private fun notificationBadge(accent: Int): Bitmap {
        val bitmap = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawCircle(48f, 48f, 46f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = accent })
        getDrawable(R.drawable.ic_stat_phytosense)?.mutate()?.apply {
            setTint(Color.WHITE)
            setBounds(20, 18, 76, 74)
            draw(canvas)
        }
        return bitmap
    }

    private fun showNotification(
        title: String,
        body: String,
        severity: String,
        summary: String,
        sourceLabel: String,
        actionLabel: String,
        notificationTag: String,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val contentIntent = launchIntent?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val priority = if (severity.equals("critical", ignoreCase = true)) {
            Notification.PRIORITY_HIGH
        } else {
            Notification.PRIORITY_DEFAULT
        }

        val accent = when (severity.lowercase()) {
            "critical" -> Color.rgb(185, 95, 67)
            "warning" -> Color.rgb(174, 119, 52)
            else -> Color.rgb(29, 104, 77)
        }
        builder
            // Android status bars mask this artwork to a single visible colour.
            // The full-colour launcher icon can become blank here, so always use
            // the dedicated PhytoSense notification silhouette.
            .setSmallIcon(R.drawable.ic_stat_phytosense)
            .setColor(accent)
            .setLargeIcon(notificationBadge(accent))
            .setSubText(sourceLabel)
            .setShowWhen(true)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().setBigContentTitle(title).bigText(body).setSummaryText(summary))
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setPriority(priority)
            .setCategory(Notification.CATEGORY_STATUS)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setGroup("phytosense_plant_health")

        if (contentIntent != null) {
            builder.setContentIntent(contentIntent)
            @Suppress("DEPRECATION")
            builder.addAction(R.drawable.ic_stat_phytosense, actionLabel, contentIntent)
        }

        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(notificationTag, 1001, builder.build())
    }
}
