package com.harjeet.phytosense

import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.media.MediaPlayer
import android.os.Build
import io.flutter.plugin.common.MethodChannel
import java.io.File

class CarePlatform(private val activity: Activity, private val channel: MethodChannel) {
    private var pending: MethodChannel.Result? = null
    private var saveText: String? = null
    private var player: MediaPlayer? = null
    private var audioResult: MethodChannel.Result? = null
    private var audioFile: File? = null
    init {
        channel.setMethodCallHandler { call, result ->
            try {
                when(call.method) {
                    "openVoiceSettings" -> {
                        val settings = Intent("com.android.settings.TTS_SETTINGS")
                        try { activity.startActivity(settings) }
                        catch (_: ActivityNotFoundException) {
                            activity.startActivity(Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS))
                        }
                        result.success(null)
                    }
                    "share" -> {
                        activity.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).apply {
                            type="text/plain"; putExtra(Intent.EXTRA_TEXT,call.argument<String>("text"))
                        },"Share PhytoSense report")); result.success(null)
                    }
                    "saveFile", "openFile" -> {
                        if(pending!=null) {result.error("busy","A file picker is already open",null)} else {
                            val saving=call.method=="saveFile"
                            val intent=Intent(if(saving) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE); type="application/json"
                                if(saving)putExtra(Intent.EXTRA_TITLE,call.argument<String>("name"))
                            }
                            saveText=if(saving)call.argument<String>("text") else null
                            pending=result
                            activity.startActivityForResult(intent,if(saving) 8301 else 8302)
                        }
                    }
                    "playAudio" -> {
                        stopAudio()
                        val bytes=call.argument<ByteArray>("bytes") ?: throw IllegalArgumentException("No audio")
                        if(bytes.size>8000000)throw IllegalArgumentException("Audio too large")
                        val file=File.createTempFile("phyto-voice-",".mp3",activity.cacheDir)
                        file.writeBytes(bytes); audioFile=file; audioResult=result
                        val mp=MediaPlayer(); player=mp
                        mp.setDataSource(file.absolutePath)
                        mp.setOnPreparedListener { it.start() }
                        mp.setOnCompletionListener { finishAudio(true) }
                        mp.setOnErrorListener { _,_,_ -> finishAudio(false); true }
                        mp.prepareAsync()
                    }
                    "stopAudio" -> {stopAudio();result.success(null)}
                    "remind" -> {
                        val allowed=Build.VERSION.SDK_INT<33 || activity.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)==PackageManager.PERMISSION_GRANTED
                        if(!allowed)result.success(false) else {
                            val time=call.argument<Number>("time")!!.toLong()
                            val id=call.argument<Number>("id")!!.toInt()
                            val body=call.argument<String>("body")!!.take(1000)
                            val p=activity.getSharedPreferences("care-reminders",Context.MODE_PRIVATE)
                            p.edit().putLong("time-$id",time).putString("body-$id",body).apply()
                            CareReminderReceiver.schedule(activity,id,time,body)
                            result.success(true)
                        }
                    }
                    "cancelReminder" -> {
                        val id=call.argument<Number>("id")!!.toInt()
                        val intent=Intent(activity,CareReminderReceiver::class.java).putExtra("id",id)
                        val pi=PendingIntent.getBroadcast(activity,id,intent,PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                        (activity.getSystemService(Context.ALARM_SERVICE) as AlarmManager).cancel(pi)
                        activity.getSharedPreferences("care-reminders",Context.MODE_PRIVATE).edit().remove("time-$id").remove("body-$id").apply()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }catch(e:Exception){pending=null;saveText=null;result.error("care_error",e.message,null)}
        }
    }
    private fun finishAudio(success:Boolean) {
        val r=audioResult;audioResult=null
        player?.release();player=null;audioFile?.delete();audioFile=null
        r?.success(success)
    }
    fun stopAudio(){finishAudio(false)}
    fun onResult(request:Int,resultCode:Int,data:Intent?):Boolean {
        if(request!=8301 && request!=8302)return false
        val result=pending ?: return true
        pending=null
        try {
            val uri=data?.data
            if(resultCode!=Activity.RESULT_OK || uri==null){result.success(if(request==8301) false else null);saveText=null;return true}
            if(request==8301){
                val stream=activity.contentResolver.openOutputStream(uri) ?: throw IllegalStateException("Cannot save")
                stream.bufferedWriter().use {it.write(saveText ?: "")}; result.success(true)
            }else{
                val stream=activity.contentResolver.openInputStream(uri) ?: throw IllegalStateException("Cannot open")
                val bytes=stream.use { input ->
                    val buffer=ByteArray(8192)
                    val output=java.io.ByteArrayOutputStream()
                    while(true){val count=input.read(buffer);if(count<0)break;output.write(buffer,0,count);if(output.size()>30000000)throw IllegalArgumentException("Backup too large")}
                    output.toByteArray()
                }
                if(bytes.size>30000000)throw IllegalArgumentException("Backup too large")
                result.success(bytes.toString(Charsets.UTF_8))
            }
        }catch(e:Exception){result.error("file_error",e.message,null)}
        saveText=null;return true
    }
}

class CareReminderReceiver:BroadcastReceiver() {
    companion object {
        fun schedule(context:Context,id:Int,time:Long,body:String){
            val intent=Intent(context,CareReminderReceiver::class.java).putExtra("id",id).putExtra("body",body)
            val pi=PendingIntent.getBroadcast(context,id,intent,PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            (context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP,time,pi)
        }
    }
    override fun onReceive(context:Context,intent:Intent){
        val prefs=context.getSharedPreferences("care-reminders",Context.MODE_PRIVATE)
        if(intent.action==Intent.ACTION_BOOT_COMPLETED){
            prefs.all.keys.filter {it.startsWith("time-")}.forEach {key ->
                val id=key.removePrefix("time-").toIntOrNull() ?: return@forEach
                schedule(context,id,maxOf(System.currentTimeMillis()+60000,prefs.getLong(key,0)),prefs.getString("body-$id","") ?: "")
            };return
        }
        val id=intent.getIntExtra("id",0)
        val body=intent.getStringExtra("body") ?: return
        if(Build.VERSION.SDK_INT>=33 && context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS)!=PackageManager.PERMISSION_GRANTED)return
        val manager=context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel="phytosense_care_reminders"
        if(Build.VERSION.SDK_INT>=26)manager.createNotificationChannel(NotificationChannel(channel,"PhytoSense care reminders",NotificationManager.IMPORTANCE_DEFAULT))
        val tap=PendingIntent.getActivity(context,id,Intent(context,MainActivity::class.java).apply {flags=Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP},PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val builder=if(Build.VERSION.SDK_INT>=26)Notification.Builder(context,channel) else Notification.Builder(context)
        manager.notify("care",id,builder.setSmallIcon(R.drawable.ic_stat_phytosense).setContentTitle("PhytoSense AI").setContentText(body).setStyle(Notification.BigTextStyle().bigText(body)).setContentIntent(tap).setAutoCancel(true).setOnlyAlertOnce(true).build())
        prefs.edit().remove("time-$id").remove("body-$id").apply()
    }
}
