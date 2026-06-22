# Checkin - 每日打卡 / Daily Check-in

## Feature Overview

- **Code name**: `checkin`
- **User-facing name**: 打卡 / Check-in
- **Description**: A habit-tracking feature where users define **events** (e.g., "晨跑", "早睡", "阅读") and do a daily **check-in** for each event — at most **once per event per day**. The main page shows a **monthly calendar** with color-coded completion dots per event, plus an event list with per-month completion counts.

---

## Design Decisions

### 1. Independent Feature (not a Tracker sub-type)
- Data model, DB, sync, controller, and UI are all self-contained.
- Rationale: The calendar-centric UX (do/undo, per-event color dots, monthly stats per event) does not align with the existing `tracker`'s timeline + progress semantic.

### 2. Data Sync
- **Synced to server** via SyncStore protocol (same as notes/tracker/task/clipboard).
- All-platform: phone + desktop, data shared across devices.
- Mobile widget / shortcut for quick check-in deferred to v2.

### 3. Core Constraint: At Most 1 Record Per Event Per Day
- "Do" = create a record; "Undo" = delete that record.
- **Editing** existing records (timestamp + note) is supported.
- Same-day uniqueness enforced by `localDayKey` (ISO date string `yyyy-MM-dd` in the local timezone at creation time).
- `timestamp` stored in UTC for cross-timezone integrity; `localDayKey` stored alongside to prevent timezone-caused date drift.

### 4. Time Zone Strategy
- `createdAtUtc`: UTC timestamp (for sync & ordering)
- `localDayKey`: `yyyy-MM-dd` string computed in device local timezone **at record creation time**
- Monthly stats and same-day uniqueness use `localDayKey`
- Optional: `timezoneOffsetMinutes` stored for forensic debugging

### 5. Date Constraints
- **Past dates allowed** (backfill/补打卡)
- **Future dates forbidden** (no pre-check-in)
- Date picker restricted to `DateTime.now().toLocal()` as max

### 6. ACL / Sharing
- **Not in v1**. All data is personal (owned by the current user).
- Sharing infrastructure (ACL, read-only shared events) deferred to v2.

### 7. Event Color
- Each event stores a custom `colorValue` (`int` for `Color.value`).
- Calendar dots and event chips use this color.
- No predetermined palette; user picks from a color picker.

### 8. Delete Event
- Hard delete with **confirmation dialog**.
- **Cascading delete** of all records under that event.
- Rationale: Long-horizon habits; accidental delete is mitigated by confirmation.

### 9. No Goal Frequency
- v1 shows only raw stats: **monthly completion count** per event, **current streak** computed server-side (v2).
- No weekly/monthly target, no "achieved X%".

---

## Data Models

### CheckinEvent

```dart
@Repository(collectionName: 'checkin', tableName: 'event', db: CheckinDB)
@freezed
abstract class CheckinEvent with _$CheckinEvent {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CheckinEvent({
    required String name,
    required String description,
    required int colorValue,   // Color.value — custom per event
  }) = _CheckinEvent;

  factory CheckinEvent.fromJson(Map<String, dynamic> json) => _$CheckinEventFromJson(json);
}
```

### CheckinRecord

```dart
@Repository(collectionName: 'checkin', tableName: 'record', db: CheckinDB)
@freezed
abstract class CheckinRecord with _$CheckinRecord {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory CheckinRecord({
    required String eventId,
    required DateTime createdAtUtc,
    required String localDayKey,         // "yyyy-MM-dd" in local tz at creation
    @Default(0) int timezoneOffsetMinutes, // local offset at creation (for debugging)
    String? note,                         // optional description
  }) = _CheckinRecord;

  factory CheckinRecord.fromJson(Map<String, dynamic> json) => _$CheckinRecordFromJson(json);
}
```

### Database

