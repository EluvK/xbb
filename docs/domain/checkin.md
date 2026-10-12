# Check-in Feature Domain

## 1. Domain Concept
The Check-in (每日打卡) module provides a calendar-based habit registration system where users define personal events and log daily completions.

---

## 2. Core Constraints & Invariants (ADR-0003)

1. **Local Day Boundary & Single Completion**:
   - Strictly at most 1 completion per event per local natural day.
   - Enforced by `localDayKey` (`yyyy-MM-dd` in device local timezone).
   - `createdAtUtc` stores the UTC timestamp for cross-device synchronization and monotonic ordering.
2. **Date Boundaries & Anti-Cheat**:
   - Past dates allow backfilling (补打卡).
   - Future dates are strictly prohibited (no pre-check-in / 禁止预打卡).
   - Dates preceding event creation are prohibited from backfilling.
3. **Double-Confirmation for Undo**:
   - Removing an existing check-in requires explicit user confirmation to prevent accidental habit loss.
4. **Cascading Deletion**:
   - Deleting a `CheckinEvent` atomically removes all associated `CheckinRecord` entries in a single database transaction.

---

## 3. Core Entities & Schema

### 3.1 CheckinEvent (打卡事件)
- **Definition**: Habit theme entity with customizable ARGB color and description.
- **Model**: `CheckinEvent { String name, String description, int colorValue }`
- **Drift Table**: `CheckinEventTable` -> table `checkin_event` in `app_v2.db`.

### 3.2 CheckinRecord (打卡记录)
- **Definition**: Concrete proof of completion for a specific event on a calendar day.
- **Model**: `CheckinRecord { String eventId, DateTime createdAtUtc, String localDayKey, int timezoneOffsetMinutes, String? note }`
- **Drift Table**: `CheckinRecordTable` -> table `checkin_record` in `app_v2.db` (`parent_id = eventId`).

---

## 4. UI Layout & Widget Integration

- **Table Calendar Grid**: Rendered via `table_calendar`, showing colored dots matching each checked-in event on that day.
- **Event Filter Bar (`EventListBar`)**: Horizontal chip list displaying event colors, names, and monthly completion counts; supports one-tap filtering and long-press editing.
- **System Home Widget (`CheckinWidgetBridge`)**:
  - Communicates over `MethodChannel('com.eluvk.xbb/checkin_widget')`.
  - Supports 3 widget sizes; resets stale checkmarks on midnight date transition.

---

## 5. Key Source Paths

- **Domain Model**: `app/lib/models/checkin/model.dart`
- **Data Repository**: `app/lib/data/repositories/checkin_repository.dart` (`CheckinRepository`)
- **State Management**: `app/lib/presentation/checkin/checkin_providers.dart` (Riverpod Notifiers & StreamProviders)
- **Presentation Views**:
  - Main Calendar: `app/lib/presentation/checkin/modern_checkin_view.dart` (`ModernCheckinView`)
  - Filter Bar: `app/lib/presentation/checkin/event_filter_bar.dart` (`EventListBar`)
  - Event Dialog: `app/lib/presentation/checkin/edit_checkin_event_dialog.dart` (`EditCheckinEventDialog`)
- **Widget Bridge**: `app/lib/controller/checkin_widget.dart` (`CheckinWidgetBridge`)
- **Route Screen**: `app/lib/pages/checkin/edit_event_page.dart`
