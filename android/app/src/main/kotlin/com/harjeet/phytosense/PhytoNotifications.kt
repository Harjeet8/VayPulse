package com.harjeet.phytosense

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationChannelGroup
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.drawable.Icon
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle

/** One plant alert, as sent from Dart (or re-posted after a snooze). */
data class PlantAlert(
    val title: String,
    val body: String,
    val severity: String, // critical | warning | info
    val summary: String,
    val sourceLabel: String,
    val actionLabel: String,
    val tag: String,
    val healthScore: Int?,
    val tamil: Boolean,
    val snoozed: Boolean,
) {
    fun toBundle(tagOverride: String = tag, snoozedOverride: Boolean = snoozed) = Bundle().apply {
        putString("title", title)
        putString("body", body)
        putString("severity", severity)
        putString("summary", summary)
        putString("sourceLabel", sourceLabel)
        putString("actionLabel", actionLabel)
        putString("tag", tagOverride)
        putInt("healthScore", healthScore ?: -1)
        putBoolean("tamil", tamil)
        putBoolean("snoozed", snoozedOverride)
    }

    companion object {
        fun fromBundle(b: Bundle) = PlantAlert(
            title = b.getString("title") ?: "VayPulse",
            body = b.getString("body") ?: "",
            severity = b.getString("severity") ?: "warning",
            summary = b.getString("summary") ?: "",
            sourceLabel = b.getString("sourceLabel") ?: "",
            actionLabel = b.getString("actionLabel") ?: "Open VayPulse",
            tag = b.getString("tag") ?: "phytosense:current",
            healthScore = b.getInt("healthScore", -1).takeIf { it >= 0 },
            tamil = b.getBoolean("tamil", false),
            snoozed = b.getBoolean("snoozed", false),
        )
    }
}

/**
 * Plant-health notifications in three levels, each with its own sound and
 * vibration, a health ring on the large icon, and "Got it" / "Remind in 1 h"
 * buttons.
 */
object PhytoNotifications {
    const val GROUP = "phytosense_plant_health"
    const val CRITICAL = "phytosense_alerts_critical"
    const val ATTENTION = "phytosense_alerts_attention"
    const val ADVICE = "phytosense_alerts_advice"
    private const val LEGACY_CHANNEL = "phytosense_plant_alerts"
    private const val NOTIFICATION_ID = 1001

    const val ACTION_DISMISS = "com.harjeet.phytosense.notification.DISMISS"
    const val ACTION_SNOOZE = "com.harjeet.phytosense.notification.SNOOZE"
    const val ACTION_REPOST = "com.harjeet.phytosense.notification.REPOST"
    private const val SNOOZE_MS = 60 * 60 * 1000L

    private val criticalPattern = longArrayOf(0, 450, 180, 450, 180, 700)
    private val attentionPattern = longArrayOf(0, 260, 140, 260)

