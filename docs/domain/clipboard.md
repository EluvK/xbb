# Clipboard Feature Domain

## 1. Domain Concept
The Clipboard module provides a cross-platform desktop background clipboard manager. It captures copied text locally, respects user privacy boundaries (ADR-0002), and integrates with system tray and window controls.

---

## 2. Core Decisions & Privacy Rules (ADR-0002)

1. **Local-First & Non-Automatic Double Writing**:
   - Background copy events are captured strictly to local storage (`localOnly = true`).
   - Entries are **never** automatically uploaded to the cloud upon capture.
   - Cloud synchronization requires explicit user selection and manual confirmation ("Confirm Sync").
2. **Lifecycle & Mutability**:
   - `localOnly == true`: Mutations (edits and deletes) apply exclusively to local storage.
   - `localOnly == false`: Mutations apply locally and enqueue an Outbox mutation for cloud synchronization.
3. **Deduplication**:
   - Consecutive identical clips within a 30-second window are automatically deduplicated.

---

## 3. Core Entities & Schema

### 3.1 ClipboardHistoryEntry (剪贴板记录)
- **Definition**: Captured clipboard text record with timestamp and cloud state.
- **Model**: `ClipboardHistoryEntry { String data, DateTime? capturedAt, bool localOnly }`
- **Drift Table**: `ClipboardHistoryTable` -> table `clipboard_history_entry` in `app_v2.db`.
- **Sync Payload**: Serializes `data` and `captured_at`; excludes `localOnly` from the remote body.

---

## 4. Desktop Integration & UI Features

1. **Cross-Platform Tray & Windowing (ADR-0006)**:
   - Unified across Windows, macOS, and Linux using `tray_manager` and `window_manager`.
   - Minimize-to-tray on window close, click to restore, and context menu actions (Toggle listening, Exit).
   - MethodChannel `com.eluvk.xbb/clipboard_tray` handles native background clipboard hooks, supporting both `onClipboardTextChanged` and `onClipboardDataCollected`.
2. **Modern Clipboard UI**:
   - **Date Grouping**: Automatic chronological grouping with daily collapsible headers (`ClipboardDateGroupView`).
   - **Batch Management**: Multi-select action bar (`ClipboardBatchActionBar`) for batch cloud backup and batch deletion.
   - **In-Place Card Editing**: Inline editing card (`ClipboardOverviewCard`) allowing quick text modification without full-screen navigation.

---

## 5. Key Source Paths

- **Domain Model**: `app/lib/models/clipboard/model.dart`
- **Data Repository**: `app/lib/data/repositories/clipboard_repository.dart` (`ClipboardRepository`)
- **State Management**: `app/lib/presentation/clipboard/clipboard_providers.dart` (Riverpod Notifiers & Providers)
- **Service & Desktop Hook**:
  - Tray Service: `app/lib/controller/clipboard_tray.dart` (`ClipboardTrayService`)
  - Desktop Base: `app/lib/core/desktop/desktop_manager.dart` (`DesktopManager`)
- **Presentation Views**:
  - Main View: `app/lib/presentation/clipboard/modern_clipboard_view.dart` (`ModernClipboardView`)
  - Date Groups: `app/lib/presentation/clipboard/clipboard_date_group_view.dart` (`ClipboardDateGroupView`)
  - Batch Action Bar: `app/lib/presentation/clipboard/clipboard_batch_action_bar.dart` (`ClipboardBatchActionBar`)
  - Card & Overview: `app/lib/presentation/clipboard/clipboard_overview_card.dart` (`ClipboardOverviewCard`)
