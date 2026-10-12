import 'package:flutter/material.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/models/checkin/model.dart';

class EventFilterBar extends StatelessWidget {
  const EventFilterBar({
    super.key,
    required this.events,
    required this.monthlyCounts,
    required this.selectedEventIds,
    required this.onFilterChanged,
    this.onEditEvent,
  });

  final List<DataItem<CheckinEvent>> events;
  final Map<String, int> monthlyCounts;
  final Set<String> selectedEventIds;
  final ValueChanged<Set<String>> onFilterChanged;
  final ValueChanged<DataItem<CheckinEvent>>? onEditEvent;

  bool get _isShowingAll =>
      selectedEventIds.isEmpty || selectedEventIds.length == events.length;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemCount: events.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            // "全部" 标签
            final isAllActive = _isShowingAll;
            return FilterChip(
              label: const Text('全部'),
              selected: isAllActive,
              showCheckmark: false,
              selectedColor: theme.colorScheme.primaryContainer,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: isAllActive ? FontWeight.bold : FontWeight.normal,
                color: isAllActive
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
              onSelected: (_) {
                if (isAllActive) {
                  // 保持全部
                  onFilterChanged(events.map((e) => e.id).toSet());
                } else {
                  // 恢复全部
                  onFilterChanged(events.map((e) => e.id).toSet());
                }
              },
            );
          }

          final eventItem = events[index - 1];
          final event = eventItem.body;
          final eventColor = Color(event.colorValue);
          final count = monthlyCounts[eventItem.id] ?? 0;
          final isSelected = !_isShowingAll && selectedEventIds.contains(eventItem.id);

          return GestureDetector(
            onLongPress: onEditEvent != null ? () => onEditEvent!(eventItem) : null,
            child: FilterChip(
              showCheckmark: false,
              selected: isSelected || _isShowingAll,
              selectedColor: isSelected
                  ? eventColor.withValues(alpha: 0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              side: BorderSide(
                color: isSelected
                    ? eventColor
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: isSelected ? 1.5 : 1,
              ),
              avatar: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: eventColor,
                  shape: BoxShape.circle,
                ),
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: eventColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count次',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: eventColor,
                      ),
                    ),
                  ),
                ],
              ),
              onSelected: (selected) {
                if (_isShowingAll) {
                  // 从全部切换为仅查看当前事件
                  onFilterChanged({eventItem.id});
                } else {
                  final newSet = Set<String>.from(selectedEventIds);
                  if (newSet.contains(eventItem.id)) {
                    newSet.remove(eventItem.id);
                  } else {
                    newSet.add(eventItem.id);
                  }
                  if (newSet.isEmpty || newSet.length == events.length) {
                    onFilterChanged(events.map((e) => e.id).toSet());
                  } else {
                    onFilterChanged(newSet);
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }
}
