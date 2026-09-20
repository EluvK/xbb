# Tracker Feature Domain

## 1. Domain Concept
The Tracker module provides flexible time-series and habit tracking across three distinct configurations: periodic habits, measurable milestones, and anniversary reflections.

---

## 2. Core Entities

### 2.1 Tracker
- Definition: The parent configuration entity defining what is being tracked.
- Model: `Tracker { String name, String description, String category, String type, TrackerConfig config }`
- ACL Enabled: Yes (`withAcls: true`). Supports sharing trackers with collaborators.
- Config Polymorphism (`TrackerConfig`):
  - `event`: Periodic habit tracking.
    - Fields: `int periodDays` (interval in days; `0` indicates no fixed cycle).
  - `milestone`: Target progress tracking toward a goal.
    - Fields: `String goalType` (`time` in minutes, `number`, `boolean`), `String targetValue`, `String progressMode` (`accumulate` vs `latest`).
  - `anniversary`: Significant date reflections.
    - Fields: `DateTime baseDate`, `bool isLunar` (supports traditional lunar calendar), `String remindType` (`per_year`, `per_100_days`, `t_minus`).

### 2.2 TrackerRecord
- Definition: A concrete log entry recorded against a specific tracker.
- Model: `TrackerRecord { String trackerId, DateTime timestamp, String? value, String? content }`

---

## 3. Record Expression Rules

| Tracker Type | `value` Format | `timestamp` Role | `content` Role |
|---|---|---|---|
| Event | `null` | Primary field (when the habit occurred). | Optional memo. |
| Milestone (number) | Numeric string (e.g. `"18"`, `"3.5"`) | When progress was made. | Optional memo. |
| Milestone (time) | Minutes as integer string (e.g. `"45"`) | When activity occurred. | Optional memo. |
| Milestone (boolean) | `"true"` / `"false"` | Completion date. | Optional memo. |
| Anniversary | `null` | Record timestamp. | Reflection or milestone note. |

Convenience constructors are provided in `TrackerRecord`:
- `TrackerRecord.forEvent(...)`
- `TrackerRecord.forMilestoneNumber(...)`
- `TrackerRecord.forMilestoneTime(...)`
- `TrackerRecord.forMilestoneBoolean(...)`
- `TrackerRecord.forAnniversary(...)`

---

## 4. Key Source Paths

- Models & Codegen: `lib/models/tracker/model.dart`
- Database Provider: `lib/models/tracker/db.dart`
- Expression Spec: `lib/models/tracker/record_expression_guide.md`
- Pages & Components: `lib/pages/trackers/view_tracker.dart`, `lib/pages/trackers/edit_tracker.dart`, `lib/components/trackers/tracker_card.dart`
