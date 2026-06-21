# xbb 对话功能迁移文档（按当前实现重整）

> 本文档以当前代码实现为准，记录已完成能力、固定策略、遗留风险与下一迭代计划。

## 1. 当前已完成能力

### 1.1 架构与接入

- 已按 xbb 既有目录深度融合，不新增独立 feature 根目录：
  - `lib/models/chat`
  - `lib/controller/chat.dart`
  - `lib/client/chat/*`
  - `lib/components/chat/*`
  - `lib/pages/chat/chat_page.dart`
- 已接入 Home Tab 与 feature 开关（`enableChat`），支持首页展示/隐藏 chat tab。

### 1.2 数据与状态机

- Chat 数据模型与生成仓储/控制器已可用（assistant/conversation/message）。
- `ChatController` 编排层已实现：
  - 本地优先写入（会话/消息）
  - 流式生命周期：`streaming/completed/error/cancelled`
  - 最后一轮重试/改写约束
  - 会话级手动同步（水位推进、失败续传）
  - 远端优先删除，失败回退本地保留+失败标记

### 1.3 LLM 调用链与配置

- 本地 workspace 包 `packages/deepseek_client` 已落地并替换旧外部依赖。
- Chat 调用链已支持全局配置 + assistant 覆盖配置合并：
  - assistant 可覆盖：`provider/baseUrl/model/temperature/thinkingEnabled/reasoningEffort`
  - 全局独占：`apiKey`
- DeepSeek 流式请求已接入 `thinking` 与 `reasoning_effort` 字段透传。

### 1.4 UI 与国际化

- Chat 基础 UI 闭环已完成（会话列表、消息区、输入区）。
- Assistant 管理能力已落地：
  - 新建会话可选择 assistant
  - 支持 assistant 新建/编辑
  - 支持 assistant 级模型覆盖字段编辑
- 设置页已加入 Chat LLM 设置卡片：
  - provider/baseUrl/apiKey/model/temperature
  - DeepSeek `/models` 拉取与模型选择
  - 保存与重置默认
- Chat 相关文案已接入 `translation.dart`（含状态、错误、空态、assistant 管理、模型设置）。
- 推理文本已支持折叠/展开展示（reasoning panel）。

---

## 2. 已锁定产品策略

- 保持深度融合路线，不引入平行目录体系。
- `ChatConversation`/`ChatMessage`：本地优先 + 会话级手动同步。
- `ChatAssistant`：走生成 controller 的实时同步路径。
- 本地会话 ID 稳定不改写，远端映射使用 `remoteConversationId`。
- 同步候选仅限 `completed` 消息。
- 只允许操作最后一轮 user turn；已同步前缀不可变。
- MVP 并发：全局单流；切会话即取消当前流。
- 删除策略：远端优先，远端失败则本地保留并标记失败。
- 安全约束：`apiKey` 仅全局设置，不支持 assistant 覆盖。

---

## 3. 当前风险与待优化项

- 同步结果反馈仍偏粗粒度（尤其部分失败场景的可读性）。
- 设置页 Chat 配置当前为显式保存，尚未做自动保存/脏状态提示。
- 推理内容展示已可折叠，但 markdown 体验仍可继续优化。
- 背景流继续（切换会话不中断）仍是二期能力，当前未实现。

---

## 4. 下一迭代范围（Step 5）

1. **Sync UX 强化**
   - 增加会话级同步结果 toast 模板（成功/部分成功/失败）
   - 更清晰展示失败项与建议重试动作

2. **Chat 设置页增强**
   - 增加“测试配置”按钮（最小请求连通性校验）
   - 细化字段校验与错误提示（baseUrl/model/temperature/apiKey）

3. **渲染体验优化**
   - assistant 消息支持更稳定的 markdown 渲染策略
   - reasoning 区域增加默认折叠策略与可读性优化

4. **Assistant 管理完善**
   - 评估独立 assistant 管理页（列表、编辑入口、默认项策略）
   - 与会话关联关系的删除/变更边界行为补充说明

---

## 5. 验证基线

- `flutter pub get` 成功。
- `dart analyze` 对 chat/client/controller/components/translation/model 路径通过。
- 最小回归链路：
  - 新建会话（含 assistant 选择）
  - 发送并流式返回
  - 重试最后一轮失败/取消回复
  - 手动同步（首次 + 增量 + 失败后续传）
  - 远端优先删除
  - 设置页模型拉取与模型选择

---

## 6. 暂不纳入范围

- yaaa 旧本地数据/旧设置兼容迁移
- DeepSeek 以外 provider 的生产级运行链路
- 分叉/多分支会话历史模型
- 切会话后后台继续流式生成
