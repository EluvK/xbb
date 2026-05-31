import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:uuid/uuid.dart';
import 'package:xbb/controller/chat.dart';
import 'package:xbb/controller/setting.dart';
import 'package:xbb/models/chat/model.dart';

class ChatSessionList extends StatefulWidget {
  const ChatSessionList({super.key});

  @override
  State<ChatSessionList> createState() => _ChatSessionListState();
}

class _ChatSessionListState extends State<ChatSessionList> {
  ChatController? _controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<ChatController>()) {
      _controller = Get.find<ChatController>();
    }
  }

  Future<void> _ensureController() async {
    if (_controller != null) return;
    if (!Get.isRegistered<ChatController>()) {
      await reInitChatController();
    }
    _controller = Get.find<ChatController>();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _createConversation() async {
    await _ensureController();
    final controller = _controller;
    if (controller == null) return;
    final assistants = await ChatAssistantRepository().listFromLocalDb();
    ChatAssistantDataItem assistant;
    if (assistants.isEmpty) {
      final owner = Get.find<SettingController>().userId;
      final now = DateTime.now().toUtc();
      assistant = DataItem<ChatAssistant>(
        const Uuid().v4(),
        now,
        now,
        owner,
        null,
        null,
        body: const ChatAssistant(
          name: 'Default Assistant',
          type: ChatAssistantType.system,
          description: 'Default assistant for chat',
          prompt: 'You are a helpful assistant.',
        ),
      );
      await ChatAssistantRepository().addToLocalDb(assistant);
    } else {
      assistant = assistants.first;
    }

    final timeText = DateTime.now().toLocal().toIso8601String().substring(11, 19);
    final title = 'chat_new_conversation_title'.trParams({'time': timeText});
    await controller.createConversation(name: title, assistant: assistant);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ensureController(),
      builder: (context, snapshot) {
        final controller = _controller;
        if (controller == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Obx(() {
          final items = controller.conversationViewModels;
          return Column(
            children: [
              ListTile(
                dense: true,
                title: Text('home_bar_title_chat'.tr),
                trailing: IconButton(
                  onPressed: _createConversation,
                  icon: const Icon(Icons.add_comment_outlined),
                  tooltip: 'chat_new_conversation'.tr,
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text('chat_no_conversations'.tr))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final vm = items[index];
                          final selected = controller.currentConversationId.value == vm.item.id;
                          return ListTile(
                            selected: selected,
                            dense: true,
                            title: Text(vm.item.body.name),
                            subtitle: Text(_syncStateLabel(vm.syncState, vm.pendingSyncCount)),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'sync') {
                                  await controller.manualSyncConversation(vm.item.id);
                                  return;
                                }
                                if (value == 'delete') {
                                  await controller.deleteConversationWithRemote(vm.item.id);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'sync', child: Text('chat_sync_conversation'.tr)),
                                PopupMenuItem(value: 'delete', child: Text('delete'.tr)),
                              ],
                            ),
                            onTap: () async {
                              await controller.selectConversation(vm.item.id);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        });
      },
    );
  }

  String _syncStateLabel(ChatConversationSyncState state, int pending) {
    switch (state) {
      case ChatConversationSyncState.localOnly:
        return 'chat_sync_state_local_only'.tr;
      case ChatConversationSyncState.dirty:
        return 'chat_sync_state_dirty'.trParams({'count': '$pending'});
      case ChatConversationSyncState.synced:
        return 'chat_sync_state_synced'.tr;
      case ChatConversationSyncState.syncError:
        return 'chat_sync_state_failed'.tr;
    }
  }
}
