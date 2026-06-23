import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xbb/models/clipboard/model.dart';

// UNUSED in current layout - clipboard overview sidebar was removed during desktop refactoring.
class ViewClipboardOverview extends StatefulWidget {
  const ViewClipboardOverview({super.key});

  @override
  State<ViewClipboardOverview> createState() => _ViewClipboardOverviewState();
}

class _ViewClipboardOverviewState extends State<ViewClipboardOverview> {
  static const String _filterKey = 'view-clipboard-overview-all';

  ClipboardHistoryEntryController? _controller;
  RxList<ClipboardHistoryEntryDataItem>? _entriesRx;
  Worker? _worker;
  bool _isInitializing = true;
  int _total = 0;
  int _pending = 0;

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
    _worker = ever<List<ClipboardHistoryEntryDataItem>>(_entriesRx!, (_) => _refreshStats());
    _refreshStats();

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  void _refreshStats() {
    final items = _entriesRx?.toList(growable: false) ?? const <ClipboardHistoryEntryDataItem>[];
    final pending = items.where((item) => item.body.localOnly).length;
    if (!mounted) return;
    setState(() {
      _total = items.length;
      _pending = pending;
    });
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

    final synced = _total - _pending;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('clipboard_overview_title'.tr, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text('clipboard_overview_subtitle'.tr),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(label: 'clipboard_overview_total'.tr, value: _total),
                    _StatChip(label: 'clipboard_overview_pending'.tr, value: _pending),
                    _StatChip(label: 'clipboard_overview_synced'.tr, value: synced),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 8),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
