import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:sync_annotation/sync_annotation.dart';

part 'main.g.dart';

Future<void> debug() async {
  // print('Debugging...');
  // final controller = Get.find<RepoController>();
  // var currentRepos = controller.onViewRepos(null);
  // print('Current repos count: ${currentRepos.length}');
  // print('Debugging done.');
}
void test_hpke() async {
  final aad = Uint8List.fromList("/api/data/xbb/repo".codeUnits);
  final message = Uint8List.fromList("null".codeUnits);
  print("message: $message");

  // final keyPair = await X25519Kem().fixKeyPair();
  final keyPair = await X25519Kem().newKeyPair();
  final extractedPub = await keyPair.extractPublicKey();
  print("Generated Public Key: ${base64Encode(extractedPub.bytes)}");
  final extractedPriv = await keyPair.extractPrivateKeyBytes();
  print("Generated Private Key: ${base64Encode(extractedPriv)}");

  final r = await HpkeBase().seal(plaintext: message, recipientPub: extractedPub, aad: aad);
  print("Sealed ciphertext: ${base64Encode(r.$2)}");
  print("Ephemeral Public Key: ${base64Encode(r.$1)}");

  final opened = await HpkeBase().open(
    enc: r.$1,
    ciphertext: r.$2,
    recipientKeyPair: keyPair,
    recipientPub: extractedPub,
    aad: aad,
  );
  print("Opened plaintext: ${utf8.decode(opened)}");
}

void main() async {
  final storage = InMemoryTokenStorage();
  final client = SyncStoreClient(baseUrl: 'http://localhost:1011/api', tokenStorage: storage, enableHpke: false);
  try {
    await client.login('test', 'password');
    print('Login successful');
  } catch (e) {
    print('Login failed: $e');
    return;
  }

  await Get.putAsync(() async {
    final controller = RepoController(client);
    return controller;
  });

  final controller = Get.find<RepoController>();
  await controller.ensureInitialization();

  print("0. Syncing all repos from server...");
  await controller.syncOwned();
  await controller.rebuildLocal();

  // try update one of the local repos (if any)
  final viewRepos = controller.getRepoDetails(selector: (c) => c);
  if (viewRepos.length > 2) {
    String secondRepoId = viewRepos[1].id;
    print('1. Updated local repo: ${secondRepoId}');
    final Repo updatedData = Repo(
      name: viewRepos.last.body.name,
      status: viewRepos.last.body.status,
      description: 'Updated locally at ${DateTime.now().toIso8601String()}',
    );
    controller.updateData(secondRepoId, updatedData);
    // await Future.delayed(Duration(seconds: 2)); // wait for background sync to finish
  }

  await debug();
  print('2. Created new repo');
  Repo newRepo = Repo(name: 'some-repo', status: 'normal', description: 'Created from client example');
  controller.addData(newRepo);
  // await Future.delayed(Duration(seconds: 2)); // wait for background sync to finish

  await debug();
  // try delete a repo at local and server
  if (viewRepos.isNotEmpty) {
    final toDelete = viewRepos.first;
    print('3. Deleted repo: ${toDelete.id}');
    controller.deleteData(toDelete.id);
    // await Future.delayed(Duration(seconds: 2)); // wait for background sync to finish
  }
  await debug();

  return;
}

@Repository(collectionName: 'xbb', tableName: 'repo', db: TestDataBase)
@JsonSerializable(includeIfNull: false)
class Repo {
  String name;
  String status;
  String? description;

  Repo({required this.name, required this.status, this.description});

  factory Repo.fromJson(Map<String, dynamic> json) => _$RepoFromJson(json);
  Map<String, dynamic> toJson() => _$RepoToJson(this);
}

// class _RepoSyncEngine {
//   final SyncStoreClient client;
//   _RepoSyncEngine(this.client);

//   Future<RepoDataItem> create(RepoDataItem local) async {
//     local.syncStatus = SyncStatus.syncing;
//     await RepoRepository().addToLocalDb(local);

//     final newId = await client.create('xbb', 'repo', local.body.toJson());
//     final RepoDataItem createdItem = await client.get<Repo>('xbb', 'repo', newId, Repo.fromJson);
//     createdItem.syncStatus = SyncStatus.archived;

//     await RepoRepository().deleteFromLocalDb(local.id);
//     await RepoRepository().addToLocalDb(createdItem);
//     return createdItem;
//   }

//   Future<RepoDataItem> update(RepoDataItem local) async {
//     local.syncStatus = SyncStatus.syncing;
//     await RepoRepository().updateToLocalDb(local);
//     await client.update('xbb', 'repo', local.id, local.body.toJson());
//     final RepoDataItem updatedItem = await client.get<Repo>('xbb', 'repo', local.id, Repo.fromJson);
//     updatedItem.syncStatus = SyncStatus.archived;
//     await RepoRepository().updateToLocalDb(updatedItem);
//     return updatedItem;
//   }

