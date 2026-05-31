# xbb Chat Migration Plan (Re-baselined)

This document reflects the current implementation status and defines the immediate next iteration.

## Completed in Current Iteration

- Architecture integrated into existing xbb layout:
  - `lib/models/chat`
  - `lib/controller/chat.dart`
  - `lib/client/chat/*`
  - `lib/components/chat/*`
  - `lib/pages/chat/chat_page.dart`
- Chat models and generated repositories/controllers are in place.
- Home tab + feature toggle plumbing is integrated (`enableChat`, chat tab in home).
- Core orchestration implemented in `ChatController`:
  - local-first conversation/message writes
  - stream lifecycle (`streaming/completed/error/cancelled`)
  - retry/rewrite-last-turn constraints
  - manual conversation sync with watermark progression
  - remote-first deletion fallback behavior
- Local in-repo `deepseek_client` package added and wired through workspace path dependency.
- Chat request pipeline supports global settings and assistant model override fields:
  - override-able: `provider/baseUrl/model/temperature/thinkingEnabled/reasoningEffort`
  - global-only: `apiKey`
- Chat UI text and status labels are now translated via `translation.dart` keys.

## Locked Product/Behavior Decisions

- No separate feature root; keep deep integration with xbb conventions.
- `ChatConversation` and `ChatMessage` remain local-first with manual conversation-level sync.
- `ChatAssistant` remains real-time sync via generated controller paths.
- Local conversation ID is stable; remote mapping uses `remoteConversationId`.
- Sync candidate scope is `completed` messages only.
- Retry/rewrite allowed only on last user turn; synced prefix is immutable.
- MVP streaming concurrency is global single request; switching conversation cancels current stream.
- Deletion default is remote-first; remote failure keeps local and marks sync failure.

## Current Risks / Follow-ups

- Assistant management UI is still minimal; model override editing UX is not yet exposed.
- More granular sync feedback and diagnostics can be improved (batch result UX).
- Background stream continuation across conversations is intentionally deferred.

## Next Iteration Scope (Step 4)

1. Assistant management UX
   - add assistant create/edit UI
   - expose model override fields safely
   - keep `apiKey` global-only
2. Chat setting panel polish
   - improve validation/affordances for provider config
   - optional model list fetch and picker (DeepSeek `/models`)
3. Message rendering polish
   - optional markdown rendering improvements
   - reasoning text display controls (collapse/expand)
4. Sync UX refinement
   - clearer per-conversation sync result toasts
   - better empty and edge-state messaging

## Verification Baseline

- `flutter pub get` succeeds.
- `dart analyze` passes for chat/client/controller/component/translation/model paths.
- End-to-end smoke checks:
  - create conversation
  - send/stream response
  - retry failed/cancelled last turn
  - manual sync and resume
  - delete conversation with remote-first semantics

## Not in Scope (for now)

- Backward compatibility with yaaa legacy local data/settings
- Multi-provider runtime beyond DeepSeek in production path
- Branching/forking conversation history model
- Background streaming continuation after conversation switch
