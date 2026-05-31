# xbb 对话功能迁移文档（深度融合版）

> 目标：将 yaaa 的对话能力深度融入 xbb 现有结构。  
> 不新建独立 feature 根目录，不兼容 yaaa 旧本地数据和旧设置。

## 1. 融合策略与命名规范

- **目录融合**：沿用 xbb 现有目录职责：
  - `lib/models/` 放数据结构与仓储
  - `lib/controller/` 放状态与业务控制器
  - `lib/components/` 放 UI 组件
  - `lib/pages/` 放页面装配与路由级入口
  - `lib/utils/` 放通用工具、渲染与小型抽象
- **feature 名称**：统一使用 `chat`（对外文案可为 AI Chat）。
- **命名防冲突**：新增对象统一前缀 `Chat` 或语义前缀，避免与现有模块重名。
- **数据独立但结构统一**：新建 xbb 内部 chat 表结构，不迁移 yaaa 历史表。

---

## 2. 目标落位（xbb 结构内）

```text
lib/
  models/chat/
    model.dart               # ChatAssistant/Conversation/Message + @Repository 定义
    db.dart                  # 本地 DB 初始化与建表入口
    model.g.dart             # 生成：LocalStore/Repository/Controller/SyncEngine
    model.freezed.dart       # 生成：freezed 数据类

  controller/
    chat.dart                # ChatConversationController / ChatMessageController
    chat_assistant.dart      # （可选）助手模板与 prompt 管理
    chat_setting.dart        # （可选）provider/baseUrl/apiKey/temperature

  components/chat/
    view_chat_messages.dart  # 消息列表区
    chat_input.dart          # 输入发送区
    chat_message_card.dart   # 单条消息渲染
    chat_session_list.dart   # （可选）会话列表
    chat_search_box.dart     # （可选）历史搜索

  pages/chat/
    chat_page.dart           # 对话页（Tab 主入口）

  client/chat/
    client.dart              # 调用入口
    llm/common.dart
    llm/openai.dart          # 或 deepseek.dart

  utils/
    markdown_chat.dart       # 可复用 markdown 渲染器（如需）
```

说明：
- `models/chat/` 与 xbb 当前 `models/task`、`models/notes` 风格保持一致，核心以 `@Repository` + 代码生成为主。
- `components/chat/` 与 `components/task`、`components/notes` 风格一致。
- Chat 的本地仓储与基础 Controller 不手写 CRUD，统一依赖 `model.g.dart` 生成结果。

---

## 3. 分步迁移执行清单

以下步骤按顺序执行，每步都可独立验收。

### Step 0：结构融合设计与命名落盘（先定规则）

**要做什么**
- 固化 `chat` 在 xbb 的落位（models/controller/components/pages/client）。
- 定义核心实体与控制器命名，避免后续反复改名。
- 在主页和设置中预留 chat feature 标识。

**参考文件**
- 结构参考：`xbb/lib/models/task/model.dart`、`xbb/lib/models/task/db.dart`
- 结构参考：`xbb/lib/components/task/view_tasks.dart`
- 结构参考：`xbb/lib/controller/setting.dart`
- 枚举参考：`xbb/lib/utils/text_input.dart`（`AppFeatureMetaEnum`）

**命名建议（本次迁移固定）**
- model:
  - `ChatAssistant`
  - `ChatAssistantType`
  - `ChatConversation`
  - `ChatMessage`
  - `ChatMessageRole`
  - `ChatUsage`
- db/repo:
  - `ChatDB`
  - `ChatAssistantRepository`（生成）
  - `ChatConversationRepository`（生成）
  - `ChatMessageRepository`（生成）
- controller:
  - `ChatAssistantController`（生成）
  - `ChatConversationController`（生成）
  - `ChatMessageController`（生成）
  - `controller/chat.dart` 作为编排层（后续实现）
  - `ChatSettingController`（二期可选）
- page/component:
  - `ChatPage`
  - `ViewChatMessages`
  - `ChatInput`
  - `ChatMessageCard`

**与 xbb 现有功能融合点**
- `HomeTabIndex` 增加 `chat`。
- `AppFeatureMetaEnum` 增加 `enableChat`（图标、标题、颜色）。
- `AppFeaturesManagement` 增加 `enableChat` 开关（默认建议 true）。

