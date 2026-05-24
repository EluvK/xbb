import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:xbb/models/clipboard/model.dart';
import 'package:xbb/utils/utils.dart';

class ViewClipboardHistory extends StatefulWidget {
  const ViewClipboardHistory({super.key});

  @override
  State<ViewClipboardHistory> createState() => _ViewClipboardHistoryState();
}

class _ViewClipboardHistoryState extends State<ViewClipboardHistory> {
  static const String _filterKey = 'view-clipboard-history-all';

  ClipboardHistoryEntryController? _controller;
  RxList<ClipboardHistoryEntryDataItem>? _entriesRx;
  Worker? _worker;
  final TextEditingController _searchFilterTextController = TextEditingController();
  final TextEditingController _editTextController = TextEditingController();
  bool _isInitializing = true;
  List<ClipboardHistoryEntryDataItem> _items = const [];
  List<ClipboardHistoryEntryDataItem> _filteredItems = const [];
  final Set<String> _selectedIds = <String>{};
  final Set<String> _expandedIds = <String>{};
  String? _editingId;

  bool get _hasSelection => _selectedIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    if (!Get.isRegistered<ClipboardHistoryEntryController>()) {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
      return;
    }

    _controller = Get.find<ClipboardHistoryEntryController>();
    await _controller!.ensureInitialization();
    _entriesRx = _controller!.registerFilterSubscription(filterKey: _filterKey);
    _worker = ever<List<ClipboardHistoryEntryDataItem>>(_entriesRx!, (_) => _refreshItems());
    _refreshItems();

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  void _refreshItems() {
    final incoming = _entriesRx?.toList(growable: false) ?? const <ClipboardHistoryEntryDataItem>[];
    final sorted = List<ClipboardHistoryEntryDataItem>.of(incoming)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _selectedIds.removeWhere((id) => !sorted.any((item) => item.id == id));
    _expandedIds.removeWhere((id) => !sorted.any((item) => item.id == id));
    if (_editingId != null && !sorted.any((item) => item.id == _editingId)) {
      _editingId = null;
      _editTextController.clear();
    }
    final filtered = _applySearchFilter(sorted, _searchFilterTextController.text);
    _selectedIds.removeWhere((id) => !filtered.any((item) => item.id == id));
    _expandedIds.removeWhere((id) => !filtered.any((item) => item.id == id));
    if (!mounted) return;
    setState(() {
      _items = sorted;
      _filteredItems = filtered;
    });
  }

  List<ClipboardHistoryEntryDataItem> _applySearchFilter(List<ClipboardHistoryEntryDataItem> source, String keyword) {
    final query = keyword.trim().toLowerCase();
    if (query.isEmpty) {
      return source;
    }
    return source
        .where((item) {
          final text = item.body.data.toLowerCase();
          return text.contains(query);
        })
        .toList(growable: false);
  }

  void _toggleSelect(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _clearSelection() {
    if (!_hasSelection) return;
    setState(() {
      _selectedIds.clear();
    });
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
        if (_editingId == id) {
          _editingId = null;
          _editTextController.clear();
        }
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _startEdit(ClipboardHistoryEntryDataItem item) {
    setState(() {
      _expandedIds.add(item.id);
      _editingId = item.id;
      _editTextController.text = item.body.data;
    });
  }

  Future<void> _saveEdit(ClipboardHistoryEntryDataItem item) async {
    final newText = _editTextController.text;
    final updatedBody = item.body.copyWith(data: newText);
    final updatedItem = item.updatedBody(updatedBody);
    await ClipboardHistoryEntryRepository().updateToLocalDb(updatedItem);
    if (Get.isRegistered<ClipboardHistoryEntryController>()) {
      await Get.find<ClipboardHistoryEntryController>().rebuildLocal();
    }
    if (!mounted) return;
    setState(() {
      _editingId = null;
      _editTextController.clear();
    });
    successSimpleFlushBar('clipboard_edit_saved'.tr);
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    successSimpleFlushBar('clipboard_copy_done'.tr);
  }

  void _confirmSyncSelected() {
    if (!_hasSelection) return;
    flushBar(
      FlushLevel.INFO,
      'clipboard_confirm_sync_title'.tr,
      'clipboard_confirm_sync_stub_message'.trParams({'count': _selectedIds.length.toString()}),
      upperPosition: true,
    );
  }

  Future<void> _deleteSelectedLocal() async {
    if (!_hasSelection) return;
    final controller = _controller;
    if (controller == null) return;
    final ids = _selectedIds.toList(growable: false);
    for (final id in ids) {
      await ClipboardHistoryEntryRepository().deleteFromLocalDb(id);
    }
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
    });
    await controller.rebuildLocal();
    flushBar(
      FlushLevel.OK,
      null,
      'clipboard_delete_selected_done'.trParams({'count': ids.length.toString()}),
      upperPosition: true,
    );
  }

