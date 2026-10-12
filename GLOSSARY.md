# 项目领域知识字典 (GLOSSARY)

本项目核心领域概念、中英文术语对照、代码物理索引及决策关联。

> **维护守则**：
> 1. 本文档仅用于概念定义与物理索引，严禁记录具体实现细节。
> 2. 每个条目必须包含中英文对照、精准定义与代码物理锚点。
> 3. 严格遵循 `_Avoid_` 约束，杜绝使用已被排除的近义词或废弃旧词。

---

## 核心业务域 (Core Business Domains)

### Repo (笔记本 / 知识库)
- **定义**: 笔记模块的顶层容器，用于归类管理成组文章，支持多成员 ACL 权限共享与好友订阅。
- **别名**: 笔记本、知识库、分类库、Notebook、Folder
- **_Avoid_**: Folder（代码实体统一为 `Repo`，避免与文件系统目录混淆）
- **代码索引**: `app/lib/data/repositories/notes_repository.dart` (`NotesRepository`, `Repo`)
- **关联决策**: [ADR-0001: SQLite 按用户 ID 物理目录隔离](./docs/adr/0001-user-isolated-sqlite.md)

### Post (文章 / 便签)
- **定义**: 隶属于某一 `Repo` 的独立文章或富文本笔记实体，包含 Markdown 正文、分类及颜色标签。
- **别名**: 文章、笔记、便签、文档、Article、Note
- **_Avoid_**: Memo
- **代码索引**: `app/lib/models/notes/model.dart` (`Post`), `app/lib/presentation/notes/modern_notes_view.dart` (`ModernNotesView`)

### Comment (批注 / 讨论)
- **定义**: 针对具体 `Post` 发起的树状讨论评论，支持父子级多层嵌套回复及正文稳定段落/块级锚定。
- **别名**: 批注、评论、段落批注、讨论、Feedback
- **_Avoid_**: Review（Review 专指审核流程，此处为文章讨论）
- **代码索引**: `app/lib/presentation/notes/comment_widgets.dart` (`CommentListWidget`, `CommentTreeNode`)
- **关联决策**: [ADR-0007: 基于稳定块标识的树状批注系统](./docs/adr/0007-stable-block-comments.md)

### CheckList (任务清单)
- **定义**: 任务模块的核心容器，以连续工作区形式承载当前活动中或已历史归档的待办条目集合。
- **别名**: 清单、任务列表、检查单、工作区、TaskList
- **_Avoid_**: TodoList（统一为 CheckList，强调可勾选与文档化属性）
- **代码索引**: `app/lib/data/repositories/task_repository.dart` (`TaskRepository`, `CheckList`)

### TaskItem (待办项)
- **定义**: 清单内的离散待办单元，携带完成状态、完成时间戳及支持拖拽排序的顺序权重。
- **别名**: 待办项、任务条目、子任务、TodoItem
- **_Avoid_**: ActionItem（ActionItem 专指会议待办，此处为个人清单条目）
- **代码索引**: `app/lib/models/task/model.dart` (`TaskItem`), `app/lib/presentation/task/modern_task_view.dart` (`ModernTaskView`)

### Tracker (追踪器)
- **定义**: 长期行为与目标追踪的主体配置实体，支持习惯周期 (Event)、目标里程碑 (Milestone) 与重要纪念日 (Anniversary) 三类多态。
- **别名**: 追踪器、习惯追踪、目标追踪、纪念日追踪、TargetTracker
- **代码索引**: `app/lib/data/repositories/tracker_repository.dart` (`TrackerRepository`, `Tracker`)

### TrackerRecord (追踪记录)
- **定义**: 依附于特定 `Tracker` 产生的时序日志项，按追踪器类型分别表达时间戳、完成布尔值或量化数值。
- **别名**: 追踪记录、习惯打卡打卡点、进度记录、LogEntry
- **_Avoid_**: HistoryEntry（HistoryEntry 专指剪贴板历史）
- **代码索引**: `app/lib/models/tracker/model.dart` (`TrackerRecord`), `app/lib/presentation/tracker/tracker_history_sheet.dart` (`ViewTrackerDetailPage`)

### CheckinEvent (打卡事件)
- **定义**: 每日打卡模块中由用户定义的打卡主题（如晨跑、阅读），具备固定 ARGB 标识色与描述。
- **别名**: 打卡事件、打卡项目、习惯项、HabitEvent
- **_Avoid_**: Attendance（Attendance 专指企业考勤，非个人习惯打卡）
- **代码索引**: `app/lib/data/repositories/checkin_repository.dart` (`CheckinRepository`, `CheckinEvent`)

### CheckinRecord (打卡记录)
- **定义**: 记录特定打卡事件在某一自然日的完成凭据，由设备本地日期 `localDayKey` 严格限制单日单次完成。
- **别名**: 打卡记录、完成记录、DailyRecord
- **代码索引**: `app/lib/models/checkin/model.dart` (`CheckinRecord`), `app/lib/presentation/checkin/modern_checkin_view.dart` (`ModernCheckinView`)
- **关联决策**: [ADR-0003: 打卡本地时区单次判定与禁止预打卡](./docs/adr/0003-checkin-local-day-boundary.md)