**验收标准**
- 命名方案不与现有类冲突。
- 新增 chat feature 在设置模型上有开关位（即使 UI 暂未展示）。

---

### Step 1：先做 `models/chat` 数据结构与数据库

**要做什么**
- 用 xbb 的 syncstore 模型范式定义数据结构：`@Repository + freezed + json_serializable`。
- 通过生成代码提供本地 `LocalStore* / *Repository / *Controller / *SyncEngine`。
- 在 `db.dart` 中接入生成 SQL，完成本地 DB 初始化。

**参考文件（主）**
- `yaaa/lib/model/conversation.dart`

**参考文件（xbb 风格）**
- `xbb/lib/models/task/model.dart`
- `xbb/lib/models/task/db.dart`
- `xbb/lib/models/notes/db.dart`

**当前已落地结构（以代码为准）**
- `ChatAssistant`（table: `assistant`）
  - `name` / `type` / `description` / `prompt` / `avatarUrl`
- `ChatConversation`（table: `conversation`）
  - `name` / `assistantId` / `assistantName` / `like`
- `ChatMessage`（table: `message`, `parentIdField: conversationId`）
  - `conversationId` / `role` / `text` / `reasoningText` / `usage`
- `ChatUsage`
  - `promptTokens` / `completionTokens` / `totalTokens`

**本地表结构说明（生成）**
- 每个 `@Repository` 对应一张本地表：`assistant` / `conversation` / `message`。
- 表结构统一为 syncstore DataItem 形态：
  - `id` / `created_at` / `updated_at` / `owner` / `parent_id` / `unique` / `sync_status` / `color_tag` / `body`
- 业务字段存于 `body` JSON（例如 `ChatMessage.usage` 以嵌套 JSON 方式持久化）。

**落地说明**
- DB 文件当前为 `chat.db`（按用户目录隔离，与现有模块一致）。
- 不实现 yaaa 的版本兼容迁移逻辑，只保留 xbb 当前版本需要的 schema。

**验收标准**
- `model.g.dart` 成功生成 `ChatAssistant/Conversation/Message` 的 LocalStore、Repository、Controller。
- 能通过生成的 repository/controller 完成会话创建、消息写入、按 `parentId(conversationId)` 读取消息。

---

### Step 2：实现 `controller/chat.dart` 核心状态流

**要做什么**
- 实现会话状态管理、消息加载、发送占位、流式更新、异常处理。

**参考文件（主）**
- `yaaa/lib/controller/conversation.dart`

**参考文件（xbb 状态风格）**
- `xbb/lib/controller/syncstore.dart`
- `xbb/lib/controller/setting.dart`

**最小状态集**
- `conversationList`
- `currentConversationId`
- `messageList`
- `waitingForResponse`

**落地说明**
- 先不做复杂分页，后续再补 `loadHistory` 优化。
- `controller/chat.dart` 作为编排层，优先复用 `model.g.dart` 里的 `ChatConversationController / ChatMessageController / ChatAssistantController`。

**验收标准**
- 切换会话能刷新消息。
- 发送消息立即回显，assistant 占位可更新。

---

### Step 3：接 `client/chat` 调用链（先单 provider）

**要做什么**
- 建立统一 chat client 调用入口。
- 支持流式回调三段：`onStream` / `onError` / `onSuccess`。

**参考文件（主）**
- `yaaa/lib/client/client.dart`
- `yaaa/lib/client/llm/common.dart`
- `yaaa/lib/client/llm/openai.dart` 或 `yaaa/lib/client/llm/deepseek.dart`

**落地说明**
- MVP 只接一个 provider，配置先硬编码在 `controller/chat.dart` 或 `client/chat/client.dart`。
- 后续再迁设置 UI。

**验收标准**
- 一条用户消息能触发流式响应并最终保存到本地。

---

### Step 4：在 `components/chat` 完成最小 UI 闭环

**要做什么**
- 实现消息列表组件、输入组件、消息卡片组件。

**参考文件（主）**
- `yaaa/lib/components/conversation.dart`
- `yaaa/lib/components/chatbox.dart`
- `yaaa/lib/components/message.dart`
- `yaaa/lib/components/markdown_message.dart`

**参考文件（xbb 组件风格）**
- `xbb/lib/components/notes/post_viewer.dart`
- `xbb/lib/components/notes/markdown_renderer.dart`
- `xbb/lib/components/task/view_tasks.dart`

