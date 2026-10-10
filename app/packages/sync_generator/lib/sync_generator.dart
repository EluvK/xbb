import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:sync_annotation/sync_annotation.dart';

class RepositoryGenerator extends GeneratorForAnnotation<Repository> {
  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) return '';

    final className = element.name!;
    final tableName = annotation.read('tableName').stringValue;
    final dbType = annotation.read('db').typeValue.getDisplayString();

    final dataItemType = '${className}DataItem';
    final repositoryType = '${className}Repository';
    final extName = 'LocalStore$className';

    final buffer = StringBuffer();

    buffer.writeln(_generateExtension(className, extName, tableName, dbType));
    buffer.writeln('typedef $dataItemType = DataItem<$className>;\n');
    buffer.writeln(_generateRepository(className, repositoryType, dataItemType, extName));

    return buffer.toString();
  }

  String _generateExtension(String className, String extName, String tableName, String dbType) {
    return '''
extension $extName on $className {
  static String get tableName => '$tableName';

  static String get onCreateTable${className}SQL => 
      """
        CREATE TABLE \$tableName (
          id TEXT PRIMARY KEY,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          owner TEXT NOT NULL,
          parent_id TEXT,
          "unique" TEXT,
          sync_status TEXT NOT NULL,
          color_tag TEXT NOT NULL,
          body TEXT NOT NULL
        )
      """;

  static Future<Database> getDb() async {
    return await $dbType().getDb();
  }
}
''';
  }

  String _generateRepository(String className, String repositoryType, String dataItemType, String extName) {
    return '''
class $repositoryType {
  Future<void> addToLocalDb($dataItemType item) async {
    final db = await $extName.getDb();
    await db.insert(
      $extName.tableName, item.toJson((r) => json.encode(r.toJson())),
    );
  }

  Future<$dataItemType?> getFromLocalDb(String id) async {
    final db = await $extName.getDb();
    final List<Map<String, dynamic>> maps = await db.query($extName.tableName, where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return DataItem<$className>.fromJson(maps.first, (jsonStr) => $className.fromJson(json.decode(jsonStr as String)));
    }
    return null;
  }

  Future<List<$dataItemType>> listFromLocalDb({String? parentId}) async {
    final db = await $extName.getDb();
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];
    if (parentId != null) {
      whereClauses.add('parent_id = ?');
      whereArgs.add(parentId);
    }
    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      $extName.tableName,
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => DataItem<$className>.fromJson(
      map, (jsonStr) => $className.fromJson(json.decode(jsonStr as String))))
      .toList();
  }

  Future<List<$dataItemType>> listByParentIdFromLocalDb(String parentId, {bool desc = true}) async {
    final db = await $extName.getDb();
    final order = desc ? 'DESC' : 'ASC';
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM \${$extName.tableName} WHERE parent_id = ? ORDER BY created_at \$order',
      [parentId],
    );
    return maps.map((map) => DataItem<$className>.fromJson(
      map, (jsonStr) => $className.fromJson(json.decode(jsonStr as String))))
      .toList();
  }

  Future<void> deleteFromLocalDb(String id) async {
    final db = await $extName.getDb();
    await db.delete($extName.tableName, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateToLocalDb($dataItemType item) async {
    final db = await $extName.getDb();
    await db.update(
      $extName.tableName,
      item.toJson((r) => json.encode(r.toJson())),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> upsertToLocalDb($dataItemType item) async {
    if (await getFromLocalDb(item.id) == null) {
      await addToLocalDb(item);
    } else {
      await updateToLocalDb(item);
    }
  }
}
''';
  }
}

Builder syncModelBuilder(BuilderOptions options) =>
    SharedPartBuilder([RepositoryGenerator()], 'sync_model');

