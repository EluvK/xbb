# Windows 托盘 + 剪贴板备份（V1）初期需求分析与设计稿

## 1. 背景与目标

### 1.1 背景
- 当前项目是 Flutter 应用，已具备本地数据能力（sqflite/sqflite_ffi）与设置页能力。
- 现状中 Windows 端尚未集成托盘能力与系统级剪贴板监听能力。
- 目标场景是 Windows 桌面常驻：用户复制过的内容可被本地记录，按需手动挑选后再进行长期保存/同步。

### 1.2 目标
- 在 Windows 下提供稳定的托盘常驻能力。
- 在 Windows 下以事件驱动方式监听剪贴板文本并本地缓存。
- 提供“手动暂停监听”“手动选中后同步（后续对接）”的低打扰交互。
- 以最小侵入方式接入现有导航与设置体系。

---

## 2. 本次讨论后的决策汇总

## 2.1 已确认决策
- 技术路径：`原生 Win32 + MethodChannel`。
- 监听机制：采用 `AddClipboardFormatListener` 事件驱动。
- 托盘交互：关闭主窗口时最小化到托盘；托盘菜单至少支持“显示主窗口 / 退出程序”。
- 启动策略：V1 暂不做开机启动。
- 功能范围：V1 只做 Windows。
- 数据范围：分阶段推进，V1 先支持文本；图片/HTML/文件后续阶段支持。
- 云端策略：不是自动双写；先本地缓存，用户“手动选中后”再同步。
- 导航位置：剪贴板历史作为一级 Tab。
- 开关策略：剪贴板备份能力默认关闭。
- 隐私策略：V1 仅做手动暂停（不做敏感应用自动豁免）。
- 暂停入口：托盘开关 + 设置页开关，状态双向同步。
- 托盘信息：只显示监听状态与最近采集时间，不显示具体内容。
- 去重策略：相邻去重 + 时间窗口去重（30 秒）。
- 进程模型：单实例运行。

### 2.2 明确不在本稿展开
- SyncStore 同步可靠性与失败重试策略细节（归属 SyncStore 侧议题）。
- 图片/HTML/文件格式的完整采集链路。
- 跨平台（Android/iOS/macOS）统一实现。

---

## 3. 范围定义

### 3.1 In Scope（V1）
- 事件驱动剪贴板文本监听。
- 本地存储文本剪贴板历史（可查询展示）。
- 去重（相邻 + 30 秒窗口）。
- 监听开关（托盘 + 设置）与状态同步。
- 剪贴板历史一级 Tab 展示。

### 3.2 Out of Scope（V1）
- 图片/HTML/文件格式落库。
- 自动开机启动。
- 敏感应用自动暂停采集。
- 自动上云同步与复杂同步状态机。

---

## 4. 方案设计（V1）

### 4.1 总体架构
- `Windows Runner (C++)`
  - 托盘图标注册与菜单事件处理。
  - 剪贴板监听窗口消息接收（`WM_CLIPBOARDUPDATE`）。
  - 通过 MethodChannel 向 Dart 上报事件。
- `Flutter (Dart)`
  - 监听状态管理（GetX）。
  - 剪贴板记录去重与入库。
  - 历史页展示、手动选择、手动同步入口。

### 4.2 平台通信
- Channel 建议：`com.eluvk.xbb/clipboard_tray`（命名可后续统一）。
- 原生 -> Dart 事件（建议）
  - `onClipboardTextChanged`: `{ text, timestamp }`
  - `onTrayToggleListening`: `{ enabled }`
  - `onTrayShowMainWindow`
  - `onTrayExitApp`
- Dart -> 原生命令（建议）
  - `setListeningEnabled(bool)`
  - `showMainWindow()`
  - `updateTrayStatus(...)`
  - `quitApp()`

### 4.3 数据与模型（V1）
- 数据原则：先可运行，不做注释占位式“伪字段”。
- 本地记录最小字段建议：
  - `id`
  - `content`
  - `contentHash`
  - `createdAt`
  - `localOnly`（用于“未手动同步”标识）