### ClipboardHistoryEntry (剪贴板记录)
- **定义**: 跨平台桌面后台捕获的文本剪贴记录，默认标记为本地私有，仅在用户显式确认后同步上云。
- **别名**: 剪贴板历史、剪切记录、历史条目、ClipEntry
- **代码索引**: `app/lib/data/repositories/clipboard_repository.dart` (`ClipboardRepository`, `ClipboardHistoryEntry`)
- **关联决策**: [ADR-0002: 剪贴板本地优先与绝对隐私同步](./docs/adr/0002-clipboard-local-first-privacy.md)

### ChatAssistant (AI 助手)
- **定义**: 配置化 AI 人格实体，定义系统提示词、温度值及关联的 LLM 模型推理超参数。
- **别名**: AI助手、助理角色、模型配置、Persona
- **_Avoid_**: Bot（统一为 Assistant）
- **代码索引**: `app/lib/data/repositories/chat_repository.dart` (`ChatRepository`, `ChatAssistant`)

### ChatConversation (对话会话)
- **定义**: 绑定到特定 `ChatAssistant` 的独立对话会话线程。
- **别名**: 会话、对话、聊天窗口、Session、Thread
- **_Avoid_**: Channel（Channel 专指消息通道或通知通道）
- **代码索引**: `app/lib/models/chat/model.dart` (`ChatConversation`)

### ChatMessage (对话消息)
- **定义**: 会话内的单条消息交互载体，包含角色、文本内容、Token 消耗以及模型原生思考链推理流。
- **别名**: 对话消息、聊天记录、Message
- **_Avoid_**: Prompt（Prompt 专指输入给模型的系统引导词，消息包含 system/user/assistant 全角色）
- **代码索引**: `app/lib/presentation/chat/modern_chat_view.dart` (`ModernChatView`, `ChatMessage`)

---

## 基础设施与数据同步 (Infrastructure & Sync)

### SyncServer (同步服务端)
- **定义**: 采用 Rust 编写的现代化集中式云端同步服务，基于 Salvo + SQLite 提供日志流与版本化分发。
- **别名**: 同步服务器、服务端、SyncBackend
- **_Avoid_**: NodeSync（统一为 Rust SyncServer）
- **代码索引**: `server/src/` (`server::router::create_app_router`, `server::sync`)

### SyncWorker (同步守护进程)
- **定义**: 客户端后台单例同步守护进程，负责变更防抖、互斥调度、出队 Push 与服务端变更流 Pull。
- **别名**: 同步工人、后台同步器、SyncDaemon
- **_Avoid_**: SyncTimer（SyncWorker 具备本地写通知与网络唤醒机制，非单一轮询定时器）
- **代码索引**: `app/lib/sync/v2/sync_worker.dart` (`SyncWorker`)

### Outbox (待发变更队列)
- **定义**: 客户端本地持久化的事务性待发变更队列表，确保业务写入与同步变更日志原子落盘。
- **别名**: 出队日志表、待发队列、MutationOutbox
- **_Avoid_**: SyncQueue（Outbox 专指单事务持久化保证零丢失的本地事务发件箱模式）
- **代码索引**: `app/lib/sync/v2/outbox_dao.dart` (`OutboxDao`, `OutboxItem`)
- **关联决策**: [ADR-0004: Drift 响应式存储与单事务 Outbox 日志流持久化](./docs/adr/0004-drift-outbox-storage.md)

### DataItem (通用数据信封)
- **定义**: SyncStore 协议的数据传输载体，为底层各业务模型封装通用 ID、所有者、父子关系、同步状态与时间戳。
- **别名**: 数据信封、同步实体包装器、EntityEnvelope
- **_Avoid_**: DTO（DataItem 为双向同步权威传输与持久化信封，非单一方向的数据传输对象）
- **代码索引**: `app/packages/syncstore_client/` (`DataItem`)

### ACLMask (权限掩码)
- **定义**: 基于 6-bit 权限掩码的访问控制抽象，表达对实体的读取、修改、删除及多层级子项追加权限。
- **别名**: 权限掩码、访问控制掩码、PermissionBitmask
- **_Avoid_**: Role（ACLMask 为细粒度二进制权限位，非粗粒度角色名）
- **代码索引**: `app/packages/syncstore_client/` (`ACLMask`), `app/lib/core/acl/acl_repository.dart` (`AclRepository`)

### AppDriftEngine (响应式数据库引擎)
- **定义**: 基于 Drift 强类型 Schema 的响应式数据库操作层，提供 watchQuery 依赖流与单事务原子变更执行能力。
- **别名**: Drift引擎、响应式数据引擎、StorageEngine
- **_Avoid_**: SqliteHelper（AppDriftEngine 具备强类型流式通知与事务封装，非朴素原生 SQLite 包装层）
- **代码索引**: `app/lib/data/drift/app_drift_database.dart` (`AppDriftEngine`), `app/lib/data/drift/schema.dart`
- **关联决策**: [ADR-0004: Drift 响应式存储与单事务 Outbox 日志流持久化](./docs/adr/0004-drift-outbox-storage.md)

### @Repository (仓储代码生成注解)
- **定义**: 作用于领域模型的代码生成声明式注解，驱动自动化生成 Drift Schema 映射与持久化辅助代码。
- **别名**: 仓储注解、模型注解、SyncEntityAnnotation
- **代码索引**: `app/packages/sync_annotation/` (`Repository`), `app/packages/sync_generator/` (`RepositoryGenerator`)
