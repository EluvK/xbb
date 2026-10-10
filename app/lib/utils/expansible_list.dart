import 'package:flutter/material.dart';

mixin ExpansibleListMixin<T extends StatefulWidget> on State<T> {
  final Map<String, ExpansibleController> _controllers = {};
  bool _allExpanded = true;
  bool _isProcessing = false;

  bool isAllExpanded() {
    if (_controllers.isEmpty) return _allExpanded;
    return _controllers.values.every((c) => c.isExpanded);
  }

  void toggleAll() async {
    if (_isProcessing) return;
    _isProcessing = true;

    _allExpanded = !isAllExpanded();
    for (var controller in _controllers.values) {
      _allExpanded ? controller.expand() : controller.collapse();
    }

    setState(() {});
    await Future.delayed(const Duration(milliseconds: 300));
    _isProcessing = false;
  }

  ExpansibleController getController(String key) {
    return _controllers.putIfAbsent(key, () {
      final c = ExpansibleController();
      if (_allExpanded) c.expand();
      return c;
    });
  }

  void disposeControllers() {
    _controllers.clear();
  }
}

class GroupedExpansionList<K, V> extends StatelessWidget {
  final Map<K, List<V>> groupedData;
  final Widget Function(K key, ExpansibleController controller) titleBuilder;
  final Widget Function(V item) itemBuilder;
  final ExpansibleController Function(String key) controllerProvider;
  final EdgeInsetsGeometry? tilePadding;
  final ListTileControlAffinity controlAffinity;

  const GroupedExpansionList({
    super.key,
    required this.groupedData,
    required this.titleBuilder,
    required this.itemBuilder,
    required this.controllerProvider,
    this.tilePadding,
    this.controlAffinity = ListTileControlAffinity.leading,
  });

  @override
  Widget build(BuildContext context) {
    if (groupedData.isEmpty) {
      // return const Center(child: Text('No items found.'));
      // return a draggable area to trigger pull-to-refresh when list is empty, since Center will block the gesture.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: const Center(child: Text('No items found.')),
          ),
        ],
      );
    }

    return ListView(
      children: groupedData.entries.map((entry) {
        final key = entry.key;
        final controller = controllerProvider(key.toString());

        return ExpansionTile(
          controller: controller,
          title: titleBuilder(key, controller),
          tilePadding: tilePadding,
          controlAffinity: controlAffinity,
          children: entry.value.map((item) => itemBuilder(item)).toList(),
        );
      }).toList(),
    );
  }
}
