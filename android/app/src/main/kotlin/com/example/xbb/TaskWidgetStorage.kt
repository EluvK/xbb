package com.eluvk.xbb

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

const val TASK_WIDGET_CHANNEL = "com.eluvk.xbb/task_widget"
const val TASK_WIDGET_LAUNCH_CHANNEL = "com.eluvk.xbb/launch"
const val TASK_WIDGET_PREFS = "task_widget_prefs"
const val TASK_WIDGET_SNAPSHOT_KEY = "task_widget_snapshot"
const val TASK_WIDGET_OPEN_TAB_EXTRA = "open_tab"
const val TASK_WIDGET_HOME_TAB_TASK = "task"

data class TaskWidgetItem(
    val id: String,
    val content: String,
)

data class TaskWidgetSnapshot(
    val state: String,
    val totalCount: Int,
    val unfinishedCount: Int,
    val items: List<TaskWidgetItem>,
)

object TaskWidgetStorage {
    fun saveSnapshot(context: Context, snapshotJson: String?) {
        context.getSharedPreferences(TASK_WIDGET_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(TASK_WIDGET_SNAPSHOT_KEY, snapshotJson)
            .apply()
    }

    fun loadSnapshot(context: Context): TaskWidgetSnapshot {
        val raw = context.getSharedPreferences(TASK_WIDGET_PREFS, Context.MODE_PRIVATE)
            .getString(TASK_WIDGET_SNAPSHOT_KEY, null)

        return raw?.let(::parseSnapshot) ?: TaskWidgetSnapshot(
            state = "requires_login",
            totalCount = 0,
            unfinishedCount = 0,
            items = emptyList(),
        )
    }

    private fun parseSnapshot(raw: String): TaskWidgetSnapshot {
        return runCatching {
            val json = JSONObject(raw)
            val itemsJson = json.optJSONArray("items") ?: JSONArray()
            val items = buildList {
                for (index in 0 until itemsJson.length()) {
                    val itemJson = itemsJson.optJSONObject(index) ?: continue
                    add(
                        TaskWidgetItem(
                            id = itemJson.optString("id"),
                            content = itemJson.optString("content"),
                        ),
                    )
                }
            }

            TaskWidgetSnapshot(
                state = json.optString("state", "requires_login"),
                totalCount = json.optInt("total_count", 0),
                unfinishedCount = json.optInt("unfinished_count", items.size),
                items = items,
            )
        }.getOrElse {
            TaskWidgetSnapshot(
                state = "requires_login",
                totalCount = 0,
                unfinishedCount = 0,
                items = emptyList(),
            )
        }
    }
}