- `CheckinDB` follows the same pattern as `TrackerDB` / `ClipboardDB`.
- Two tables: `checkin_event` and `checkin_record`.
- Unique constraint on `(eventId, localDayKey)` enforced at application level (since SyncStore uses string IDs, the generated controller handles it).

---

## UI Components

### 1. Main Calendar Page (`CheckinCalendarPage`)
```
┌─────────────────────────────────────────┐
│  ◁ January 2026 ▷                       │
│  ┌────────────────────────────────────┐  │
│  │  M   T   W   T   F   S   S        │  │
│  │       1   2   3   4   5   6        │  │
│  │  7 ● 8 ○ 9 ●10 11 12 13           │  │
│  │ 14 15 16 17 18 19 20              │  │
│  │ 21 22 23 24 25 26 27              │  │
│  │ 28 29 30 31                       │  │
│  └────────────────────────────────────┘  │
│  ┌────────────────────────────────────┐  │
│  │ ● running (12)  ▲ daily-read (8)  │  │
│  │ ■ sleep-early (3)                  │  │
│  └────────────────────────────────────┘  │
│  ┌─ 2026-01-15 ───────────────────────┐  │
│  │ ● running    08:32 · felt great   [✎│  │
│  │ ▲ daily-read           [Check in]  │  │
│  │ ■ sleep-early 22:15                │  │
│  └───────────────────────────────────┘   │
│                    [+ add event]  FAB    │
└─────────────────────────────────────────┘
```

- **Calendar**: `table_calendar` library, month view (day), weekday labels in local.
- **Date dots**: Multiple small colored circles per date; one color per event that was checked in that day.
- **Event row** (`EventListBar`): Below the calendar, a horizontal scrollable chip/row area.
  - Each chip shows: color dot + event name + **monthly count** (auto-updates as month swipes).
  - Tapping a chip **filters** the calendar to show only that event's dots.
  - A "Show All" chip resets the filter.
  - Long-press a chip → edit event.
- **Day event list** (`DayEventList`): Below the event bar, an inline list showing check-in status for the selected date. Updates when tapping a calendar day.
  - If already checked in: show time + note (if any), with edit and undo buttons.
  - If not checked in: "Check in" button (disabled for future dates).
  - Editing opens a modal bottom sheet with `TimePickerWidget` (from `lib/utils/time_picker.dart`) and optional note field.
  - Undo shows confirmation dialog.
- **FAB**: Create new event.

### 2. Event Editor (`CheckinEventEditPage`)

```
┌─────────────────────────────────────────┐
│  [Create Event] / [Edit Event]          │
│                                         │
│  Name: [________________]               │
│  Description: [________________]        │
│  Color: [🧴 Color Picker]              │
│                                         │
│  [Save]                                 │
│                                         │
│  (If editing) [Delete Event] (red btn)   │
│       → Confirmation: "Delete event and │
│          all its records?"              │
└─────────────────────────────────────────┘
```

- Name required, description optional.
- Color picker: a grid of pre-defined swatches + custom color wheel.
- Delete button only visible when editing (not creating).
- Fills edit form from existing `CheckinEvent` on edit.

---

## Integration Points

| Layer | What to add |
|---|---|
| **Nav** | `HomeTabIndex.checkin` enum + tab in `home.dart` |
| **Routes** | `/checkin/edit-event` in `main.dart` |
| **Feature toggle** | `enableCheckin` in `AppFeaturesManagement` + `SettingController` |
| **Settings UI** | Check-in toggle in settings page (`common/settings.dart`) |
| **Sync init** | `reInitCheckinSync` + `onReadySyncCheckin` in model file; wired in `syncstore.dart` |
| **Translation** | New key block in `translation.dart` (prefixed `checkin_*`) |

---

## Implementation Plan

### Task 1: Add Dependencies
- Add `table_calendar: ^3.1.3` to `pubspec.yaml` (check latest version).
- Add `flex_color_picker: ^3.8.0` to `pubspec.yaml`.
- Add `flutter_randomcolor: ^1.0.18` to `pubspec.yaml`.
- Run `flutter pub get`.