- 扩展字段建议：`extraJson`（可空），供后续图片/HTML元信息扩展。

> 说明：云端字段模型本轮不冻结，避免在未进入同步设计阶段时过早承诺。

### 4.4 去重策略
- 规则 1：相邻去重（与最新一条 `contentHash` 相同则跳过）。
- 规则 2：时间窗口去重（30 秒内相同 `contentHash` 跳过）。
- 规则作用域：本地入库前执行。

### 4.5 UI 与交互
- 设置页：
  - 功能总开关（默认关）
  - 监听状态开关（与托盘同步）
  - 本地保留策略配置（可配置）
- 一级 Tab：新增“剪贴板历史”入口。

### 4.6 生命周期与单实例
- 启动时仅在功能开关开启后注册托盘与剪贴板监听。
- 单实例模式：重复启动时唤醒已运行主窗口，不新开第二监听实例。

---

## 5. 非功能需求

### 5.1 性能
- 监听应为事件驱动，避免高频轮询。
- 高频复制场景下保持主线程不卡顿（入库异步化）。

### 5.2 稳定性
- 原生层异常不导致主进程崩溃（MethodChannel 调用需容错）。
- 托盘退出流程应保证资源释放（监听注销、窗口销毁）。

### 5.3 隐私
- 默认关闭监听。
- 提供明确“暂停监听”开关。
- 托盘提示不展示具体剪贴板内容。

---

## 6. 验收标准（DoD）

V1 验收采用以下 6 条：
- 剪贴板文本事件驱动入库。
- 相邻 + 30 秒去重生效。
- 监听暂停开关可通过托盘与设置页双向控制。
- 剪贴板历史可在一级 Tab 查看。

---

## 7. 风险与待定项

### 7.1 主要风险
- Win32 消息处理与 Flutter 窗口生命周期耦合，需重点做退出/恢复场景测试。
- 高频复制下的数据库写入抖动，需要在实现时关注批处理或轻量队列。

### 7.2 待定项（需在开发前冻结）
- 本地保留策略默认值（已确认“可配置”，默认值建议：`7 天 + 5000 条`）。
- 剪贴板历史 Tab 文案与图标命名。
- 本地表结构是否放入现有 DB 体系或独立 DB 文件。

---

## 8. 后续演进建议（V2+）
- 支持图片/HTML/文件格式采集与差异化存储。
- 增加敏感场景自动暂停（进程黑名单/窗口检测等）。
- 增加“手动选中后同步”的批处理体验与可观测状态。
- 视使用反馈决定是否引入开机启动配置。

---

## 9. V1.1 实施步骤（增量执行计划）

> 当前基线：Windows 托盘与设置联动已具备基础能力；以下计划聚焦“剪贴板文本监听 -> 本地历史 -> 手动确认上云”。

### Step 1：数据结构与存储层落地（先打地基）
- 目标：冻结最小可运行的数据模型与本地存储接口。
- 工作项：
  - 定义 `ClipboardHistoryEntry`：`data: String` + `localOnly: bool`（默认 `true`）。
  - 采用 `@Repository(collectionName: 'clipboard_history', tableName: 'entry', db: ClipboardDB)`。
  - 落地本地库接入：`clipboard.db`，并通过生成代码获得 repository/controller。
  - 接入初始化流程：在 SyncStore 重建后同步初始化 `ClipboardHistoryEntryController`。
- 产出：
  - Dart 模型 + DB schema + repository/controller API。
- 验收：
  - 可完成单条写入、按时间倒序查询、`localOnly` 状态读写。
  - 应用启动后 `ClipboardHistoryEntryController` 可完成初始化并可被 GetX 获取。

#### Step 1 当前进展（已完成）
- 新增模型与仓库定义：`lib/models/clipboard/model.dart`
- 新增数据库接入：`lib/models/clipboard/db.dart`
- 已生成代码：`lib/models/clipboard/model.g.dart`、`lib/models/clipboard/model.freezed.dart`
- 已接入初始化：`lib/controller/syncstore.dart` 中新增 `reInitClipboardSync(syncStoreClient)`

