# Tracker Record Expression Guide

This document defines how to express `TrackerRecord` for each tracker scenario.

## Shared Model

`TrackerRecord` fields:

- `trackerId`: required
- `timestamp`: required
- `value`: optional string, semantic varies by tracker type
- `content`: optional note text

Core rule: keep model generic, but make input and interpretation type-specific.

## 1) Event Tracker

Use case: periodic habit or repeatable action.

Expression:

- `value`: always `null` (not used)
- `timestamp`: main field, can be set to past time when backfilling records
- `content`: optional note

Example:

- Tracker: "Workout"
- Record: `timestamp=2026-03-16 21:30`, `value=null`, `content="Leg day"`
- Meaning: one event happened at that specific time.

## 2) Milestone Tracker

Use case: progress toward a target.

### 2.1 `goalType = boolean`

Status: temporarily hidden in current UI (no new input entry).

Expression:

- `value`: `"true"` or `"false"`
- `content`: optional note

Example:

- Tracker: "No sugar today"
- Record: `value="true"`, `content="Skipped dessert"`

Notes:

- Existing data can still be read and displayed.
- New creation/input for this type is temporarily disabled until the product semantics are finalized.

### 2.2 `goalType = number`

Expression:

- `value`: numeric contribution string, like `"12"` or `"3.5"`
- `content`: optional note

Example:

- Tracker: "Read 200 pages"
- Record: `value="18"`, `content="Chapter 3 and 4"`

### 2.3 `goalType = time`

Expression:

- `value`: minutes as integer string, like `"30"`, `"90"`
- `content`: optional note

Example:

- Tracker: "Study 600 minutes"
- Record: `value="45"`, `content="Vocabulary practice"`

## 3) Anniversary Tracker

Use case: milestone date reflection (yearly, 100-day, T-minus style).

Expression:

- `value`: always `null`
- `content`: main content, should not be empty

Example:

- Tracker: "Together Anniversary"
- Record: `value=null`, `content="Had dinner at the first restaurant"`

## Input Recommendations

- Event: use a datetime picker to record when it happened, with optional note.
- Milestone boolean: use explicit selection (done / not done), no free text.
- Milestone time: use minute-based input with quick presets.
- Anniversary: note-first input, do not ask for numeric value.

## Convenience Constructors

Use these constructors on `TrackerRecord` to avoid repetitive mapping logic:

- `TrackerRecord.forEvent(...)`
- `TrackerRecord.forMilestoneBoolean(...)`
- `TrackerRecord.forMilestoneNumber(...)`
- `TrackerRecord.forMilestoneTime(...)`
- `TrackerRecord.forAnniversary(...)`

## Validation Rules

- Event value is ignored; timestamp can be selected manually.
- Milestone boolean must be selected.
- Milestone time must be positive integer minutes.
- Milestone number must be numeric.
- Anniversary content must be non-empty.
