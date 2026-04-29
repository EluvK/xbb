package com.eluvk.xbb

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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
    }
}
