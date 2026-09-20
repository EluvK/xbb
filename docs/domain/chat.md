# Chat Feature Domain

## 1. Domain Concept
The Chat module provides an integrated conversational AI interface supporting configurable assistant personas and real-time streaming LLM responses with native reasoning (chain-of-thought) visualization.

---

## 2. Core Entities

### 2.1 ChatAssistant
- Definition: Configured AI persona defining system prompt and model hyperparameters.
- Model: `ChatAssistant { String name, ChatAssistantType type, String description, String prompt, String? avatarUrl, ChatAssistantModelConfig? modelConfig }`
- Assistant Types: `system` (built-in templates) or `userDefined` (custom created by user).
- Model Config: Optional per-assistant override for provider, baseUrl, model name, temperature, and thinking parameters.

### 2.2 ChatConversation
- Definition: A conversation thread bound to a specific assistant.
- Model: `ChatConversation { String name, String assistantId, String assistantName, bool like }`

### 2.3 ChatMessage
- Definition: Individual message in a conversation.
- Model: `ChatMessage { String conversationId, ChatMessageRole role, String text, String? reasoningText, ChatUsage? usage }`
- Role: `system`, `user`, `assistant`.
- Reasoning Stream: `reasoningText` stores internal chain-of-thought tokens (e.g. DeepSeek-R1), rendered in an expandable thinking box in the UI.
- Usage: Token metrics (`promptTokens`, `completionTokens`, `totalTokens`).

---

## 3. Streaming & LLM Client

- Provider: Supported provider is currently DeepSeek (`packages/deepseek_client`), with extensible common abstractions in `lib/client/chat/llm/common.dart`.
- Streaming Pipeline: `ChatClient.sendMessageStream(...)` provides real-time token streaming with separate callbacks for reasoning chunks (`onStream`), error events (`onError`), and completion (`onSuccess`).

---

## 4. Key Source Paths

- Models & Codegen: `lib/models/chat/model.dart`, `lib/models/chat/db.dart`
- Chat Client: `lib/client/chat/client.dart`, `lib/client/chat/llm/deepseek.dart`
- Underlying Package: `packages/deepseek_client/`
- Page & Components: `lib/pages/chat/chat_page.dart`, `lib/components/chat/view_chat_messages.dart`, `lib/components/chat/chat_input.dart`, `lib/components/chat/chat_message_card.dart`
