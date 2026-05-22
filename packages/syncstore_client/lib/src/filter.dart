import 'package:equatable/equatable.dart';
import 'package:syncstore_client/src/models.dart' show SyncStatus, DataItem, ColorTag;

abstract interface class DataItemFilter<T> {
  bool apply(DataItem<T> item);
}

abstract class EquatableFilter<T> extends Equatable implements DataItemFilter<T> {
  const EquatableFilter();

  // all class must implement props to make Equatable work
  @override
  abstract final List<Object?> props;
}

abstract class DataItemBodyEquatableFilter<T> extends Equatable implements DataItemFilter<T> {
  const DataItemBodyEquatableFilter();
  bool applyBody(T body);
  @override
  bool apply(DataItem<T> item) => applyBody(item.body);

  @override
  abstract final List<Object?> props;
}

class ParentIdFilter extends EquatableFilter {
  final String parentId;
  ParentIdFilter(this.parentId);

  @override
  bool apply(DataItem<dynamic> item) {
    return item.parentId == parentId;
  }

  @override
  List<Object?> get props => [parentId];
}

class IdsFilter extends EquatableFilter {
  final List<String> ids;
  IdsFilter(this.ids);

  @override
  bool apply(DataItem<dynamic> item) {
    return ids.contains(item.id);
  }

  @override
  List<Object?> get props => [ids];
}

enum StatusFilter implements DataItemFilter {
  synced,
  notHidden;

  @override
  bool apply(DataItem<dynamic> item) {
    switch (this) {
      case StatusFilter.synced:
        return item.syncStatus == SyncStatus.synced;
      case StatusFilter.notHidden:
        return item.syncStatus != SyncStatus.hidden;
    }
  }
}

enum ColorTagFilter implements DataItemFilter {
  // none,
  red,
  orange,
  yellow,
  green,
  blue,
  gray,
  all;

  @override
  bool apply(DataItem<dynamic> item) {
    switch (this) {
      case ColorTagFilter.red:
        return item.colorTag == ColorTag.red;
      case ColorTagFilter.orange:
        return item.colorTag == ColorTag.orange;
      case ColorTagFilter.yellow:
        return item.colorTag == ColorTag.yellow;
      case ColorTagFilter.green:
        return item.colorTag == ColorTag.green;
      case ColorTagFilter.blue:
        return item.colorTag == ColorTag.blue;
      case ColorTagFilter.gray:
        return item.colorTag == ColorTag.gray;
      case ColorTagFilter.all:
        return true;
    }
  }

  factory ColorTagFilter.fromColorTag(ColorTag tag) {
    switch (tag) {
      case ColorTag.red:
        return ColorTagFilter.red;
      case ColorTag.orange:
        return ColorTagFilter.orange;
      case ColorTag.yellow:
        return ColorTagFilter.yellow;
      case ColorTag.green:
        return ColorTagFilter.green;
      case ColorTag.blue:
        return ColorTagFilter.blue;
      case ColorTag.gray:
        return ColorTagFilter.gray;
      case ColorTag.none:
        return ColorTagFilter.all;
    }
  }
}

class OrFilter<T> extends EquatableFilter<T> {
  final Iterable<DataItemFilter<T>> filters;
  OrFilter(this.filters);

  @override
  bool apply(DataItem<T> item) {
    for (var filter in filters) {
      if (filter.apply(item)) {
        return true;
      }
    }
    return false;
  }

  @override
  List<Object?> get props => [filters];
}
