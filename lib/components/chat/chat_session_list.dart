import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/controller/chat.dart';
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
    final assistant = await _openAssistantsDialog(forSelection: true);
    if (assistant == null) return;

    final timeText = DateTime.now().toLocal().toIso8601String().substring(11, 19);
    final title = 'chat_new_conversation_title'.trParams({'time': timeText});
    await controller.createConversation(name: title, assistant: assistant);
  }

  Future<List<ChatAssistantDataItem>> _loadAssistants() async {
    final assistants = await ChatAssistantRepository().listFromLocalDb();
    assistants.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return assistants;
  }

  Future<void> _duplicateAssistant(ChatAssistantDataItem assistant) async {
    await _ensureController();
    final controller = _controller;
    if (controller == null) return;

    final duplicated = assistant.body.copyWith(
      name: '${assistant.body.name} ${'chat_assistant_duplicate_suffix'.tr}',
      type: ChatAssistantType.userDefined,
    );
    await controller.upsertAssistant(null, duplicated);
    await controller.reloadConversations();
  }

  Future<void> _deleteAssistant(ChatAssistantDataItem assistant) async {
    if (assistant.body.type == ChatAssistantType.system) {
      return;
    }
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('chat_assistant_delete_title'.tr),
          content: Text('chat_assistant_delete_confirm'.trParams({'name': assistant.body.name})),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('cancel'.tr)),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text('delete'.tr)),
          ],
        );
      },
    );
    if (confirmed != true) return;

    final assistantController = Get.find<ChatAssistantController>();
    assistantController.deleteData(assistant.id);
    await _controller?.reloadConversations();
  }

  Widget _buildAssistantsMatrix({
    required List<ChatAssistantDataItem> assistants,
    required bool forSelection,
    required Future<void> Function() onRefresh,
    required BuildContext dialogContext,
  }) {
    if (assistants.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('chat_assistant_empty'.tr),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = MediaQuery.of(context).size.width < 800;
        final cardWidth = isCompact ? 180.0 : 280.0;
        final maxPerRow = (constraints.maxWidth / cardWidth).floor().clamp(1, 6);
        final spacing = (constraints.maxWidth - (maxPerRow * cardWidth)) / (maxPerRow + 1);

        return Wrap(
          spacing: spacing.isFinite && spacing > 8 ? spacing : 8,
          runSpacing: 12,
          children: assistants.map((assistant) {
            return SizedBox(
              width: cardWidth,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              assistant.body.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          if (assistant.body.type == ChatAssistantType.system)
                            Chip(
                              label: Text('chat_assistant_system'.tr),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        assistant.body.description.isEmpty
                            ? 'chat_assistant_no_description'.tr
                            : assistant.body.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (forSelection)
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(assistant),
                              child: Text('chat_assistant_use'.tr),
                            ),
                          IconButton(
                            onPressed: () async {
                              await _createOrEditAssistant(existing: assistant);
                              await onRefresh();
                            },
                            tooltip: 'chat_assistant_edit'.tr,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () async {
                              await _duplicateAssistant(assistant);
                              await onRefresh();
                            },
                            tooltip: 'chat_assistant_duplicate'.tr,
                            icon: const Icon(Icons.copy_outlined),
                          ),
                          IconButton(
                            onPressed: assistant.body.type == ChatAssistantType.system
                                ? null
                                : () async {
                                    await _deleteAssistant(assistant);
                                    await onRefresh();
                                  },
                            tooltip: 'chat_assistant_delete'.tr,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }

  Widget _buildAssistantSection({
    required String title,
    required List<ChatAssistantDataItem> assistants,
    required bool forSelection,
    required Future<void> Function() onRefresh,
    required BuildContext dialogContext,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildAssistantsMatrix(
          assistants: assistants,
          forSelection: forSelection,
          onRefresh: onRefresh,
          dialogContext: dialogContext,
        ),
      ],
    );
  }

  Future<ChatAssistantDataItem?> _openAssistantsDialog({required bool forSelection}) async {
    if (!mounted) return null;

    Future<List<ChatAssistantDataItem>> assistantsFuture = _loadAssistants();
    return showDialog<ChatAssistantDataItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> refreshAssistants() async {
              setDialogState(() {
                assistantsFuture = _loadAssistants();
              });
            }

            return AlertDialog(
              title: Text('chat_assistants_title'.tr),
              content: SizedBox(
                width: 860,
                child: FutureBuilder<List<ChatAssistantDataItem>>(
                  future: assistantsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final assistants = snapshot.data ?? const <ChatAssistantDataItem>[];
                    if (assistants.isEmpty) {
                      return Center(child: Text('chat_assistant_empty'.tr));
                    }

                    final userDefined = assistants.where((a) => a.body.type == ChatAssistantType.userDefined).toList();
                    final system = assistants.where((a) => a.body.type == ChatAssistantType.system).toList();

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAssistantSection(
                            title: 'chat_assistant_section_user'.tr,
                            assistants: userDefined,
                            forSelection: forSelection,
                            onRefresh: refreshAssistants,
                            dialogContext: dialogContext,
                          ),
                          if (system.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildAssistantSection(
                              title: 'chat_assistant_section_system'.tr,
                              assistants: system,
                              forSelection: forSelection,
                              onRefresh: refreshAssistants,
                              dialogContext: dialogContext,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('cancel'.tr),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await _createOrEditAssistant();
                    await refreshAssistants();
                  },
                  icon: const Icon(Icons.add),
                  label: Text('chat_assistant_create'.tr),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createOrEditAssistant({ChatAssistantDataItem? existing}) async {
    await _ensureController();
    final controller = _controller;
    if (controller == null || !mounted) return;

    final nameController = TextEditingController(text: existing?.body.name ?? '');
    final descriptionController = TextEditingController(text: existing?.body.description ?? '');
    final promptController = TextEditingController(text: existing?.body.prompt ?? '');
    final baseUrlController = TextEditingController(text: existing?.body.modelConfig?.baseUrl ?? '');
    final modelController = TextEditingController(text: existing?.body.modelConfig?.model ?? '');
    final tempController = TextEditingController(
      text: existing?.body.modelConfig?.temperature?.toString() ?? '',
    );
    final reasoningEffortController = TextEditingController(text: existing?.body.modelConfig?.reasoningEffort ?? '');

    var overrideEnabled = existing?.body.modelConfig != null;
    var thinkingEnabled = existing?.body.modelConfig?.thinkingEnabled ?? false;
    var provider = existing?.body.modelConfig?.provider ?? ChatAssistantModelProvider.deepSeek;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text((existing == null ? 'chat_assistant_create' : 'chat_assistant_edit').tr),
                content: SingleChildScrollView(
                  child: SizedBox(
                    width: 520,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(labelText: 'chat_assistant_name'.tr),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(labelText: 'chat_assistant_description'.tr),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: promptController,
                          minLines: 4,
                          maxLines: 8,
                          decoration: InputDecoration(labelText: 'chat_assistant_prompt'.tr),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          value: overrideEnabled,
                          contentPadding: EdgeInsets.zero,
                          title: Text('chat_assistant_model_override'.tr),
                          onChanged: (value) {
                            setDialogState(() {
                              overrideEnabled = value;
                            });
                          },
                        ),
                        if (overrideEnabled) ...[
                          const SizedBox(height: 8),
                        DropdownButtonFormField<ChatAssistantModelProvider>(
                            initialValue: provider,
                            decoration: InputDecoration(labelText: 'chat_assistant_model_provider'.tr),
                            items: ChatAssistantModelProvider.values
                                .map((value) => DropdownMenuItem(value: value, child: Text(value.name)))
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setDialogState(() {
                                provider = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: baseUrlController,
                            decoration: InputDecoration(labelText: 'chat_assistant_model_base_url'.tr),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: modelController,
                            decoration: InputDecoration(labelText: 'chat_assistant_model_name'.tr),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: tempController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(labelText: 'chat_assistant_model_temperature'.tr),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            value: thinkingEnabled,
                            contentPadding: EdgeInsets.zero,
                            title: Text('chat_assistant_model_thinking_enabled'.tr),
                            onChanged: (value) {
                              setDialogState(() {
                                thinkingEnabled = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: reasoningEffortController,
                            decoration: InputDecoration(labelText: 'chat_assistant_model_reasoning_effort'.tr),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text('cancel'.tr)),
                  FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text('save'.tr)),
                ],
              );
            },
          );
        },
      );

      final parsedTemperature = tempController.text.trim().isEmpty ? null : double.tryParse(tempController.text.trim());
      if (result == true && mounted) {
        if (nameController.text.trim().isEmpty || promptController.text.trim().isEmpty) {
          Get.snackbar('chat_assistant_validation_title'.tr, 'chat_assistant_validation_required'.tr);
          return;
        }
        if (overrideEnabled && tempController.text.trim().isNotEmpty && parsedTemperature == null) {
          Get.snackbar('chat_assistant_validation_title'.tr, 'chat_assistant_validation_temperature'.tr);
          return;
        }

        final modelConfig = overrideEnabled
            ? ChatAssistantModelConfig(
                provider: provider,
                baseUrl: baseUrlController.text.trim().isEmpty ? null : baseUrlController.text.trim(),
                model: modelController.text.trim().isEmpty ? null : modelController.text.trim(),
                temperature: parsedTemperature,
                thinkingEnabled: thinkingEnabled,
                reasoningEffort:
                    reasoningEffortController.text.trim().isEmpty ? null : reasoningEffortController.text.trim(),
              )
            : null;

        final body = ChatAssistant(
          name: nameController.text.trim(),
          type: existing?.body.type ?? ChatAssistantType.userDefined,
          description: descriptionController.text.trim(),
          prompt: promptController.text.trim(),
          avatarUrl: existing?.body.avatarUrl,
          modelConfig: modelConfig,
        );
        await controller.upsertAssistant(existing, body);
        await controller.reloadConversations();
      }
    } finally {
      nameController.dispose();
      descriptionController.dispose();
      promptController.dispose();
      baseUrlController.dispose();
      modelController.dispose();
      tempController.dispose();
      reasoningEffortController.dispose();
    }
  }

  Future<void> _editAssistant(String assistantId) async {
    final assistant = await ChatAssistantRepository().getFromLocalDb(assistantId);
    if (assistant == null) {
      if (mounted) {
        Get.snackbar('chat_assistant_not_found_title'.tr, 'chat_assistant_not_found_message'.tr);
      }
      return;
    }
    await _createOrEditAssistant(existing: assistant);
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () async {
                        await _openAssistantsDialog(forSelection: false);
                      },
                      icon: const Icon(Icons.smart_toy_outlined),
                      tooltip: 'chat_assistants_title'.tr,
                    ),
                    IconButton(
                      onPressed: _createConversation,
                      icon: const Icon(Icons.add_comment_outlined),
                      tooltip: 'chat_new_conversation'.tr,
                    ),
                  ],
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
                                  return;
                                }
                                if (value == 'edit_assistant') {
                                  await _editAssistant(vm.item.body.assistantId);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'sync', child: Text('chat_sync_conversation'.tr)),
                                PopupMenuItem(value: 'edit_assistant', child: Text('chat_assistant_edit'.tr)),
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
