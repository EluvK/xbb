package com.eluvk.xbb

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.RemoteViews

class CheckinWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        updateWidgets(context, appWidgetManager, intArrayOf(appWidgetId))
    }

    companion object {
        fun refreshAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, CheckinWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            if (appWidgetIds.isNotEmpty()) {
                updateWidgets(context, appWidgetManager, appWidgetIds)
            }
        }

        private fun updateWidgets(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
        ) {
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.checkin_widget_list)
            appWidgetIds.forEach { appWidgetId ->
                val snapshot = CheckinWidgetStorage.loadSnapshot(context)
                val views = RemoteViews(context.packageName, layoutFor(appWidgetManager, appWidgetId))

                views.setTextViewText(R.id.checkin_widget_title, context.getString(R.string.checkin_widget_title))
                views.setTextViewText(R.id.checkin_widget_subtitle, subtitleFor(context, snapshot))
                views.setTextViewText(R.id.checkin_widget_empty, emptyMessageFor(context, snapshot))
                views.setEmptyView(R.id.checkin_widget_list, R.id.checkin_widget_empty)

                val serviceIntent = Intent(context, CheckinWidgetRemoteViewsService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                views.setRemoteAdapter(R.id.checkin_widget_list, serviceIntent)

                views.setOnClickPendingIntent(R.id.checkin_widget_header, createLaunchPendingIntent(context, appWidgetId))
                views.setPendingIntentTemplate(R.id.checkin_widget_list, createLaunchPendingIntent(context, appWidgetId))

                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }

        private fun createLaunchPendingIntent(context: Context, appWidgetId: Int): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(CHECKIN_WIDGET_OPEN_TAB_EXTRA, CHECKIN_WIDGET_HOME_TAB_CHECKIN)
            }
            return PendingIntent.getActivity(
                context,
                appWidgetId,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
            )
        }

        private fun layoutFor(appWidgetManager: AppWidgetManager, appWidgetId: Int): Int {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            return if (minWidth < 180) {
                R.layout.checkin_widget_small
            } else {
                R.layout.checkin_widget_medium
            }
        }

        private fun subtitleFor(context: Context, snapshot: CheckinWidgetSnapshot): String {
            return when (snapshot.state) {
                "ready" -> context.getString(
                    R.string.checkin_widget_subtitle_ready,
                    snapshot.checkedCount,
                    snapshot.eventCount,
                )
                "empty" -> context.getString(R.string.checkin_widget_subtitle_empty)
                else -> context.getString(R.string.checkin_widget_subtitle_requires_login)
            }
        }

        private fun emptyMessageFor(context: Context, snapshot: CheckinWidgetSnapshot): String {
            return when (snapshot.state) {
                "ready" -> context.getString(R.string.checkin_widget_empty_loading)
                "empty" -> context.getString(R.string.checkin_widget_state_empty)
                else -> context.getString(R.string.checkin_widget_state_requires_login)
            }
        }
    }
}
