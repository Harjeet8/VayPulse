package com.harjeet.phytosense

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

/**
 * Checks that this copy of VayPulse is signed with Harjeet's release key.
 *
 * A repackaged or modified copy must be re-signed with a different key, so
 * its certificate fingerprint will not match. Dart uses the answer to label
 * such copies "unofficial" and to keep them away from the cloud controls.
 */
object AppIntegrity {
    /** SHA-256 of the official release certificate (CN=PhytoSense AI Release). */
    private const val OFFICIAL_SHA256 =
        "112EA495C55E6925EEFE62D7C250AD340B4741DB50FD2CE207C40B6FE7C98970"

    fun signingSha256(context: Context): List<String> {
        val pm = context.packageManager
        val certs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val info = pm.getPackageInfo(context.packageName, PackageManager.GET_SIGNING_CERTIFICATES)
            val signing = info.signingInfo ?: return emptyList()
            if (signing.hasMultipleSigners()) signing.apkContentsSigners else signing.signingCertificateHistory
        } else {
            @Suppress("DEPRECATION")
            pm.getPackageInfo(context.packageName, PackageManager.GET_SIGNATURES).signatures
        } ?: return emptyList()
        val digest = MessageDigest.getInstance("SHA-256")
        return certs.map { cert ->
            digest.digest(cert.toByteArray()).joinToString("") { "%02X".format(it) }
        }
    }

    fun isOfficial(context: Context): Boolean = try {
        signingSha256(context).any { it == OFFICIAL_SHA256 }
    } catch (_: Exception) {
        false
    }

    fun register(context: Context, channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "check" -> result.success(mapOf(
                    "official" to isOfficial(context),
                    "debuggable" to ((context.applicationInfo.flags and
                        android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0),
                ))
                else -> result.notImplemented()
            }
        }
    }
}
