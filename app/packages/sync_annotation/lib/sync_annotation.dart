library sync_annotation;

class Repository {
  final String collectionName;
  final String tableName;
  final Type db;
  final bool withAcls;
  final String? parentIdField;
  final String? toSyncJsonMethod;
  final String? fromRemoteJsonFactory;

  const Repository({
    required this.collectionName,
    required this.tableName,
    required this.db,
    this.withAcls = false,
    this.parentIdField,
    this.toSyncJsonMethod,
    this.fromRemoteJsonFactory,
  });
}