  @override
  void dispose() {
    _worker?.dispose();
    _searchFilterTextController.dispose();
    _editTextController.dispose();
    _controller?.unregisterFilterSubscription(_filterKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'clipboard_history_empty'.tr,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Column(
      children: [
        _SearchFilter(
          controller: _searchFilterTextController,
          onChanged: (value) {
            setState(() {
              _filteredItems = _applySearchFilter(_items, value);
              _selectedIds.removeWhere((id) => !_filteredItems.any((item) => item.id == id));
            });
          },
        ),
        _ActionBar(
          selectedCount: _selectedIds.length,
          onClearSelection: _clearSelection,
          onConfirmSync: _confirmSyncSelected,
          onDeleteSelected: _deleteSelectedLocal,
        ),
        Expanded(
          child: _filteredItems.isEmpty
              ? Center(
                  child: Text(
                    'clipboard_history_filter_empty'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : ListView.separated(
                  itemCount: _filteredItems.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];
                    final isSelected = _selectedIds.contains(item.id);
                    final isExpanded = _expandedIds.contains(item.id);
                    final isEditing = _editingId == item.id;
                    return _ClipboardEntryTile(
                      item: item,
                      isSelected: isSelected,
                      isExpanded: isExpanded,
                      isEditing: isEditing,
                      editingController: _editTextController,
                      onSelectChanged: (selected) => _toggleSelect(item.id, selected),
                      onExpandToggle: () => _toggleExpand(item.id),
                      onCopy: () => _copyText(item.body.data),
                      onStartEdit: () => _startEdit(item),
                      onCancelEdit: () {
                        setState(() {
                          _editingId = null;
                          _editTextController.clear();
                        });
                      },
                      onSaveEdit: () => _saveEdit(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SearchFilter extends StatelessWidget {
  const _SearchFilter({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: TextField(
        controller: controller,
        onTapOutside: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search_rounded),
          hintText: 'search_title'.tr,
          suffixIcon: IconButton(
            onPressed: () {
              controller.text = '';
              onChanged('');
            },
            icon: const Icon(Icons.clear_rounded),
          ),
          border: const OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.selectedCount,
    required this.onClearSelection,
    required this.onConfirmSync,
    required this.onDeleteSelected,
  });

  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onConfirmSync;
  final VoidCallback onDeleteSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Row(
        children: [
          if (selectedCount > 0) Text('$selectedCount', style: Theme.of(context).textTheme.labelLarge),
          const Spacer(),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: selectedCount > 0 ? onDeleteSelected : null,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text('delete'.tr),
                  ),
                  TextButton(onPressed: selectedCount > 0 ? onClearSelection : null, child: Text('clear_selection'.tr)),
                  FilledButton.icon(
                    onPressed: selectedCount > 0 ? onConfirmSync : null,
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: Text('clipboard_confirm_sync_action'.tr),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClipboardEntryTile extends StatelessWidget {
  const _ClipboardEntryTile({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.isEditing,
    required this.editingController,
    required this.onSelectChanged,
    required this.onExpandToggle,
    required this.onCopy,
    required this.onStartEdit,
    required this.onCancelEdit,
    required this.onSaveEdit,
  });

  final ClipboardHistoryEntryDataItem item;
  final bool isSelected;
  final bool isExpanded;
  final bool isEditing;
  final TextEditingController editingController;
  final ValueChanged<bool> onSelectChanged;
  final VoidCallback onExpandToggle;
  final VoidCallback onCopy;
  final VoidCallback onStartEdit;
  final VoidCallback onCancelEdit;
  final VoidCallback onSaveEdit;

  @override
  Widget build(BuildContext context) {
    final preview = item.body.data.trim();
    final statusLabel = item.body.localOnly ? 'clipboard_status_local_only'.tr : 'clipboard_status_synced'.tr;
    final statusColor = item.body.localOnly ? Colors.orange : Colors.green;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onExpandToggle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: Checkbox(value: isSelected, onChanged: (value) => onSelectChanged(value ?? false)),
              title: Text(
                preview.isEmpty ? 'clipboard_history_empty_content'.tr : preview,
                maxLines: isExpanded ? 4 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(detailedDateStr(item.createdAt), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 18),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isEditing)
                      TextField(
                        controller: editingController,
                        minLines: 3,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: 'clipboard_edit_hint'.tr,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      )
                    else
                      SelectableText(
                        preview.isEmpty ? 'clipboard_history_empty_content'.tr : preview,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: isEditing
                          ? [
                              FilledButton.icon(
                                onPressed: onSaveEdit,
                                icon: const Icon(Icons.save_outlined),
                                label: Text('save'.tr),
                              ),
                              OutlinedButton(onPressed: onCancelEdit, child: Text('cancel'.tr)),
                            ]
                          : [
                              OutlinedButton.icon(
                                onPressed: onCopy,
                                icon: const Icon(Icons.copy_rounded),
                                label: Text('clipboard_copy_action'.tr),
                              ),
                              OutlinedButton.icon(
                                onPressed: onStartEdit,
                                icon: const Icon(Icons.edit_outlined),
                                label: Text('edit'.tr),
                              ),
                            ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
