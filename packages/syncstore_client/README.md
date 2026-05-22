# syncstore_client (Dart) - Minimal handwritten client (Scheme B)

目标
- 手工实现一个轻量通用的 Dart 客户端库，使用泛型 T 表示业务 data body。
- 自动处理认证（登录、refresh），过期 token 会自动 refresh 并重试原请求；仅在 refresh 最终失败时向上抛出错误。

快速开始
1. 在 pubspec.yaml 中加入依赖：
```yaml
dependencies:
  dio: ^5.0.0
```

2. 使用示例（伪代码，参见 example/main.dart）：
```dart
final storage = InMemoryTokenStorage();
final client = SyncStoreClient(baseUrl: 'http://localhost:7878/api', tokenStorage: storage);

// 登录（会保存 tokens）
await client.login('alice', 'password');

// list repo，T 为 Map<String, dynamic>（简单示例）
final res = await client.list<Map<String, dynamic>>(
  'xbb',
  'repo',
  fromMap: (m) => m,
  limit: 20,
);

// create repo
final created = await client.create<Map<String, dynamic>>(
  'xbb',
  'repo',
  {'name': 'demo', 'status': 'normal'},
  (m) => m,
);
```

扩展点与注意
- TokenStorage 有多种实现：InMemoryTokenStorage（示例）、文件或 Flutter secure storage（生产环境建议）。
- AuthInterceptor 使用单个 Refresh 流程来避免并发多次刷新。
- DataItem / ListResponse 提供从 Map -> T 的转换 hook，业务方可以使用 json_serializable 或 freezed 生成类型化模型。
- 如果服务提供 OpenAPI，推荐在后续迭代里结合 openapi-generator 自动生成 model，再将这些模型与本库的 auth/transport 层整合。

错误处理
- ApiException 为基础错误，细化为 AuthException、ValidationException、NetworkException，方便业务方区分并处理。

后续建议
- 添加可选的本地缓存（Hive/SQLite）用于离线场景。
- 支持 refresh token 存储与管理策略（例如 rotating refresh tokens）。
- 在 CI 中加入集成测试，启动一个临时的 syncstore 服务并进行端到端测试。

