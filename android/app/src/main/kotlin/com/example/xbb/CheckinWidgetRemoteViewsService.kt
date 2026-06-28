package com.eluvk.xbb

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService

class CheckinWidgetRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return CheckinWidgetRemoteViewsFactory(applicationContext, intent)
    }
}

class CheckinWidgetRemoteViewsFactory(
    private val context: android.content.Context,
    intent: Intent,
) : RemoteViewsService.RemoteViewsFactory {
    private val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
    private var items: List<CheckinWidgetItem> = emptyList()

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        val snapshot = CheckinWidgetStorage.loadSnapshot(context)
        items = if (snapshot.state == "ready") snapshot.items else emptyList()
    }

    override fun onDestroy() {
        items = emptyList()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews? {
        if (position < 0 || position >= items.size) return null
        val item = items[position]
        return RemoteViews(context.packageName, R.layout.checkin_widget_list_item).apply {
            setTextViewText(R.id.checkin_widget_item_text, item.eventName)
            setInt(R.id.checkin_widget_item_dot, "setColorFilter", item.eventColor)
            if (item.isChecked) {
                setViewVisibility(R.id.checkin_widget_item_check, android.view.View.VISIBLE)
            } else {
                setViewVisibility(R.id.checkin_widget_item_check, android.view.View.GONE)
            }
            setOnClickFillInIntent(
                R.id.checkin_widget_item_root,
                Intent().apply {
                    putExtra(CHECKIN_WIDGET_OPEN_TAB_EXTRA, CHECKIN_WIDGET_HOME_TAB_CHECKIN)
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                },
            )
        }
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 2

    override fun getItemId(position: Int): Long = items.getOrNull(position)?.id?.hashCode()?.toLong() ?: position.toLong()

    override fun hasStableIds(): Boolean = true
}
