import 'package:flutter/material.dart';
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
  bool _isInitializing = true;
  List<ClipboardHistoryEntryDataItem> _items = const [];
  final Set<String> _selectedIds = <String>{};

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
    if (!mounted) return;
    setState(() {
      _items = sorted;
    });
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

  void _confirmSyncSelected() {
    if (!_hasSelection) return;
    flushBar(
      FlushLevel.INFO,
      'clipboard_confirm_sync_title'.tr,
      'clipboard_confirm_sync_stub_message'.trParams({'count': _selectedIds.length.toString()}),
      upperPosition: true,
    );
  }

  @override
  void dispose() {
    _worker?.dispose();
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
        _ActionBar(
          selectedCount: _selectedIds.length,
          onClearSelection: _clearSelection,
          onConfirmSync: _confirmSyncSelected,
        ),
        Expanded(
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _items[index];
              final isSelected = _selectedIds.contains(item.id);
              return _ClipboardEntryTile(
                item: item,
                isSelected: isSelected,
                onSelectChanged: (selected) => _toggleSelect(item.id, selected),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.selectedCount, required this.onClearSelection, required this.onConfirmSync});

  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onConfirmSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Row(
        children: [
          Text('clipboard_selected_count'.trParams({'count': selectedCount.toString()})),
          const Spacer(),
          TextButton(onPressed: selectedCount > 0 ? onClearSelection : null, child: Text('clear_selection'.tr)),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: selectedCount > 0 ? onConfirmSync : null,
            icon: const Icon(Icons.cloud_upload_rounded),
            label: Text('clipboard_confirm_sync_action'.tr),
          ),
        ],
      ),
    );
  }
}

class _ClipboardEntryTile extends StatelessWidget {
  const _ClipboardEntryTile({required this.item, required this.isSelected, required this.onSelectChanged});

  final ClipboardHistoryEntryDataItem item;
  final bool isSelected;
  final ValueChanged<bool> onSelectChanged;

  @override
  Widget build(BuildContext context) {
    final preview = item.body.data.trim();
    final statusLabel = item.body.localOnly ? 'clipboard_status_local_only'.tr : 'clipboard_status_synced'.tr;
    final statusColor = item.body.localOnly ? Colors.orange : Colors.green;

    return ListTile(
      leading: Checkbox(value: isSelected, onChanged: (value) => onSelectChanged(value ?? false)),
      title: Text(
        preview.isEmpty ? 'clipboard_history_empty_content'.tr : preview,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(detailedDateStr(item.createdAt), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
        child: Text(
          statusLabel,
          style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
        ),
      ),
      onTap: () => onSelectChanged(!isSelected),
    );
  }
}