//   void delete(String id) {
//     RepoRepository().deleteFromLocalDb(id);
//     try {
//       client.delete('xbb', 'repo', id);
//     } catch (e) {
//       rethrow;
//     }
//   }

//   Future<void> syncAll() async {
//     try {
//       var nextMarker = null;
//       final serviceIds = <String>{};
//       do {
//         final ListResponse resp = await client.list('xbb', 'repo', limit: 50, marker: nextMarker);
//         nextMarker = resp.pageInfo.nextMarker;
//         for (var summary in resp.items) {
//           serviceIds.add(summary.id);
//           final RepoDataItem? localItem = await RepoRepository().getFromLocalDb(summary.id);
//           if (localItem == null) {
//             // new from server
//             final RepoDataItem item = await client.get<Repo>('xbb', 'repo', summary.id, Repo.fromJson);
//             await RepoRepository().addToLocalDb(item);
//           } else if (localItem.updatedAt.isBefore(summary.updatedAt)) {
//             // update local data.
//             final RepoDataItem item = await client.get<Repo>('xbb', 'repo', summary.id, Repo.fromJson);
//             await RepoRepository().updateToLocalDb(item);
//           } else if (localItem.updatedAt.isAfter(summary.updatedAt)) {
//             // local data is newer, need to sync to server
//             localItem.syncStatus = SyncStatus.failed;
//             await RepoRepository().updateToLocalDb(localItem);
//           }
//         }
//       } while (nextMarker != null);
//       // clean up local data that are deleted from server
//       final localItems = await RepoRepository().listFromLocalDb();
//       for (RepoDataItem localItem in localItems) {
//         if (!serviceIds.contains(localItem.id)) {
//           localItem.syncStatus = SyncStatus.deleted;
//           await RepoRepository().updateToLocalDb(localItem);
//         }
//       }
//     } catch (e) {
//       // todo more error handling?
//       rethrow;
//     }
//   }
// }

// class RepoController extends GetxController {
//   final SyncStoreClient client;
//   final _RepoSyncEngine _syncEngine;
//   RepoController(this.client) : _syncEngine = _RepoSyncEngine(client);

//   final RxList<RepoDataItem> _items = <RepoDataItem>[].obs;
//   final Rx<String?> currentRepoId = Rx<String?>(null);

//   @override
//   Future<void> onInit() async {
//     await rebuildLocal();
//     super.onInit();
//     _initialized = true;
//   }

//   bool _initialized = false;
//   Future<void> ensureInitialization() async {
//     while (!_initialized) {
//       await onInit();
//     }
//     return;
//   }

//   Future<void> rebuildLocal() async {
//     _items.value = await RepoRepository().listFromLocalDb();
//   }

//   void onSelectRepo(String id) {
//     currentRepoId.value = id;
//   }

//   List<RepoDataItem> onViewRepos(String? parent_id) {
//     if (parent_id == null) {
//       return _items;
//     }
//     return _items.where((item) => item.parentId == parent_id).toList();
//   }

//   Future<void> trySyncAll() async => await _syncEngine.syncAll();
//   void _replaceLocal(String id, RepoDataItem fetchedItem) {
//     final index = _items.indexWhere((item) => item.id == id);
//     if (index != -1) {
//       _items[index] = fetchedItem;
//     }
//     // print('Replaced local repo with id: $id, new id: ${fetchedItem.id}');
//     if (currentRepoId.value == id && fetchedItem.id != id) {
//       // update current selected id if changed by server generated id
//       currentRepoId.value = fetchedItem.id;
//     }
//   }

//   void addData(Repo newData) {
//     // generate a local uuid before successfully created on server
//     final owner = client.currentUserId();
//     final newItem = RepoDataItem.localNew(owner, newData);
//     // it's a temporary memory data, not even in local db yet.
//     _items.add(newItem);
//     _syncEngine.create(newItem).then((fetchedItem) {
//       _replaceLocal(newItem.id, fetchedItem);
//     });
//   }

//   void updateData(String id, Repo updatedData) {
//     final item = _items.firstWhere((item) => item.id == id);
//     // todo maybe rewrite this update body method...
//     final updatedItem = item.updatedBody(updatedData);
//     _items[_items.indexOf(item)] = updatedItem;
//     _syncEngine.update(updatedItem).then((fetchedItem) {
//       _replaceLocal(updatedItem.id, fetchedItem);
//     });
//   }

//   void deleteData(String id) {
//     _items.removeWhere((item) => item.id == id);
//     _syncEngine.delete(id);
//   }
// }

class TestDataBase {
  static Database? _db;

  Future<Database> getDb() async {
    if (_db != null) return _db!;
    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'example_c.db');

    _db ??= await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute(LocalStoreRepo.onCreateTableRepoSQL);
        },
      ),
    );
    return _db!;
  }
}
