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
  final Set<String> _collapsedDateKeys = <String>{};
  String? _editingId;
  bool _isSyncingSelected = false;
  bool _isDeletingSelected = false;

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
    final sorted = List<ClipboardHistoryEntryDataItem>.of(incoming)
      ..sort((a, b) => _displayTimeOf(b).compareTo(_displayTimeOf(a)));
    _selectedIds.removeWhere((id) => !sorted.any((item) => item.id == id));
    _expandedIds.removeWhere((id) => !sorted.any((item) => item.id == id));
    if (_editingId != null && !sorted.any((item) => item.id == _editingId)) {
      _editingId = null;
      _editTextController.clear();
    }
    final filtered = _applySearchFilter(sorted, _searchFilterTextController.text);
    _selectedIds.removeWhere((id) => !filtered.any((item) => item.id == id));
    _expandedIds.removeWhere((id) => !filtered.any((item) => item.id == id));
    final visibleDateKeys = filtered.map((item) => _dateKey(_displayTimeOf(item))).toSet();
    _collapsedDateKeys.removeWhere((key) => !visibleDateKeys.contains(key));
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

  bool _isDateGroupAllSelected(_ClipboardDateGroup group) {
    if (group.items.isEmpty) {
      return false;
    }
    return group.items.every((item) => _selectedIds.contains(item.id));
  }

  void _toggleSelectDateGroup(_ClipboardDateGroup group) {
    if (group.items.isEmpty) {
      return;
    }
    final ids = group.items.map((item) => item.id).toList(growable: false);
    final shouldUnselect = ids.every(_selectedIds.contains);
    setState(() {
      if (shouldUnselect) {
        _selectedIds.removeAll(ids);
      } else {
        _selectedIds.addAll(ids);
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

  void _toggleDateGroup(String dateKey) {
    setState(() {
      if (_collapsedDateKeys.contains(dateKey)) {
        _collapsedDateKeys.remove(dateKey);
      } else {
        _collapsedDateKeys.add(dateKey);
      }
    });
  }

  void _startEdit(ClipboardHistoryEntryDataItem item) {
    setState(() {
      _collapsedDateKeys.remove(_dateKey(_displayTimeOf(item)));
      _expandedIds.add(item.id);
      _editingId = item.id;
      _editTextController.text = item.body.data;
    });
  }

  Future<void> _saveEdit(ClipboardHistoryEntryDataItem item) async {
    final newText = _editTextController.text;
    final controller = _controller;
    if (controller == null) return;

    final result = await saveEditedClipboardEntry(client: controller.client, item: item, newText: newText);
    if (Get.isRegistered<ClipboardHistoryEntryController>()) {
      await Get.find<ClipboardHistoryEntryController>().rebuildLocal();
    }
    if (!mounted) return;
    setState(() {
      _editingId = null;
      _editTextController.clear();
    });

    if (!result.changed) {
      flushBar(FlushLevel.INFO, null, 'clipboard_edit_no_change'.tr, upperPosition: true);
      return;
    }

    if (!result.remoteAttempted) {
      successSimpleFlushBar('clipboard_edit_saved'.tr);
      return;
    }

    if (result.remoteSucceeded) {
      successSimpleFlushBar('clipboard_edit_saved_synced'.tr);
      return;
    }

    flushBar(FlushLevel.WARNING, null, 'clipboard_edit_saved_sync_failed'.tr, upperPosition: true);
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    successSimpleFlushBar('clipboard_copy_done'.tr);
  }

  Future<void> _confirmSyncSelected() async {
    if (!_hasSelection || _isSyncingSelected) return;
    final controller = _controller;
    if (controller == null) return;

    final selectedItems = _items.where((item) => _selectedIds.contains(item.id)).toList(growable: false);
    if (selectedItems.isEmpty) {
      return;
    }

    setState(() {
      _isSyncingSelected = true;
    });

    final result = await confirmClipboardEntriesManualSync(client: controller.client, selectedItems: selectedItems);

    await controller.rebuildLocal();
    if (!mounted) return;

    setState(() {
      _isSyncingSelected = false;
      if (result.failedCount > 0) {
        _selectedIds
          ..clear()
          ..addAll(result.failedIds);
      } else {
        _selectedIds.clear();
      }
    });

    if (result.syncedCount > 0 && result.failedCount == 0) {
      flushBar(
        FlushLevel.OK,
        null,
        'clipboard_confirm_sync_success'.trParams({
          'synced': result.syncedCount.toString(),
          'skipped': result.alreadySyncedCount.toString(),
        }),
        upperPosition: true,
      );
      return;
    }

    if (result.syncedCount > 0 && result.failedCount > 0) {
      flushBar(
        FlushLevel.WARNING,
        'clipboard_confirm_sync_title'.tr,
        'clipboard_confirm_sync_partial'.trParams({
          'synced': result.syncedCount.toString(),
          'failed': result.failedCount.toString(),
          'skipped': result.alreadySyncedCount.toString(),
        }),
        upperPosition: true,
      );
      return;
    }

    if (result.failedCount > 0) {
      flushBar(
        FlushLevel.WARNING,
        'clipboard_confirm_sync_title'.tr,
        'clipboard_confirm_sync_failed'.trParams({'failed': result.failedCount.toString()}),
        upperPosition: true,
      );
      return;
    }

    flushBar(FlushLevel.INFO, null, 'clipboard_confirm_sync_nothing_to_sync'.tr, upperPosition: true);
  }

  Future<void> _deleteSelectedLocal() async {
    if (!_hasSelection || _isDeletingSelected) return;
    final controller = _controller;
    if (controller == null) return;

    final selectedItems = _items.where((item) => _selectedIds.contains(item.id)).toList(growable: false);
    if (selectedItems.isEmpty) {
      return;
    }

    setState(() {
      _isDeletingSelected = true;
    });

    final result = await deleteClipboardEntriesWithRemoteSync(client: controller.client, selectedItems: selectedItems);

    await controller.rebuildLocal();
    if (!mounted) return;

    setState(() {
      _isDeletingSelected = false;
      if (result.failedCount > 0) {
        _selectedIds
          ..clear()
          ..addAll(result.failedIds);
      } else {
        _selectedIds.clear();
      }
    });

    if (result.deletedCount > 0 && result.failedCount == 0) {
      flushBar(
        FlushLevel.OK,
        null,
        'clipboard_delete_selected_done'.trParams({'count': result.deletedCount.toString()}),
        upperPosition: true,
      );
      return;
    }

    if (result.deletedCount > 0 && result.failedCount > 0) {
      flushBar(
        FlushLevel.WARNING,
        null,
        'clipboard_delete_selected_partial'.trParams({
          'deleted': result.deletedCount.toString(),
          'failed': result.failedCount.toString(),
        }),
        upperPosition: true,
      );
      return;
    }

    flushBar(
      FlushLevel.WARNING,
      null,
      'clipboard_delete_selected_failed'.trParams({'failed': result.failedCount.toString()}),
      upperPosition: true,
    );
  }

  Future<void> _refreshClipboardHistory() async {
    await onReadySyncClipboard();
    if (!mounted) return;
    _refreshItems();
  }

  String _dateKey(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _timeLabel(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _weekdayLabel(DateTime dt) {
    final isZh = (Get.locale?.languageCode ?? '').startsWith('zh');
    if (isZh) {
      const zhWeekdays = <int, String>{
        DateTime.monday: '星期一',
        DateTime.tuesday: '星期二',
        DateTime.wednesday: '星期三',
        DateTime.thursday: '星期四',
        DateTime.friday: '星期五',
        DateTime.saturday: '星期六',
        DateTime.sunday: '星期日',
      };
      return zhWeekdays[dt.weekday] ?? '';
    }
    const enWeekdays = <int, String>{
      DateTime.monday: 'Mon',
      DateTime.tuesday: 'Tue',
      DateTime.wednesday: 'Wed',
      DateTime.thursday: 'Thu',
      DateTime.friday: 'Fri',
      DateTime.saturday: 'Sat',
      DateTime.sunday: 'Sun',
    };
    return enWeekdays[dt.weekday] ?? '';
  }

  String _dateHeaderLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (_isSameDate(date, today)) {
      return '${_dateKey(date)} · ${'tracker_today'.tr}';
    }
    if (_isSameDate(date, yesterday)) {
      final isZh = (Get.locale?.languageCode ?? '').startsWith('zh');
      final yesterdayLabel = isZh ? '昨天' : 'Yesterday';
      return '${_dateKey(date)} · $yesterdayLabel';
    }
    return '${_dateKey(date)} · ${_weekdayLabel(date)}';
  }

  List<_ClipboardDateGroup> _groupByDate(List<ClipboardHistoryEntryDataItem> source) {
    final groups = <_ClipboardDateGroup>[];
    for (final item in source) {
      final displayTime = _displayTimeOf(item);
      final key = _dateKey(displayTime);
      final local = displayTime.toLocal();
      final date = DateTime(local.year, local.month, local.day);
      if (groups.isNotEmpty && groups.last.key == key) {
        groups.last.items.add(item);
      } else {
        groups.add(_ClipboardDateGroup(key: key, date: date, items: <ClipboardHistoryEntryDataItem>[item]));
      }
    }
    return groups;
  }

  Widget _buildEntryTile(ClipboardHistoryEntryDataItem item) {
    final isSelected = _selectedIds.contains(item.id);
    final isExpanded = _expandedIds.contains(item.id);
    final isEditing = _editingId == item.id;
    return _ClipboardEntryTile(
      item: item,
      timeLabel: _timeLabel(_displayTimeOf(item)),
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
      return RefreshIndicator(
        onRefresh: _refreshClipboardHistory,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 220,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'clipboard_history_empty'.tr,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
          ],
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
          isBusy: _isSyncingSelected || _isDeletingSelected,
          onClearSelection: _clearSelection,
          onConfirmSync: () {
            _confirmSyncSelected();
          },
          onDeleteSelected: _deleteSelectedLocal,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshClipboardHistory,
            child: _filteredItems.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 180,
                        child: Center(
                          child: Text(
                            'clipboard_history_filter_empty'.tr,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                    ],
                  )
                : Builder(
                    builder: (context) {
                      final groups = _groupByDate(_filteredItems);
                      return ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: groups.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, indent: 12, endIndent: 12),
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          final isCollapsed = _collapsedDateKeys.contains(group.key);
                          final isAllSelected = _isDateGroupAllSelected(group);
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                InkWell(
                                  onTap: () => _toggleDateGroup(group.key),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isCollapsed ? Icons.chevron_right_rounded : Icons.expand_more_rounded,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                         Text(
                                           _dateHeaderLabel(group.date),
                                           style: Theme.of(
                                             context,
                                           ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                         ),
                                         const SizedBox(width: 8),
                                         Text('${group.items.length}', style: Theme.of(context).textTheme.bodySmall),
                                         const Spacer(),
                                         TextButton(
                                           onPressed: () => _toggleSelectDateGroup(group),
                                           style: TextButton.styleFrom(
                                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                             minimumSize: const Size(0, 28),
                                             tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                           ),
                                           child: Text(
                                             isAllSelected
                                                 ? 'clipboard_unselect_day_items'.tr
                                                 : 'clipboard_select_day_items'.tr,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),
                                 ),
                                if (!isCollapsed) const Divider(height: 1),
                                if (!isCollapsed)
                                  ...List<Widget>.generate(group.items.length, (itemIndex) {
                                    final tile = _buildEntryTile(group.items[itemIndex]);
                                    if (itemIndex == group.items.length - 1) {
                                      return tile;
                                    }
                                    return Column(children: [tile, const Divider(height: 1)]);
                                  }),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
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
    required this.isBusy,
    required this.onClearSelection,
    required this.onConfirmSync,
    required this.onDeleteSelected,
  });

  final int selectedCount;
  final bool isBusy;
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
                    onPressed: selectedCount > 0 && !isBusy ? onDeleteSelected : null,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text('delete'.tr),
                  ),
                  TextButton(
                    onPressed: selectedCount > 0 && !isBusy ? onClearSelection : null,
                    child: Text('clear_selection'.tr),
                  ),
                  FilledButton.icon(
                    onPressed: selectedCount > 0 && !isBusy ? onConfirmSync : null,
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: Text(isBusy ? 'clipboard_confirm_syncing'.tr : 'clipboard_confirm_sync_action'.tr),
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
    required this.timeLabel,
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
  final String timeLabel;
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
              subtitle: Text(timeLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
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

class _ClipboardDateGroup {
  final String key;
  final DateTime date;
  final List<ClipboardHistoryEntryDataItem> items;

  _ClipboardDateGroup({required this.key, required this.date, required this.items});
}

DateTime _displayTimeOf(ClipboardHistoryEntryDataItem item) {
  return item.body.capturedAt ?? item.createdAt;
}