**Files**: `pubspec.yaml`

### Task 2: Create Data Models
- Create `lib/models/checkin/` directory.
- Create `lib/models/checkin/model.dart`:
  - `CheckinEvent` with `@Repository` + `@freezed` (lowercase for freezed 3.x)
  - `CheckinRecord` with `@Repository` + `@freezed` (lowercase for freezed 3.x)
  - `reInitCheckinSync()` and `onReadySyncCheckin()` helpers
- Create `lib/models/checkin/db.dart`:
  - `CheckinDB` with SQLite init, cache, table creation SQL
- Run `dart run build_runner build --delete-conflicting-outputs` to generate `model.g.dart` + `model.freezed.dart`, and SyncStore controller files.

**Files**: `lib/models/checkin/model.dart`, `lib/models/checkin/model.g.dart` (generated), `lib/models/checkin/model.freezed.dart` (generated), `lib/models/checkin/db.dart`

### Task 3: Add Sync Initialization
- In `lib/controller/syncstore.dart`:
  - Import checkin model
  - Add `reInitCheckinSync(syncStoreClient)` call in `reInitSyncStoreController()`
  - Add checkin sync in `onReadySyncStartup()` (gated by `settingController.checkinEnabled`)

**Files**: `lib/controller/syncstore.dart`

### Task 4: Feature Toggle & Navigation
- In `lib/constant.dart`: add `STORAGE_CHECKIN_SYNC_META_KEY` if needed.
- In `lib/controller/setting.dart`:
  - Add `enableCheckin` to `AppFeaturesManagement` (default `false`)
  - Add getter `bool get checkinEnabled` to `SettingController`
- In `lib/pages/home.dart`:
  - Add `HomeTabIndex.checkin` to enum
  - Add tab entry with icon/translation key
  - Add `_LeftButton` / `_RightMain` / `_AppBar` case for `checkin`
  - Gate by `settingController.checkinEnabled`

**Files**: `lib/controller/setting.dart`, `lib/pages/home.dart`

### Task 5: Register Routes
- In `lib/main.dart`:
  - Import checkin pages
  - Add `GetPage(name: '/checkin/edit-event', page: () => const EditCheckinEventPage())`

**Files**: `lib/main.dart`

### Task 6: Create Pages
- Create `lib/pages/checkin/checkin_calendar_page.dart`:
  - `CheckinCalendarPage` — main page wrapper (scaffold with FAB)
- Create `lib/pages/checkin/edit_event_page.dart`:
  - `EditCheckinEventPage` — event editor page (create/edit)
  - Uses `ColorPickerWidget` from `lib/utils/color_picker.dart` for color selection
  - Uses `flutter_randomcolor` for default random color on new event creation
- Create `lib/utils/color_picker.dart`:
  - `ColorPickerWidget` — reusable color picker using `flex_color_picker` library
  - Shows primary palette + color wheel picker
  - Initial color can be set; notifies via `onChanged` callback

**Files**: `lib/pages/checkin/checkin_calendar_page.dart`, `lib/pages/checkin/edit_event_page.dart`, `lib/utils/color_picker.dart`

### Task 7: Create UI Components
- Create `lib/components/checkin/checkin_calendar.dart`:
  - `CheckinCalendar` — `table_calendar` integration
  - Month view only
  - Custom dot markers per event using colors
  - Tap date → updates selected day, which triggers `DayEventList` re-render
  - Swipe month → auto-refresh event monthly counts
- Create `lib/components/checkin/event_list_bar.dart`:
  - Horizontal scrollable event chips
  - Each chip: color indicator + name + monthly count
  - Tap to filter; long-press to edit
  - "Show All" chip
