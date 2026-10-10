# 项目领域知识字典 (GLOSSARY)

本项目核心领域概念、中英文术语对照、代码物理索引及决策关联。

> **维护守则**：
> 1. 本文档仅用于概念定义与物理索引，严禁记录具体实现细节。
> 2. 每个条目必须包含中英文对照、精准定义与代码物理锚点。
> 3. 严格遵循 `_Avoid_` 约束，杜绝使用已被排除的近义词或废弃旧词。

---

## 核心业务域 (Core Business Domains)

### Repo (笔记本 / 知识库)
- **定义**: 笔记模块的顶层容器，用于归类管理成组文章，支持多成员 ACL 权限共享。
- **别名**: 笔记本、知识库、分类库、Notebook、Folder
- **_Avoid_**: Folder（代码实体统一为 `Repo`，避免与文件系统目录混淆）
- **代码索引**: `lib/models/notes/` (`Repo`, `NotesDB`)
- **关联决策**: [ADR-0001: SQLite 按用户 ID 物理分库隔离](./docs/adr/0001-user-isolated-sqlite.md)

### Post (文章 / 便签)
- **定义**: 隶属于某一 `Repo` 的独立文章或富文本笔记实体，包含 Markdown 内容与分类。
- **别名**: 文章、笔记、便签、文档、Article、Note
- **_Avoid_**: Memo（便签统一为 Post，Memo 在本项目中特指简短备忘）
- **代码索引**: `lib/models/notes/` (`Post`)

### Comment (批注 / 讨论)
- **定义**: 针对具体 `Post` 发起的讨论评论，支持父子级嵌套回复及正文段落级锚定。
- **别名**: 批注、评论、段落批注、讨论、Feedback
- **_Avoid_**: Review（Review 专指审核流程，此处为文章讨论）
- **代码索引**: `lib/models/notes/` (`Comment`)

### CheckList (任务清单)
- **定义**: 任务模块的核心容器，以连续文档形式承载当前活动中或已历史归档的待办条目集合。
- **别名**: 清单、任务列表、检查单、工作区、TaskList
- **_Avoid_**: TodoList（统一为 CheckList，强调可勾选与文档化属性）
- **代码索引**: `lib/models/task/` (`CheckList`, `TaskDB`)

### TaskItem (待办项)
- **定义**: 清单内的离散待办单元，携带完成状态、完成时间戳及自定义排列顺序。
- **别名**: 待办项、任务条目、子任务、TodoItem
- **_Avoid_**: ActionItem（ActionItem 专指会议待办，此处为个人清单条目）
- **代码索引**: `lib/models/task/` (`TaskItem`)

### Tracker (追踪器)
- **定义**: 长期行为与周期追踪的主体配置实体，支持习惯周期 (Event)、目标里程碑 (Milestone) 与重要纪念日 (Anniversary) 三类多态。
- **别名**: 追踪器、习惯追踪、目标追踪、纪念日追踪、TargetTracker
- **_Avoid_**: Monitor（Monitor 专指系统性能与日志大屏监控，不负责用户业务目标追踪）
- **代码索引**: `lib/models/tracker/` (`Tracker`, `TrackerDB`)

### TrackerRecord (追踪记录)
- **定义**: 依附于特定 `Tracker` 产生的时序日志项，按追踪器类型分别表达时间戳、完成布尔值或量化数值。
- **别名**: 追踪记录、习惯打卡打卡点、进度记录、LogEntry
- **_Avoid_**: HistoryEntry（HistoryEntry 专指剪贴板历史）
- **代码索引**: `lib/models/tracker/` (`TrackerRecord`)

### CheckinEvent (打卡事件)
- **定义**: 每日打卡模块中由用户定义的打卡主题（如晨跑、阅读），具备固定 ARGB 标识色与名称。
- **别名**: 打卡事件、打卡项目、习惯项、HabitEvent
- **_Avoid_**: Attendance（Attendance 专指企业考勤，非个人习惯打卡）
- **代码索引**: `lib/models/checkin/` (`CheckinEvent`, `CheckinDB`)

