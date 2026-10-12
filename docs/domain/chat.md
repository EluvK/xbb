# Chat Feature Domain

## 1. Domain Concept
The Chat module provides an integrated conversational AI workspace supporting configurable assistant personas, dialogue threads, and real-time streaming LLM responses with first-class chain-of-thought (reasoning) token visualization.

---

## 2. Core Entities & Schema

### 2.1 ChatAssistant (AI 助手)
- **Definition**: Configured AI persona defining system prompt, temperature, avatar, and provider parameters.
- **Model**: `ChatAssistant { String name, ChatAssistantType type, String description, String prompt, String? avatarUrl, ChatAssistantModelConfig? modelConfig }`
- **Drift Table**: table `chat_assistant` in `app_v2.db`.
- **Types**: `system` (built-in templates) or `userDefined` (custom created by user).

### 2.2 ChatConversation (对话会话)
- **Definition**: Conversation thread bound to a specific assistant.
- **Model**: `ChatConversation { String name, String assistantId, String assistantName, bool like }`
- **Drift Table**: table `chat_conversation` in `app_v2.db` (`parent_id = assistantId`).

### 2.3 ChatMessage (对话消息)
- **Definition**: Individual message in a conversation.
- **Model**:
  ```dart
  ChatMessage {
    String conversationId,
    ChatMessageRole role,
    String text,
    String? reasoningText,
    ChatUsage? usage,
    bool favorite,
  }
  ```
- **Drift Table**: table `chat_message` in `app_v2.db` (`parent_id = conversationId`).
- **Chain of Thought**: `reasoningText` holds raw model reasoning stream (e.g. DeepSeek-R1), rendered in an expandable thinking box.

---

## 3. Streaming & LLM Client Pipeline

- **Client Package**: `app/packages/deepseek_client/` provides Server-Sent Events (SSE) streaming.
- **Client Wrapper**: `ChatClient` (`app/lib/client/chat/client.dart`) manages request dispatch, abort controllers, token usage recording, and separated chunk callbacks for reasoning and text response.
- **Repository & State**: `ChatRepository` saves messages and conversation state locally, while Riverpod notifiers in `chat_providers.dart` expose active conversation streams to the UI.

---

## 4. Key Source Paths

- **Domain Model**: `app/lib/models/chat/model.dart`
- **Data Repository**: `app/lib/data/repositories/chat_repository.dart` (`ChatRepository`)
- **State Management**: `app/lib/presentation/chat/chat_providers.dart` (Riverpod Notifiers & StateProviders)
- **LLM Client Layer**:
  - Common Client: `app/lib/client/chat/client.dart`
  - DeepSeek Implementation: `app/lib/client/chat/llm/deepseek.dart`
  - Internal Package: `app/packages/deepseek_client/`
- **Presentation View**: `app/lib/presentation/chat/modern_chat_view.dart` (`ModernChatView`)
- **Route Screen**: `app/lib/pages/chat/chat_page.dart`
