# Agent Guidelines

## Monorepo Architecture
本项目为 Monorepo 架构，包含以下核心模块：
- **`app/`**: 跨平台 Flutter 客户端应用及内部扩展包 (`app/packages/*`)。
- **`server/`**: 高性能 Rust 同步服务。

> **目录工作规范**：
> 在对应子目录（如 `app/` 或 `server/`）进行工作的时候，**必须首先读取并严格遵守该目录下的 `AGENTS.md` 文件**。子模块的具体代码结构、组件细节与专属规则均在各自目录的 `AGENTS.md` 中维护。

## Global Invariants & Rules (全局规则)
所有模块开发与维护工作均需严格遵守以下全局规则：
1. **禁止写注释**：严禁在代码中添加说明性注释或无意义注释。保持代码自解释，除非极其必要（若无注释完全无法理解代码逻辑）方可编写极简注释。
2. **禁止增加负面描述和历史变动描述**：文档、代码与上下文中严禁记录负面评价、废弃说明、重构对比或过去版本变迁历史；聚焦当前架构定义、核心定位与检索索引。

## 领域知识与架构决策 (Domain Knowledge)
- 业务概念定义、中英别名映射与模块物理代码入口，优先查阅 `GLOSSARY.md`。
- 涉及重要技术选型或架构调整前，先查阅 `docs/adr/README.md` 单行索引，严禁违背既定决策。
- 严格遵守 `GLOSSARY.md` 中的 `_Avoid_` 禁用词约定，防止概念混淆。

## Progressive Disclosure
- 领域词典与物理索引：首选 `GLOSSARY.md`。
- 系统整体架构与技术栈：阅读 `CONTEXT.md`。
- 架构决策记录：阅读 `docs/adr/README.md` 与对应 ADR。
- 子模块详细设计与 Schema：按需查阅 `docs/domain/<feature>.md` (`notes`, `task`, `tracker`, `checkin`, `clipboard`, `chat`, `syncstore_protocol`, `codegen_pipeline`)。
