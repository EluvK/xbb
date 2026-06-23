package com.eluvk.xbb

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

const val CHECKIN_WIDGET_CHANNEL = "com.eluvk.xbb/checkin_widget"
const val CHECKIN_WIDGET_PREFS = "checkin_widget_prefs"
const val CHECKIN_WIDGET_SNAPSHOT_KEY = "checkin_widget_snapshot"
const val CHECKIN_WIDGET_OPEN_TAB_EXTRA = "open_tab"
const val CHECKIN_WIDGET_HOME_TAB_CHECKIN = "checkin"

data class CheckinWidgetItem(
    val id: String,
    val eventName: String,
    val eventColor: Int,
    val isChecked: Boolean,
    val checkinTime: String,
)

data class CheckinWidgetSnapshot(
    val state: String,
    val eventCount: Int,
    val checkedCount: Int,
    val items: List<CheckinWidgetItem>,
)

object CheckinWidgetStorage {
    fun saveSnapshot(context: Context, snapshotJson: String?) {
        context.getSharedPreferences(CHECKIN_WIDGET_PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(CHECKIN_WIDGET_SNAPSHOT_KEY, snapshotJson)
            .apply()
    }

    fun loadSnapshot(context: Context): CheckinWidgetSnapshot {
        val raw = context.getSharedPreferences(CHECKIN_WIDGET_PREFS, Context.MODE_PRIVATE)
            .getString(CHECKIN_WIDGET_SNAPSHOT_KEY, null)

        return raw?.let(::parseSnapshot) ?: CheckinWidgetSnapshot(
            state = "requires_login",
            eventCount = 0,
            checkedCount = 0,
            items = emptyList(),
        )
    }

    private fun parseSnapshot(raw: String): CheckinWidgetSnapshot {
        return runCatching {
            val json = JSONObject(raw)
            val itemsJson = json.optJSONArray("items") ?: JSONArray()
            val items = buildList {
                for (index in 0 until itemsJson.length()) {
                    val itemJson = itemsJson.optJSONObject(index) ?: continue
                    add(
                        CheckinWidgetItem(
                            id = itemJson.optString("id"),
                            eventName = itemJson.optString("event_name"),
                            eventColor = itemJson.optInt("event_color", 0xFF9C27B0.toInt()),
                            isChecked = itemJson.optBoolean("is_checked", false),
                            checkinTime = itemJson.optString("checkin_time", ""),
                        ),
                    )
                }
            }

            CheckinWidgetSnapshot(
                state = json.optString("state", "requires_login"),
                eventCount = json.optInt("event_count", 0),
                checkedCount = json.optInt("checked_count", 0),
                items = items,
            )
        }.getOrElse {
            CheckinWidgetSnapshot(
                state = "requires_login",
                eventCount = 0,
                checkedCount = 0,
                items = emptyList(),
            )
        }
    }
}
