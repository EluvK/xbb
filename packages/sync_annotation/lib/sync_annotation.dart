library sync_annotation;

class Repository {
  final String collectionName;
  final String tableName;
  final Type db;
  final bool withAcls;

  const Repository({required this.collectionName, required this.tableName, required this.db, this.withAcls = false});
}
