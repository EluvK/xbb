# Clipboard Feature Domain

## 1. Domain Concept
The Clipboard module is a Windows desktop background clipboard manager. It captures copied text locally, provides tray minimization, and enables explicit, selective cloud backup.

---

## 2. Core Decisions & Privacy Rules

1. Local-First & Non-Automatic Double Writing:
   - Background copy events are captured only to local SQLite (`localOnly = true`).
   - Entries are never automatically uploaded to the cloud upon capture.
   - Cloud synchronization requires explicit user selection and manual confirmation ("Confirm Sync").
2. Deduplication Strategy:
   - Consecutive identical clips are ignored.
   - Sliding 30-second deduplication window against recent entries.
3. Consistency & Synchronization Lifecycle:
   - Manual Bulk Sync: Only `localOnly = true` items trigger remote `create`. Upon server success, local records are updated to `localOnly = false`.
   - Editing:
     - `localOnly = true`: Local database update only.
     - `localOnly = false`: Local update followed by immediate remote `update`.
   - Deletion:
     - `localOnly = true`: Local SQLite delete.
     - `localOnly = false`: Remote delete followed by local SQLite delete.

---

## 3. Data Models

### 3.1 ClipboardHistoryEntry
- Model: `ClipboardHistoryEntry { String data, DateTime? capturedAt, bool localOnly }`
- Annotation:
  ```dart
  @Repository(
    collectionName: 'clipboard_history',
    tableName: 'entry',
    db: ClipboardDB,
    toSyncJsonMethod: 'toSyncJson',
    fromRemoteJsonFactory: 'fromRemoteJson',
  )
  ```
- Sync Serialization: Maps `data` and `captured_at` (omits `localOnly` from remote payload).

---

## 4. Windows Native Integration

- Runner: Uses Win32 `AddClipboardFormatListener` to capture `WM_CLIPBOARDUPDATE`.
- Channel: `MethodChannel('com.eluvk.xbb/clipboard_tray')`.
- Tray Capabilities:
  - Minimize to tray on main window close.
  - Double-click to restore.
  - Tray context menu: Show Window, Pause/Resume Listening, Exit.

---

## 5. Key Source Paths

- Models & Sync: `lib/models/clipboard/model.dart`, `lib/models/clipboard/db.dart`
- Tray Controller: `lib/controller/clipboard_tray.dart`
- Native Implementation: `windows/runner/flutter_window.cpp` (and clipboard integration files)
- UI Components: `lib/components/clipboard/view_clipboard_history.dart`, `lib/components/clipboard/view_clipboard_overview.dart`
