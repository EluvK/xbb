import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'locate.dart';

/// 响应式自动依赖追踪器（无侵入轻量实现，摆脱 GetX 核心引擎）
class _RxTrackingContext {
  static final List<Set<Listenable>> _stack = [];

  static void begin() {
    _stack.add(<Listenable>{});
  }

  static Set<Listenable> end() {
    return _stack.removeLast();
  }

  static void record(Listenable listenable) {
    if (_stack.isNotEmpty) {
      _stack.last.add(listenable);
    }
  }
}

/// 纯净的 Rx 响应式单值封装
class Rx<T> extends ChangeNotifier implements ValueListenable<T> {
  T _value;

  Rx(this._value);

  @override
  T get value {
    _RxTrackingContext.record(this);
    return _value;
  }

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  void call([T? newValue]) {
    if (newValue != null) {
      value = newValue;
    }
  }

  void update(void Function(T? val) fn) {
    fn(_value);
    notifyListeners();
  }

  @override
  String toString() => _value.toString();
}

typedef RxBool = Rx<bool>;
typedef RxString = Rx<String>;
typedef RxInt = Rx<int>;
typedef RxDouble = Rx<double>;

class Rxn<T> extends Rx<T?> {
  Rxn([super.initial]);
}

class RxnString extends Rxn<String> {
  RxnString([super.initial]);
}

extension RxExtension<T> on T {
  Rx<T> get obs => Rx<T>(this);
}

/// 纯净的 RxList 响应式列表封装（基于 Dart 官方 ListMixin）
class RxList<E> extends ChangeNotifier with ListMixin<E> {
  final List<E> _list;

  RxList([Iterable<E>? initial])
      : _list = initial != null ? List<E>.from(initial) : <E>[];

  List<E> get value => this;

  set value(Iterable<E> newItems) {
    assignAll(newItems);
  }

  void assignAll(Iterable<E> iterable) {
    _list.clear();
    _list.addAll(iterable);
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  @override
  int get length {
    _RxTrackingContext.record(this);
    return _list.length;
  }

  @override
  set length(int newLength) {
    _list.length = newLength;
    notifyListeners();
  }

  @override
  E operator [](int index) {
    _RxTrackingContext.record(this);
    return _list[index];
  }

  @override
  void operator []=(int index, E value) {
    _list[index] = value;
    notifyListeners();
  }

  @override
  void add(E element) {
    _list.add(element);
    notifyListeners();
  }

  @override
  void addAll(Iterable<E> iterable) {
    _list.addAll(iterable);
    notifyListeners();
  }

  @override
  bool remove(Object? element) {
    final res = _list.remove(element);
    if (res) notifyListeners();
    return res;
  }

  @override
  void clear() {
    _list.clear();
    notifyListeners();
  }
}

extension RxListExtension<E> on List<E> {
  RxList<E> get obs => RxList<E>(this);
}

/// 纯净的 RxSet 响应式集合封装
class RxSet<E> extends ChangeNotifier with SetMixin<E> {
  final Set<E> _set;

  RxSet([Iterable<E>? initial])
      : _set = initial != null ? Set<E>.from(initial) : <E>{};

  @override
  bool add(E value) {
    final res = _set.add(value);
    if (res) notifyListeners();
    return res;
  }

  @override
  void clear() {
    _set.clear();
    notifyListeners();
  }

  @override
  bool contains(Object? element) {
    _RxTrackingContext.record(this);
    return _set.contains(element);
  }

  @override
  Iterator<E> get iterator {
    _RxTrackingContext.record(this);
    return _set.iterator;
  }

  @override
  int get length {
    _RxTrackingContext.record(this);
    return _set.length;
  }

  @override
  E? lookup(Object? element) {
    _RxTrackingContext.record(this);
    return _set.lookup(element);
  }

  @override
  bool remove(Object? value) {
    final res = _set.remove(value);
    if (res) notifyListeners();
    return res;
  }

  @override
  Set<E> toSet() {
    _RxTrackingContext.record(this);
    return _set.toSet();
  }
}

extension RxSetExtension<E> on Set<E> {
  RxSet<E> get obs => RxSet<E>(this);
}

/// 纯净的 RxMap 响应式字典封装（基于 Dart 官方 MapMixin）
class RxMap<K, V> extends ChangeNotifier with MapMixin<K, V> {
  final Map<K, V> _map;

  RxMap([Map<K, V>? initial])
      : _map = initial != null ? Map<K, V>.from(initial) : <K, V>{};

