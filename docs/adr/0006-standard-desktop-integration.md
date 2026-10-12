# 0006: 桌面系统集成全面采用成熟生态库替代手写原生 C++

## 决策背景与结论
桌面端系统托盘、无边框沉浸式窗口顶栏与关闭拦截至托盘能力，决定全面采用 Flutter 官方高成熟度生态库 `tray_manager` 与 `window_manager`，彻底废弃 Windows Runner 下手写的 C++ 代码。核心原因在于手写 C++ 代码维护成本高，极易发生 MethodChannel 接口方法名与参数失配，且无法跨平台赋能 macOS 与 Linux；引入生态标准库一步到位实现跨端一致的桌面体验。

## 被否决的备选方案 (Rejected Alternatives)
- **在各平台 Runner 中分别手写原生代码 (Windows C++, macOS Swift)**: 跨平台维护成本极高，容易因各端生命周期和 MethodChannel 签名差异产生难以排查的平台特有 Bug。