### CheckinRecord (打卡记录)
- **定义**: 记录特定打卡事件在某一自然日的完成凭据，由设备本地日期严格限制单日单次完成。
- **别名**: 打卡记录、完成记录、DailyRecord
- **_Avoid_**: ClockIn（ClockIn 强调上下班打卡签到动作）
- **代码索引**: `lib/models/checkin/` (`CheckinRecord`)
- **关联决策**: [ADR-0003: 打卡本地时区单次判定与禁止预打卡](./docs/adr/0003-checkin-local-day-boundary.md)

### ClipboardHistoryEntry (剪贴板记录)
- **定义**: 本地后台捕获的文本剪贴记录，默认标记为本地私有，仅在用户显式确认后同步上云。
- **别名**: 剪贴板历史、剪切记录、历史条目、ClipEntry
- **_Avoid_**: PasteboardEntry（跨端命名统一定义为 Clipboard）
- **代码索引**: `lib/models/clipboard/` (`ClipboardHistoryEntry`, `ClipboardDB`)
- **关联决策**: [ADR-0002: 剪贴板本地优先与绝对隐私同步](./docs/adr/0002-clipboard-local-first-privacy.md)

### ChatAssistant (AI 助手)
- **定义**: 配置化 AI 人格实体，定义系统提示词、温度值及关联的 LLM 模型推理超参数。
- **别名**: AI助手、助理角色、模型配置、Persona
- **_Avoid_**: Bot（统一为 Assistant）
- **代码索引**: `lib/models/chat/` (`ChatAssistant`, `ChatDB`)

### ChatConversation (对话会话)
- **定义**: 绑定到特定 `ChatAssistant` 的独立对话会话线程。
- **别名**: 会话、对话、聊天窗口、Session、Thread
- **_Avoid_**: Channel（Channel 专指消息通道或通知通道）
- **代码索引**: `lib/models/chat/` (`ChatConversation`)

### ChatMessage (对话消息)
- **定义**: 会话内的单条消息交互载体，包含角色、文本内容、Token 消耗以及模型原生思考链推理流。
- **别名**: 对话消息、聊天记录、Message
- **_Avoid_**: Prompt（Prompt 专指输入给模型的系统引导词，消息包含 system/user/assistant 全角色）
- **代码索引**: `lib/models/chat/` (`ChatMessage`)

---

## 基础设施与数据同步 (Infrastructure & Sync)

### DataItem (通用数据信封)
- **定义**: SyncStore 协议的数据传输载体，为底层各业务模型封装通用 ID、所有者、父子关系、同步状态与时间戳。
- **别名**: 数据信封、同步实体包装器、EntityEnvelope
- **_Avoid_**: DTO（DataItem 为双向同步权威传输与持久化信封，非单一方向的数据传输对象）
- **代码索引**: `packages/syncstore_client/` (`DataItem`)

### ACLMask (权限掩码)
- **定义**: 基于 6-bit 权限掩码的访问控制抽象，表达对实体的读取、修改、删除及多层级子项追加权限。
- **别名**: 权限掩码、访问控制掩码、PermissionBitmask
- **_Avoid_**: Role（ACLMask 为细粒度二进制权限位，非粗粒度角色名）
- **代码索引**: `packages/syncstore_client/` (`ACLMask`)

### @Repository (仓储代码生成注解)
- **定义**: 作用于领域模型的代码生成声明式注解，驱动自动化生成 SQLite DDL、CRUD 存储器、GetX 控制器及同步引擎。
- **别名**: 仓储注解、模型注解、SyncEntityAnnotation
- **_Avoid_**: @Entity（框架专属注解为 @Repository）
- **代码索引**: `packages/sync_annotation/` (`Repository`)
- **代码索引**: `packages/sync_generator/` (`RepositoryGenerator`)