### Step 2：历史页 UI（一级 Tab）与基础交互
- 目标：让用户“看得见、选得中、可确认”。
- 工作项：
  - 新增“剪贴板历史”一级 Tab（受 `enableClipboardBackup` 开关控制）。
  - 左侧概览面板：总数、仅本地、已同步统计。
  - 右侧历史列表：内容摘要、采集时间、`localOnly` 状态展示。
  - 选择态与批量操作入口（“确认同步”按钮先做 UI stub，Step 5 接云端）。
  - 启动页候选 Tab 增加 Clipboard 项（仅在功能开启时可选）。
- 产出：
  - 可浏览历史 + 可选中条目 + 可触发确认动作的 UI。
- 验收：
  - 本地已有数据可稳定渲染，空态/长文本截断表现正常。

#### Step 2 当前进展（已完成）
- 一级 Tab 接入：`lib/pages/home.dart`
  - 新增 `HomeTabIndex.clipboard`
  - 新增 Tab 文案 `home_bar_title_clipboard`
  - 仅在 `clipboardBackupEnabled` 为 true 时展示
- 左侧概览组件：`lib/components/clipboard/view_clipboard_overview.dart`
- 右侧历史组件：`lib/components/clipboard/view_clipboard_history.dart`
  - 支持选择、多选清空、确认同步入口（toast 占位）
- 启动页设置联动：
  - `lib/controller/setting.dart` 新增 `AppHomeStartupTabIndex.clipboard`
  - `lib/components/common/settings.dart` 启动页候选和标题映射已接入 Clipboard
- i18n 文案新增：`lib/utils/translation.dart`

### Step 3：Windows 监听链路打通（原生事件 -> Dart -> 入库）
- 目标：实现自动监听剪贴板文本的端到端闭环。
- 工作项：
  - 原生层接入 `AddClipboardFormatListener` 与 `WM_CLIPBOARDUPDATE`。
  - 仅提取文本内容，通过 MethodChannel 上报 `onClipboardTextChanged`。
  - Dart 侧接收事件并入库（先不做复杂优化）。
- 产出：
  - 复制文本后可自动新增本地历史记录。
- 验收：
  - 开启监听时可自动入库；暂停监听时不入库；异常不崩溃。

### Step 4：体验优化与质量加固
- 目标：降低噪音、提升状态可感知性与稳定性。
- 工作项：
  - 去重策略：相邻去重 + 30 秒窗口去重（入库前执行）。
  - 托盘状态增强：显示“监听中/已暂停/最近采集时间”。
  - 高频复制压测下的写入节流/轻量队列（必要时）。
- 产出：
  - 去重生效、托盘状态更清楚、频繁复制不卡顿。
- 验收：
  - 重复复制不产生无效噪音数据，状态文案与实际行为一致。

### Step 5：本地“确认后上云”链路
- 目标：实现“非自动双写”的手动确认同步。
- 工作项：
  - 历史页支持选中后触发同步（单条/批量）。
  - 同步成功后更新本地状态（`localOnly=false` 或等价状态）。
  - 失败反馈与可重试入口（先轻量，复杂重试策略后置）。
- 产出：
  - 用户可手动确认并完成云端同步。
- 验收：
  - 成功/失败状态可见，成功后本地状态一致更新。

### 里程碑建议
- M1：Step 1 完成（数据层就绪）
- M2：Step 2-3 完成（监听到展示闭环）
- M3：Step 4 完成（体验可用）
- M4：Step 5 完成（确认上云闭环）

### 补充 DoD（在原 DoD 基础上新增）
- 历史 Tab 可稳定展示本地剪贴板文本记录。
- `onClipboardTextChanged` 到本地入库链路可在 Windows 稳定运行。
- 去重策略在真实复制场景可验证生效。
- 手动确认同步后，本地状态与云端结果一致。
