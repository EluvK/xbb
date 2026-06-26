package com.eluvk.xbb

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity : FlutterActivity() {
    private var pendingLaunchTab: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingLaunchTab = intent?.getStringExtra(TASK_WIDGET_OPEN_TAB_EXTRA)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingLaunchTab = intent.getStringExtra(TASK_WIDGET_OPEN_TAB_EXTRA)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TASK_WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateSnapshot" -> {
                    val snapshot = call.argument<String>("snapshot")
                    TaskWidgetStorage.saveSnapshot(this, snapshot)
                    TaskWidgetProvider.refreshAllWidgets(this)
                    result.success(null)
                }

                "requestPinWidget" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val appWidgetManager = AppWidgetManager.getInstance(this)
                        if (appWidgetManager.isRequestPinAppWidgetSupported) {
                            val provider = ComponentName(this, TaskWidgetProvider::class.java)
                            appWidgetManager.requestPinAppWidget(provider, null, null)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TASK_WIDGET_LAUNCH_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeLaunchTab" -> {
                    result.success(pendingLaunchTab)
                    pendingLaunchTab = null
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHECKIN_WIDGET_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateSnapshot" -> {
                    val snapshot = call.argument<String>("snapshot")
                    CheckinWidgetStorage.saveSnapshot(this, snapshot)
                    CheckinWidgetProvider.refreshAllWidgets(this)
                    scheduleMidnightRefresh()
                    result.success(null)
                }

                "requestPinWidget" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val appWidgetManager = AppWidgetManager.getInstance(this)
                        if (appWidgetManager.isRequestPinAppWidgetSupported) {
                            val provider = ComponentName(this, CheckinWidgetProvider::class.java)
                            appWidgetManager.requestPinAppWidget(provider, null, null)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleMidnightRefresh() {
        val calendar = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_MONTH, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 1)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, MidnightRefreshReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        alarmManager.set(AlarmManager.RTC_WAKEUP, calendar.timeInMillis, pendingIntent)
    }
}