**落地说明**
- 优先复用 xbb 现有 markdown 渲染能力，减少重复代码。
- 搜索框、快捷键、会话侧栏先不做或做简版。

**验收标准**
- 页面具备输入发送、消息渲染、复制文本、时间展示。

---

### Step 5：在 `pages/chat/chat_page.dart` 装配页面并接入 Home Tab

**要做什么**
- 新建 `ChatPage`，装配 `components/chat/*`。
- 在 `xbb/lib/pages/home.dart` 中新增 chat tab。

**参考文件（接入点）**
- `xbb/lib/pages/home.dart`
- `xbb/lib/components/common/settings.dart`（feature 开关展示逻辑）
- `xbb/lib/utils/text_input.dart`（feature 元数据）
- `xbb/lib/utils/translation.dart`（tab 文案）

**落地说明**
- `HomeTabIndex` 增加 `chat`。
- `_activeIndices` 按 `settingController.chatEnabled` 控制是否展示。
- 新增国际化 key：`home_bar_title_chat`、`app_enable_chat_feature`。

**验收标准**
- 首页可切换到 Chat。
- 关闭 chat feature 时首页不显示 chat tab。

---

### Step 6：初始化与依赖收口

**要做什么**
- 在 `main.dart` 注册 chat controllers。
- 补齐 `pubspec.yaml` 必要依赖并验证。

**参考文件**
- `xbb/lib/main.dart`
- `xbb/pubspec.yaml`
- `yaaa/pubspec.yaml`

**依赖关注点**
- `scrollable_positioned_list`（如果使用）
- `deepseek_client`（如果选 deepseek）
- `markdown_widget` / `flutter_math_fork`（若沿用现有渲染则通常已具备）

**验收标准**
- `flutter pub get` 成功。
- `flutter analyze` 无新增关键错误。

---

## 4. Step 0 之后的可选增强（二期）

1. **会话侧栏/联系人区**
   - 参考：`yaaa/lib/components/contact.dart`、`yaaa/lib/pages/contact.dart`
2. **搜索历史定位**
   - 参考：`yaaa/lib/components/searchbox.dart`
3. **助手模板管理**
   - 参考：`yaaa/lib/components/assistants.dart`、`yaaa/lib/pages/edit_assistants.dart`、`yaaa/lib/model/assistant.dart`、`yaaa/lib/controller/assistant.dart`
4. **快捷键体系**
   - 参考：`yaaa/lib/controller/shortcuts.dart`、`yaaa/lib/utils/key_intents.dart`
5. **模型设置页**
   - 参考：`yaaa/lib/pages/setting.dart`、`yaaa/lib/controller/setting.dart`、`yaaa/lib/model/llm.dart`

---

## 5. 快速映射表（yaaa -> xbb）

- `yaaa/lib/model/conversation.dart` -> `xbb/lib/models/chat/model.dart` + `xbb/lib/models/chat/db.dart`
- `yaaa/lib/controller/conversation.dart` -> `xbb/lib/controller/chat.dart`（编排层） + `xbb/lib/models/chat/model.g.dart`（生成控制器）
- `yaaa/lib/client/*` -> `xbb/lib/client/chat/*`
- `yaaa/lib/components/chatbox.dart` -> `xbb/lib/components/chat/chat_input.dart`
- `yaaa/lib/components/conversation.dart` -> `xbb/lib/components/chat/view_chat_messages.dart`
- `yaaa/lib/components/message.dart` -> `xbb/lib/components/chat/chat_message_card.dart`
- `yaaa/lib/pages/conversation.dart` -> `xbb/lib/pages/chat/chat_page.dart`

---

## 6. 最小回归用例

- 新建会话并切换会话。
- 发送消息后看到 assistant 流式回复。
- 重启后会话与消息可读取。
- Home 中 chat tab 可正常显示/隐藏。
- 无效 key 或网络异常时能提示，不崩溃。

---

## 7. 结论

本方案是“**结构深度融合**”路线：按 xbb 现有 `models/controller/components/pages` 拆分 chat 功能，避免引入平行目录体系。  
执行顺序从 Step 0 到 Step 6，能最快拿到稳定可用的聊天闭环，并且后续迭代成本最低。
