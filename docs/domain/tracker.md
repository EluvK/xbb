# Tracker Feature Domain

## 1. Domain Concept
The Tracker module supports quantitative goal tracking, recurring habit monitoring, and milestone reflections across three polymorphic configurations: periodic events, measurable milestones, and anniversary monitors.

---

## 2. Core Entities & Polymorphism

### 2.1 Tracker (追踪器)
- **Definition**: Parent configuration entity defining tracking criteria, type, and target boundaries.
- **Model**: `Tracker { String name, String description, String category, String type, TrackerConfig config }`
- **Drift Table**: `TrackerTable` -> table `tracker` in `app_v2.db`.
- **Config Polymorphism (`TrackerConfig`)**:
  - `event`: Recurring habit with cycle interval.
    - Fields: `int periodDays` (`0` means flexible/no fixed interval).
  - `milestone`: Measurable target goal.
    - Fields: `String goalType` (`time` in minutes, `number`, `boolean`), `String targetValue`, `String progressMode` (`accumulate` vs `latest`).
  - `anniversary`: Significant milestone or countdown date.
    - Fields: `DateTime baseDate`, `bool isLunar` (traditional lunar calendar support), `String remindType` (`per_year`, `per_100_days`, `t_minus`).

### 2.2 TrackerRecord (追踪记录)
- **Definition**: Time-series log entry recorded against a Tracker.
- **Model**: `TrackerRecord { String trackerId, DateTime timestamp, String? value, String? content }`
- **Drift Table**: `TrackerRecordTable` -> table `tracker_record` in `app_v2.db` (`parent_id = trackerId`).

---

## 3. Key Capabilities & Analytics

1. **Category Macro Briefing (`ViewTrackerBrief`)**:
   - Aggregates overall health, category completion rates, and deadline alerts across trackers.
2. **Dedicated In-Depth Analytics Page (`ViewTrackerDetailPage`)**:
   - Full-screen time-series visualization showing historical progress charts, milestones, and record logs.
   - Provides backfill and record editing directly from the timeline view.
3. **Calculation & Countdown Engine (`TrackerCalculator`)**:
   - Calculates remaining days, recurrence health, and milestone accumulation.
   - Computes color shifts (e.g. green-to-red deadline warning gradients) for event trackers.
4. **Bento Matrix Layout**:
   - Responsive multi-card grid adapting between desktop widescreen dashboards and mobile column cards.

---

## 4. Key Source Paths

- **Domain Model**: `app/lib/models/tracker/model.dart`
- **Calculation Engine**: `app/lib/models/tracker/tracker_calculator.dart` (`TrackerCalculator`)
- **Data Repository**: `app/lib/data/repositories/tracker_repository.dart` (`TrackerRepository`)
- **State Management**: `app/lib/presentation/tracker/tracker_providers.dart` (Riverpod Notifiers & Providers)
- **Presentation Views**:
  - Main Dashboard: `app/lib/presentation/tracker/modern_tracker_view.dart` (`ModernTrackerView`, `ViewTrackerBrief`)
  - Detail Analysis & Timeline: `app/lib/presentation/tracker/tracker_history_sheet.dart` (`ViewTrackerDetailPage`, `TrackerHistorySheet`)
- **Route Screens**: `app/lib/pages/trackers/view_tracker.dart`, `app/lib/pages/trackers/edit_tracker.dart`
