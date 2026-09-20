# Check-in Feature Domain

## 1. Domain Concept
The Check-in (每日打卡) module is a calendar-centric habit-tracking feature where users define events (e.g. morning run, reading) and register daily completions.

---

## 2. Core Constraints & Design Decisions

1. At Most 1 Record Per Event Per Day:
   - Marking completion creates a record; undoing deletes that record.
   - Enforced by `localDayKey` (`yyyy-MM-dd` in device local timezone at creation).
   - `createdAtUtc` stores the UTC timestamp for cross-device sync consistency.
2. Date Boundaries:
   - Past dates are allowed (backfilling / 补打卡).
   - Future dates are strictly forbidden (no pre-check-in).
3. Event Color:
   - Each event stores an ARGB integer `colorValue`. Rendered on calendar day marker dots and event chips.
4. Cascading Deletion:
   - Deleting a `CheckinEvent` triggers cascading deletion of all associated `CheckinRecord` entries.

---

## 3. Data Models

### 3.1 CheckinEvent
- Model: `CheckinEvent { String name, String description, int colorValue }`
- Annotation: `@Repository(collectionName: 'checkin', tableName: 'event', db: CheckinDB)`

### 3.2 CheckinRecord
- Model: `CheckinRecord { String eventId, DateTime createdAtUtc, String localDayKey, int timezoneOffsetMinutes, String? note }`
- Annotation: `@Repository(collectionName: 'checkin', tableName: 'record', db: CheckinDB)`

---

## 4. UI Layout & Widgets

- Calendar Grid: Built with `table_calendar`, showing color-coded completion dots for each checked-in event on that date.
- Event Bar (`EventListBar`): Horizontal chip list displaying event colors, names, and monthly count stats. Tapping filters the calendar grid; long-pressing opens the event editor.
- Day Event List (`DayEventList`): Bottom sheet / day list detailing status for the selected calendar date with direct "Check in" or "Undo" actions.
- Android Home Screen Widget:
  - Pushed via `CheckinWidgetBridge` (`MethodChannel('com.eluvk.xbb/checkin_widget')`).
  - Supports three responsive layout sizes (xsmall, small, medium).
  - Automatically resets stale checkmarks on midnight date transition.
  - Deep links to the Check-in tab via `app_launch.dart`.

---

## 5. Key Source Paths

- Models & Codegen: `lib/models/checkin/model.dart`
- Database Provider: `lib/models/checkin/db.dart`
- Widget Bridge: `lib/controller/checkin_widget.dart`
- Pages & Components: `lib/pages/checkin/checkin_calendar_page.dart`, `lib/components/checkin/checkin_calendar.dart`, `lib/components/checkin/day_event_list.dart`