  @override
  V? operator [](Object? key) {
    _RxTrackingContext.record(this);
    return _map[key];
  }

  @override
  void operator []=(K key, V value) {
    _map[key] = value;
    notifyListeners();
  }

  @override
  void clear() {
    _map.clear();
    notifyListeners();
  }

  @override
  Iterable<K> get keys {
    _RxTrackingContext.record(this);
    return _map.keys;
  }

  @override
  V? remove(Object? key) {
    final res = _map.remove(key);
    notifyListeners();
    return res;
  }
}

extension RxMapExtension<K, V> on Map<K, V> {
  RxMap<K, V> get obs => RxMap<K, V>(this);
}

/// 纯净的 Obx 响应式组件（自动监听 builder 内访问的所有 Rx / RxList / RxMap 对象）
class Obx extends StatefulWidget {
  final Widget Function() builder;

  const Obx(this.builder, {super.key});

  @override
  State<Obx> createState() => _ObxState();
}

class _ObxState extends State<Obx> {
  Set<Listenable> _subscribed = {};

  void _handleChange() {
    if (mounted) setState(() {});
  }

  void _updateSubscriptions(Set<Listenable> newListenables) {
    for (final l in _subscribed) {
      if (!newListenables.contains(l)) {
        l.removeListener(_handleChange);
      }
    }
    for (final l in newListenables) {
      if (!_subscribed.contains(l)) {
        l.addListener(_handleChange);
      }
    }
    _subscribed = newListenables;
  }

  @override
  void dispose() {
    for (final l in _subscribed) {
      l.removeListener(_handleChange);
    }
    _subscribed.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _RxTrackingContext.begin();
    Widget result;
    try {
      result = widget.builder();
    } finally {
      final detected = _RxTrackingContext.end();
      _updateSubscriptions(detected);
    }
    return result;
  }
}

/// 基础控制器类（替代 GetxController）
abstract class AppController extends ChangeNotifier {
  bool _initialized = false;
  bool get isInitialized => _initialized;

  @mustCallSuper
  FutureOr<void> onInit() {
    _initialized = true;
  }

  void onReady() {}

  void update([List<Object>? ids]) {
    notifyListeners();
  }

  Future<void> ensureInitialization() async {
    while (!_initialized) {
      await onInit();
    }
  }

  @mustCallSuper
  void onClose() {}

  @override
  @mustCallSuper
  void dispose() {
    onClose();
    super.dispose();
  }
}

/// 替代 GetBuilder 的轻量组件
class GetBuilder<T extends Listenable> extends StatelessWidget {
  final Widget Function(T controller) builder;
  final String? id;
  final T? init;

  const GetBuilder({super.key, required this.builder, this.id, this.init});

  @override
  Widget build(BuildContext context) {
    final controller = init ?? Locate.find<T>();
    return ListenableBuilder(
      listenable: controller,
      builder: (ctx, _) => builder(controller),
    );
  }
}

/// 响应式扩展辅助
extension IterableFirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension ListAddIfExtension<E> on List<E> {
  void addIf(bool condition, E element) {
    if (condition) add(element);
  }
}

/// 简单的防抖监听工具（替代 GetX debounce）
class DebounceWorker {
  Timer? _timer;
  final Duration duration;
  final void Function() action;
  final Listenable listenable;

  DebounceWorker({
    required this.listenable,
    required this.duration,
    required this.action,
  }) {
    listenable.addListener(_listener);
  }

  void _listener() {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }

  void dispose() {
    _timer?.cancel();
    listenable.removeListener(_listener);
  }
}

class EverWorker {
  final Listenable listenable;
  final void Function(dynamic) callback;

  EverWorker({required this.listenable, required this.callback}) {
    listenable.addListener(_listener);
  }

  void _listener() => callback(null);

  void dispose() => listenable.removeListener(_listener);
}

typedef Worker = dynamic;

EverWorker ever<T>(Listenable listenable, void Function(dynamic) callback) {
  return EverWorker(listenable: listenable, callback: callback);
}

DebounceWorker debounce<T>(
  Listenable listenable,
  void Function(T value) callback, {
  Duration time = const Duration(milliseconds: 100),
}) {
  return DebounceWorker(
    listenable: listenable,
    duration: time,
    action: () {
      if (listenable is ValueListenable) {
        callback(listenable.value);
      } else if (listenable is T) {
        callback(listenable as T);
      } else {
        callback(listenable as dynamic);
      }
    },
  );
}
