import 'package:sqflite/sqflite.dart';
import 'package:xbb/model/repo.dart';

/// Repo
const String tableRepoName = "repo";
const String tableRepoColumnId = "id";
const String tableRepoColumnName = "name";
const String tableRepoColumnOwner = "owner";
const String tableRepoColumnDescription = "description";
const String tableRepoColumnCreatedAt = "createdAt";
const String tableRepoColumnUpdatedAt = "updatedAt";
// local
const String tableRepoColumnLastSyncAt = "lastSyncAt";
const String tableRepoColumnRemoteRepo = 'remoteRepo';
const String tableRepoColumnAutoSync = 'autoSync';
const String tableRepoColumnSharedTo = 'sharedTo';
const String tableRepoColumnSharedLink = 'sharedLink';
const String tableRepoColumnUnreadCount = 'unreadCount';

/// POST
const String tablePostName = 'posts';
const String tablePostColumnId = 'id';
const String tablePostColumnCategory = 'category';
const String tablePostColumnTitle = 'title';
const String tablePostColumnContent = 'content';
const String tablePostColumnCreatedAt = 'createdAt';
const String tablePostColumnUpdatedAt = 'updatedAt';
const String tablePostColumnAuthor = 'author';
const String tablePostColumnRepoId = 'repoId';
// local
const String tablePostColumnStatus = 'status';
const String tablePostColumnSelfAttitude = 'selfAttitude';
const String tablePostColumnCommentStatus = 'commentStatus';

/// COMMENT
const String tableCommentName = 'comments';
const String tableCommentColumnId = 'id';
const String tableCommentColumnRepoId = 'repoId';
const String tableCommentColumnPostId = 'postId';
const String tableCommentColumnContent = 'content';
const String tableCommentColumnCreatedAt = 'createdAt';
const String tableCommentColumnUpdatedAt = 'updatedAt';
const String tableCommentColumnAuthor = 'author';
const String tableCommentColumnParentId = 'parentId';

class DataBase {
  static Database? _db;

  Future<Database> getDb() async {
    _db ??= await openDatabase(
      'xbb_client.db',
      version: 2,
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        /// add table comments
        if (oldVersion < 2 && newVersion >= 2) {
          await db.execute('''CREATE TABLE $tableCommentName(
            $tableCommentColumnId TEXT PRIMARY KEY,
            $tableCommentColumnRepoId TEXT NOT NULL,
            $tableCommentColumnPostId TEXT NOT NULL,
            $tableCommentColumnContent TEXT NOT NULL,
            $tableCommentColumnCreatedAt TEXT NOT NULL,
            $tableCommentColumnUpdatedAt TEXT NOT NULL,
            $tableCommentColumnAuthor TEXT NOT NULL,
            $tableCommentColumnParentId TEXT
          )''');

          /// add post comment status
          // 1. 将旧表重命名为临时表
          await db.execute('ALTER TABLE $tablePostName RENAME TO _post_v1');

          // 2. 创建新表，包含新的列 comment_status
          await db.execute('''
            CREATE TABLE $tablePostName (
              $tablePostColumnId TEXT PRIMARY KEY,
              $tablePostColumnCategory TEXT NOT NULL,
              $tablePostColumnTitle TEXT NOT NULL,
              $tablePostColumnContent TEXT NOT NULL,
              $tablePostColumnCreatedAt TEXT NOT NULL,
              $tablePostColumnUpdatedAt TEXT NOT NULL,
              $tablePostColumnAuthor TEXT NOT NULL,
              $tablePostColumnRepoId TEXT NOT NULL,
              $tablePostColumnStatus TEXT NOT NULL,
              $tablePostColumnSelfAttitude TEXT NOT NULL,
              $tablePostColumnCommentStatus TEXT NOT NULL
            )
          ''');

          // 3. 将旧表的数据复制到新表
          await db.execute('''
            INSERT INTO $tablePostName (
              $tablePostColumnId,
              $tablePostColumnCategory,
              $tablePostColumnTitle,
              $tablePostColumnContent,
              $tablePostColumnCreatedAt,
              $tablePostColumnUpdatedAt,
              $tablePostColumnAuthor,
              $tablePostColumnRepoId,
              $tablePostColumnStatus,
              $tablePostColumnSelfAttitude,
              $tablePostColumnCommentStatus
            )
            SELECT
              $tablePostColumnId,
              $tablePostColumnCategory,
              $tablePostColumnTitle,
              $tablePostColumnContent,
              $tablePostColumnCreatedAt,
              $tablePostColumnUpdatedAt,
              $tablePostColumnAuthor,
              $tablePostColumnRepoId,
              $tablePostColumnStatus,
              $tablePostColumnSelfAttitude,
              'PostCommentStatus.normal'
            FROM _post_v1
          ''');

          // 4. 删除旧表
          await db.execute('DROP TABLE _post_v1');
        }
      },
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $tablePostName (
            $tablePostColumnId TEXT PRIMARY KEY,
            $tablePostColumnCategory TEXT NOT NULL,
            $tablePostColumnTitle TEXT NOT NULL,
            $tablePostColumnContent TEXT NOT NULL,
            $tablePostColumnCreatedAt TEXT NOT NULL,
            $tablePostColumnUpdatedAt TEXT NOT NULL,
            $tablePostColumnAuthor TEXT NOT NULL,
            $tablePostColumnRepoId TEXT NOT NULL,
            $tablePostColumnStatus TEXT NOT NULL,
            $tablePostColumnSelfAttitude TEXT NOT NULL,
            $tablePostColumnCommentStatus TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableRepoName(
            $tableRepoColumnId TEXT PRIMARY KEY,
            $tableRepoColumnName TEXT NOT NULL,
            $tableRepoColumnOwner TEXT NOT NULL,
            $tableRepoColumnDescription TEXT NOT NULL,
            $tableRepoColumnCreatedAt TEXT NOT NULL,
            $tableRepoColumnUpdatedAt TEXT NOT NULL,
            $tableRepoColumnLastSyncAt TEXT NOT NULL,
            $tableRepoColumnRemoteRepo INTEGER NOT NULL,
            $tableRepoColumnAutoSync INTEGER NOT NULL,
            $tableRepoColumnSharedTo TEXT,
            $tableRepoColumnSharedLink TEXT,
            $tableRepoColumnUnreadCount INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableCommentName(
            $tableCommentColumnId TEXT PRIMARY KEY,
            $tableCommentColumnRepoId TEXT NOT NULL,
            $tableCommentColumnPostId TEXT NOT NULL,
            $tableCommentColumnContent TEXT NOT NULL,
            $tableCommentColumnCreatedAt TEXT NOT NULL,
            $tableCommentColumnUpdatedAt TEXT NOT NULL,
            $tableCommentColumnAuthor TEXT NOT NULL,
            $tableCommentColumnParentId TEXT
          )
        ''');
        var now = DateTime.now().toUtc();
        var localRepo = Repo(
          id: '0',
          name: 'local',
          owner: 'local',
          description: 'local repo',
          createdAt: now,
          updatedAt: now,
          lastSyncAt: DateTime.parse(neverSyncAt),
          remoteRepo: false,
          autoSync: false,
          unreadCount: 0,
        );
        await db.insert(tableRepoName, localRepo.toMap());
      },
    );

    return _db!;
  }
}