- Create `lib/components/checkin/day_event_list.dart`:
  - Inline list showing per-event check-in status for the selected day (rendered below calendar, not a bottom sheet)
  - Check-in / undo / edit actions per event
  - Editing opens a modal bottom sheet with time picker (`TimePickerWidget`) and optional note
  - Undo shows confirmation dialog
  - Check-in button disabled for future dates (`_todayOrPast()` guard)

**Files**: `lib/components/checkin/checkin_calendar.dart`, `lib/components/checkin/event_list_bar.dart`, `lib/components/checkin/day_event_list.dart`

### Task 8: Settings UI
- In `lib/components/common/settings.dart`:
  - Add check-in toggle (similar to tracker/notes toggles) using `AppFeatureMetaEnum` pattern

**Files**: `lib/components/common/settings.dart`

### Task 9: Translations
- In `lib/utils/translation.dart`:
  - Add key block with `checkin_*` keys for en_US + zh_CN
  - Keys implemented: `home_bar_title_checkin`, `app_enable_checkin_feature`, `checkin_create_event`, `checkin_edit_event`, `checkin_delete_event`, `checkin_delete_confirm`, `checkin_event_name`, `checkin_name_required`, `checkin_event_description`, `checkin_event_color`, `checkin_record_time`, `checkin_note`, `checkin_checkin`, `checkin_undo`, `checkin_undo_title`, `checkin_undo_confirm`, `checkin_edit_record`, `checkin_done`, `checkin_not_yet`, `checkin_no_events`, `checkin_filter_all`, `checkin_save`, `checkin_completed_times`, `checkin_past_date_forbidden`, `checkin_future_date_forbidden`
  - Note: `checkin_done`, `checkin_not_yet`, `checkin_completed_times`, `checkin_past_date_forbidden`, `checkin_future_date_forbidden` are defined in translation map but not referenced in UI code.

**Files**: `lib/utils/translation.dart`

### Task 10: Add AppFeatureMetaEnum entry for Check-in
- In `lib/utils/text_input.dart`: add `enableCheckin` to `AppFeatureMetaEnum` with icon/color/title translations

**Files**: `lib/utils/text_input.dart`

### Task 11: Wire Up Sync
- In `lib/controller/syncstore.dart`:
  - Add checkin import and sync init calls
  - Handle feature-gated sync in `onReadySyncStartup()`

**Files**: `lib/controller/syncstore.dart`

### Task 12: Verify and Test
- Run `flutter analyze` to check for lint errors.
- Run `dart run build_runner build --delete-conflicting-outputs` to regenerate codegen.
- Manual testing: create event → check in → edit → undo → delete event → sync.
- Verify calendar dot rendering and monthly count accuracy with multiple events.

---

## Appendix: File Checklist

| File | Action |
|---|---|
| `pubspec.yaml` | Add `table_calendar`, `flex_color_picker`, `flutter_randomcolor` |
| `lib/models/checkin/model.dart` | Create |
| `lib/models/checkin/db.dart` | Create |
| `lib/models/checkin/model.g.dart` | Generated |
| `lib/models/checkin/model.freezed.dart` | Generated |
| `lib/pages/checkin/checkin_calendar_page.dart` | Create |
| `lib/pages/checkin/edit_event_page.dart` | Create |
| `lib/components/checkin/checkin_calendar.dart` | Create |
| `lib/components/checkin/event_list_bar.dart` | Create |
| `lib/components/checkin/day_event_list.dart` | Create |
| `lib/controller/setting.dart` | Edit (add `checkinEnabled`) |
| `lib/controller/syncstore.dart` | Edit (add checkin sync init) |
| `lib/pages/home.dart` | Edit (add tab) |
| `lib/main.dart` | Edit (add route) |
| `lib/components/common/settings.dart` | Edit (add toggle) |
| `lib/utils/color_picker.dart` | Create |
| `lib/utils/text_input.dart` | Edit (add `AppFeatureMetaEnum.enableCheckin`) |
| `lib/utils/translation.dart` | Edit (add `checkin_*` keys) |