    val allChannels = listOf(CRITICAL, ATTENTION, ADVICE)

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannelGroup(NotificationChannelGroup(GROUP, "Plant health"))
        val sound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val audio = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        fun channel(id: String, name: String, description: String, importance: Int,
                    vibration: LongArray?, light: Int) =
            NotificationChannel(id, name, importance).apply {
                this.description = description
                group = GROUP
                enableLights(true)
                lightColor = light
                if (vibration != null) {
                    enableVibration(true)
                    vibrationPattern = vibration
                } else {
                    enableVibration(false)
                }
                setSound(sound, audio)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setShowBadge(true)
            }
        manager.createNotificationChannels(listOf(
            channel(CRITICAL, "Urgent plant alerts",
                "Your plant needs action now — strong sound and vibration.",
                NotificationManager.IMPORTANCE_HIGH, criticalPattern, Color.rgb(214, 84, 56)),
            channel(ATTENTION, "Plant needs attention",
                "Something is drifting out of range — check when you can.",
                NotificationManager.IMPORTANCE_HIGH, attentionPattern, Color.rgb(226, 160, 52)),
            channel(ADVICE, "Care tips & updates",
                "Gentle advice and status updates from VayPulse.",
                NotificationManager.IMPORTANCE_DEFAULT, null, Color.rgb(40, 150, 100)),
        ))
        manager.deleteNotificationChannel(LEGACY_CHANNEL)
    }

    fun show(context: Context, alert: PlantAlert) {
        ensureChannels(context)
        val manager = context.getSystemService(NotificationManager::class.java)
        val level = alert.severity.lowercase()
        val critical = level == "critical"
        val accent = when (level) {
            "critical" -> Color.rgb(196, 82, 56)
            "warning" -> Color.rgb(190, 124, 36)
            else -> Color.rgb(29, 120, 84)
        }
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?.setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val open = launch?.let {
            PendingIntent.getActivity(context, 0, it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }

        val builder = if (Build.VERSION.SDK_INT >= 26) {
            Notification.Builder(context, when (level) {
                "critical" -> CRITICAL
                "warning" -> ATTENTION
                else -> ADVICE
            })
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context).setPriority(
                if (critical) Notification.PRIORITY_HIGH else Notification.PRIORITY_DEFAULT)
        }

        val health = alert.healthScore?.let {
            (if (alert.tamil) "ஆரோக்கியம் " else "Health ") + it + "/100"
        }
        val reminder = if (alert.snoozed) (if (alert.tamil) "நினைவூட்டல்" else "Reminder") else null
        val subText = listOfNotNull(alert.sourceLabel.ifBlank { null }, health, reminder)
            .joinToString(" • ")

        builder.setSmallIcon(R.drawable.ic_stat_phytosense)
            .setColor(accent)
            .setLargeIcon(badge(context, accent, alert.healthScore))
            .setContentTitle(alert.title)
            .setContentText(alert.body)
            .setStyle(Notification.BigTextStyle()
                .setBigContentTitle(alert.title)
                .bigText(alert.body)
                .setSummaryText(alert.summary.ifBlank { null }))
            .setShowWhen(true)
            .setAutoCancel(true)
            .setOnlyAlertOnce(!critical)
            .setCategory(when {
                alert.snoozed -> Notification.CATEGORY_REMINDER
                critical -> Notification.CATEGORY_ALARM
                else -> Notification.CATEGORY_STATUS
            })
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setGroup(GROUP)
        if (subText.isNotBlank()) builder.setSubText(subText)
        if (Build.VERSION.SDK_INT >= 26) {
            builder.setColorized(false)
            builder.setBadgeIconType(Notification.BADGE_ICON_SMALL)
        }
        if (open != null) {
            builder.setContentIntent(open)
            builder.addAction(Notification.Action.Builder(null as Icon?, alert.actionLabel, open).build())
        }
        builder.addAction(Notification.Action.Builder(null as Icon?,
            if (alert.tamil) "சரி" else "Got it",
            actionIntent(context, ACTION_DISMISS, alert, 1)).build())
        builder.addAction(Notification.Action.Builder(null as Icon?,
            if (alert.tamil) "1 மணி நேரத்தில் நினைவூட்டு" else "Remind in 1 h",
            actionIntent(context, ACTION_SNOOZE, alert, 2)).build())
        manager.notify(alert.tag, NOTIFICATION_ID, builder.build())
    }

    fun cancel(context: Context, tag: String) =
        context.getSystemService(NotificationManager::class.java).cancel(tag, NOTIFICATION_ID)

    /** Re-posts the alert in one hour, marked as a reminder. */
    fun snooze(context: Context, alert: PlantAlert) {
        cancel(context, alert.tag)
        val tag = if (alert.tag.endsWith(":reminder")) alert.tag else "${alert.tag}:reminder"
        val intent = Intent(context, PhytoNotificationActionReceiver::class.java)
            .setAction(ACTION_REPOST)
            .putExtras(alert.toBundle(tagOverride = tag, snoozedOverride = true))
        val pending = PendingIntent.getBroadcast(context, alert.tag.hashCode() * 3, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        context.getSystemService(AlarmManager::class.java)
            .setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, System.currentTimeMillis() + SNOOZE_MS, pending)
    }

    private fun actionIntent(context: Context, action: String, alert: PlantAlert, slot: Int): PendingIntent {
        val intent = Intent(context, PhytoNotificationActionReceiver::class.java)
            .setAction(action)
            .putExtras(alert.toBundle())
        return PendingIntent.getBroadcast(context, alert.tag.hashCode() * 3 + slot, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    /** Coloured circle with the app mark and, when known, a health ring. */
    private fun badge(context: Context, accent: Int, health: Int?): Bitmap {
        val bitmap = Bitmap.createBitmap(128, 128, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawCircle(64f, 64f, 62f, Paint(Paint.ANTI_ALIAS_FLAG).apply { color = accent })
        if (health != null) {
            val ring = RectF(12f, 12f, 116f, 116f)
            val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                style = Paint.Style.STROKE
                strokeWidth = 9f
                strokeCap = Paint.Cap.ROUND
                color = Color.argb(70, 255, 255, 255)
            }
            canvas.drawArc(ring, 0f, 360f, false, stroke)
            stroke.color = Color.WHITE
            canvas.drawArc(ring, -90f, health.coerceIn(0, 100) * 360f / 100f, false, stroke)
        }
        context.getDrawable(R.drawable.ic_stat_phytosense)?.mutate()?.let { mark ->
            mark.setTint(Color.WHITE)
            val inset = if (health != null) 34 else 26
            mark.setBounds(inset, inset - 2, 128 - inset, 126 - inset)
            mark.draw(canvas)
        }
        return bitmap
    }
}

class PhytoNotificationActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val alert = PlantAlert.fromBundle(intent.extras ?: return)
        when (intent.action) {
            PhytoNotifications.ACTION_DISMISS -> PhytoNotifications.cancel(context, alert.tag)
            PhytoNotifications.ACTION_SNOOZE -> PhytoNotifications.snooze(context, alert)
            PhytoNotifications.ACTION_REPOST -> PhytoNotifications.show(context, alert)
        }
    }
}
