package com.eluvk.xbb

import android.content.Intent
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
