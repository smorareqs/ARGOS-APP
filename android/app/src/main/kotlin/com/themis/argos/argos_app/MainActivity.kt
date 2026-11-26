package com.themis.argos.argos_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Canal de los push de ARGOS (el backend manda channel_id "argos_default").
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            if (manager?.getNotificationChannel("argos_default") == null) {
                manager?.createNotificationChannel(
                    NotificationChannel(
                        "argos_default",
                        "Avisos de ARGOS",
                        NotificationManager.IMPORTANCE_HIGH,
                    ).apply { description = "Tareas, incidencias y alertas" },
                )
            }
        }
    }
}
