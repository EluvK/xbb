# Notes 功能说明

## 1) 覆盖场景
- 个人知识库：按仓库（Repo）组织主题，按分类聚合文章，支持快速检索与阅读。
- 团队协作：可见共享仓库与他人内容，按权限决定可读/可改/可删。
- 长文讨论：围绕文章进行评论与回复，适合需求讨论、复盘记录、知识沉淀。
- 多端同步：本地缓存优先，显式触发同步，适合离线查看与间歇联网。

## 2) 使用方式示例
- 新建并维护仓库
  - 在 Home 的 Notes 左侧仓库区新增仓库。
  - 选择仓库后进入该仓库的文章流，后续新增文章会自动挂到当前仓库。
- 文章协作流
  - 进入文章列表 -> 新建/编辑文章 -> 打开文章详情进行评论或回复。
  - 当需要拉取远端更新时，手动触发刷新；刷新会按仓库、文章、评论分阶段同步。
- 日常检索流
  - 在文章区通过关键字过滤标题/正文/分类。
  - 在仓库切换器里快速切到最近常用仓库继续编辑。

## 3) 模块代码位置
- 领域模型（核心入口）
  - [lib/models/notes/model.dart](../../../lib/models/notes/model.dart)
- 本地库与缓存
  - [lib/models/notes/db.dart](../../../lib/models/notes/db.dart)
- 主页入口（Tab 与左右区映射）
  - [lib/pages/home.dart](../../../lib/pages/home.dart)
- 路由入口（查看/编辑页面）
  - [lib/main.dart](../../../lib/main.dart)
  - [lib/pages/notes/view_post.dart](../../../lib/pages/notes/view_post.dart)
  - [lib/pages/notes/editor_pages.dart](../../../lib/pages/notes/editor_pages.dart)
- 主要 UI 组件
  - 仓库列表与快速切换：[lib/components/notes/view_repos.dart](../../../lib/components/notes/view_repos.dart)
  - 文章列表与下拉刷新：[lib/components/notes/view_posts.dart](../../../lib/components/notes/view_posts.dart)
- 同步重置边界（应用重登/重连时）
  - [lib/controller/syncstore.dart](../../../lib/controller/syncstore.dart)

## 4) 迭代时优先关注
- 数据结构变更入口唯一化
  - 只在 [lib/models/notes/model.dart](../../../lib/models/notes/model.dart) 改 schema；不要手改 `model.g.dart` / `model.freezed.dart`。
- 权限策略一致性
  - Notes 的能力检查依赖 `NotesFeatureRequires` 与用户权限校验链路；新增操作前先定义权限语义再接 UI。
- 同步体验
  - Notes 是显式同步模型（初始化同步 + 手动刷新）；新增列表/详情视图时要明确“何时刷新本地、何时拉远端”。
- 多账号隔离
  - 本地库按用户隔离（`notes.db` 在 userId 目录下）；涉及账号切换的功能要验证缓存切换行为。

## 5) 文档维护建议
- 新增用户可见能力时，同步补充“覆盖场景”和“使用方式示例”。
- 新增入口页面或迁移文件时，只维护“模块代码位置”列表，不复制实现细节。
