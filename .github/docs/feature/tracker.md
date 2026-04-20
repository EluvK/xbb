# Tracker 功能说明

## 1) 覆盖场景
- 周期习惯追踪（event）：如每 N 天完成一次运动/整理。
- 阶段目标管理（milestone）：围绕累计值或最新值评估进度。
- 纪念日管理（anniversary）：基于基准日期的提醒与记录。
- 个人与协作并存：支持 ACL，适配“自己维护 + 指定成员共管”的轻协作场景。

## 2) 使用方式示例
- 新建一个周期追踪
  - 在 Tracker 主视图点击新增，选择 event 类型并设置周期。
  - 在详情页按时间补充记录，用于形成连续轨迹。
- 管理一个阶段性目标
  - 新建 milestone，选择时间/数值目标与进度模式。
  - 持续补记录后，在卡片和详情中查看当前进展与历史。
- 维护纪念日
  - 新建 anniversary，设置基准日期与提醒规则。
  - 在详情页以文本记录节点内容，必要时回看时间线。

## 3) 模块代码位置
- 领域模型（核心入口）
  - [lib/models/tracker/model.dart](../../../lib/models/tracker/model.dart)
- 本地库与缓存
  - [lib/models/tracker/db.dart](../../../lib/models/tracker/db.dart)
- 主页入口（Tab 与左右区映射）
  - [lib/pages/home.dart](../../../lib/pages/home.dart)
- 路由入口（编辑/详情页面）
  - [lib/main.dart](../../../lib/main.dart)
  - [lib/pages/trackers/edit_tracker.dart](../../../lib/pages/trackers/edit_tracker.dart)
  - [lib/pages/trackers/view_tracker.dart](../../../lib/pages/trackers/view_tracker.dart)
- 主要 UI 组件
  - 概览侧栏：[lib/components/trackers/view_brief.dart](../../../lib/components/trackers/view_brief.dart)
  - 主矩阵视图：[lib/components/trackers/view_tracker.dart](../../../lib/components/trackers/view_tracker.dart)
  - 编辑器：[lib/components/trackers/tracker_editor.dart](../../../lib/components/trackers/tracker_editor.dart)
  - 卡片呈现：[lib/components/trackers/tracker_card.dart](../../../lib/components/trackers/tracker_card.dart)
- 同步重置边界（应用重登/重连时）
  - [lib/controller/syncstore.dart](../../../lib/controller/syncstore.dart)

## 4) 迭代时优先关注
- 类型扩展策略
  - 新增 tracker 类型时，先扩展 [lib/models/tracker/model.dart](../../../lib/models/tracker/model.dart) 的配置联合类型，再补编辑器、详情录入与卡片展示。
- 记录写入一致性
  - 不同类型的输入校验与记录构造要保持语义一致（特别是 time/number/boolean 的值编码）。
- 权限与共享
  - 编辑与记录能力受 `TrackerFeatureRequires` + ACL 约束；新增批量操作时先确认权限边界。
- 同步与重建
  - Tracker 初始化会同步 tracker 与 record 并重建本地映射；新增聚合视图时应明确 rebuild 触发点。
- 多账号隔离
  - 本地库按用户隔离（`tracker.db` 在 userId 目录下）；账号切换后要验证视图订阅是否正确刷新。

## 5) 文档维护建议
- 新增追踪类型或新增记录维度时，优先更新“覆盖场景”和“使用方式示例”。
- 目录或入口变更时，仅更新“模块代码位置”，避免复制实现细节。
