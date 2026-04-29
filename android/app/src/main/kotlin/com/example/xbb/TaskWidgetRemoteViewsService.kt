package com.eluvk.xbb

import android.appwidget.AppWidgetManager
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService

class TaskWidgetRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TaskWidgetRemoteViewsFactory(applicationContext, intent)
    }
}

class TaskWidgetRemoteViewsFactory(
    private val context: android.content.Context,
    intent: Intent,
) : RemoteViewsService.RemoteViewsFactory {
    private val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
    private var items: List<TaskWidgetItem> = emptyList()

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        val snapshot = TaskWidgetStorage.loadSnapshot(context)
        items = if (snapshot.state == "ready") snapshot.items else emptyList()
    }

    override fun onDestroy() {
        items = emptyList()
    }

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews? {
        if (position < 0 || position >= items.size) return null
        val item = items[position]
        return RemoteViews(context.packageName, R.layout.task_widget_list_item).apply {
            setTextViewText(R.id.task_widget_item_text, item.content)
            setOnClickFillInIntent(
                R.id.task_widget_item_root,
                Intent().apply {
                    putExtra(TASK_WIDGET_OPEN_TAB_EXTRA, TASK_WIDGET_HOME_TAB_TASK)
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                },
            )
        }
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = items.getOrNull(position)?.id?.hashCode()?.toLong() ?: position.toLong()

    override fun hasStableIds(): Boolean = true
}
