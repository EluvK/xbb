import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/data/database_providers.dart';
import 'package:xbb/data/repositories/chat_repository.dart';
import 'package:xbb/models/chat/model.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final notifier = ref.watch(dbChangeNotifierProvider);
  return ChatRepository(db: db, changeNotifier: notifier);
});

final chatAssistantsStreamProvider = StreamProvider<List<DataItem<ChatAssistant>>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchAssistants();
});

final chatConversationsStreamProvider = StreamProvider<List<DataItem<ChatConversation>>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.watchConversations();
});

final selectedConversationIdProvider = StateProvider<String?>((ref) => null);

final chatMessagesStreamProvider = StreamProvider<List<DataItem<ChatMessage>>>((ref) {
  final repo = ref.watch(chatRepositoryProvider);
  final convId = ref.watch(selectedConversationIdProvider);
  return repo.watchMessages(convId);
});
