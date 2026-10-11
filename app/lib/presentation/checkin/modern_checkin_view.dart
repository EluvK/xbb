import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/data/repositories/checkin_repository.dart';
import 'package:xbb/models/checkin/model.dart';
import 'package:xbb/presentation/checkin/checkin_providers.dart';
import 'package:xbb/presentation/checkin/edit_checkin_event_dialog.dart';
import 'package:xbb/presentation/checkin/event_filter_bar.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';
import 'package:xbb/utils/translation.dart';

class ModernCheckinView extends ConsumerStatefulWidget {
  const ModernCheckinView({super.key});

  @override
  ConsumerState<ModernCheckinView> createState() => _ModernCheckinViewState();
}

class _ModernCheckinViewState extends ConsumerState<ModernCheckinView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(checkinEventsStreamProvider);
    final recordsAsync = ref.watch(checkinRecordsStreamProvider);
    final monthlyCounts = ref.watch(checkinMonthlyCountsStreamProvider).value ?? {};
    final selectedFilterIds = ref.watch(checkinFilteredEventIdsProvider);
    final effectiveFilterIds = ref.watch(effectiveFilteredEventIdsProvider);
    final userId = ref.watch(authProvider).userId;

    final selectedKey = CheckinRepository.formatLocalDayKey(_selectedDay);
    final todayKey = CheckinRepository.formatLocalDayKey(DateTime.now());
    final isFuture = selectedKey.compareTo(todayKey) > 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'checkin_appbar_title'.tr,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'checkin_add_tooltip'.tr,
            icon: const Icon(Icons.add),
            onPressed: () => EditCheckinEventDialog.show(context),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: eventsAsync.when(
        data: (events) {
          final records = recordsAsync.value ?? [];
          final checkedEventIds = records
              .where((r) => r.body.localDayKey == selectedKey)
              .map((r) => r.body.eventId)
              .toSet();
          final displayedEvents = events.where((e) => effectiveFilterIds.contains(e.id)).toList();

          return CustomScrollView(
            slivers: [
              // 顶部事件横向过滤栏 (EventFilterBar)
              if (events.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: EventFilterBar(
                      events: events,
                      monthlyCounts: monthlyCounts,
                      selectedEventIds: selectedFilterIds,
                      onFilterChanged: (newSet) {
                        ref.read(checkinFilteredEventIdsProvider.notifier).state = newSet;
                      },
                      onEditEvent: (ev) => EditCheckinEventDialog.show(context, eventItem: ev),
                    ),
                  ),
                ),
              // 顶部现代日历卡片
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ModernCard(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      currentDay: DateTime.now(),
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      calendarFormat: CalendarFormat.twoWeeks,
                      availableCalendarFormats: {
                        CalendarFormat.twoWeeks: 'checkin_calendar_two_weeks'.tr,
                        CalendarFormat.month: 'checkin_calendar_month'.tr,
                      },
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        ref.read(checkinFocusedDayProvider.notifier).state = focusedDay;
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                        ref.read(checkinFocusedDayProvider.notifier).state = focusedDay;
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, _) {
                          final dayKey = CheckinRepository.formatLocalDayKey(date);
                          final dayRecords = records.where(
                            (r) => r.body.localDayKey == dayKey && effectiveFilterIds.contains(r.body.eventId),
                          ).toList();
                          if (dayRecords.isEmpty) return null;

                          // 提取不同打卡事件的专属颜色渲染多色彩点阵列
                          final matchedColors = <int>[];
                          final seenEventIds = <String>{};
                          for (final r in dayRecords) {
                            if (seenEventIds.add(r.body.eventId)) {
                              for (final e in events) {
                                if (e.id == r.body.eventId) {
                                  matchedColors.add(e.body.colorValue);
                                  break;
                                }
                              }
                            }
                          }
                          if (matchedColors.isEmpty) return null;

                          return Positioned(
                            bottom: 4,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: matchedColors.map((colorVal) {
                                return Container(
                                  width: 5,
                                  height: 5,
                                  margin: const EdgeInsets.symmetric(horizontal: 0.8),
                                  decoration: BoxDecoration(
                                    color: Color(colorVal),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              // 选定日期提示
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedKey == todayKey ? '今日打卡 ($selectedKey)' : '选定日期 ($selectedKey)',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (isFuture)
                        const ModernBadge(
                          label: '未来日期不可打卡',
                          color: Colors.orange,
                        )
                      else
                        ModernBadge(
                          label: '已完成 ${checkedEventIds.length} / ${events.length}',
                          color: checkedEventIds.length == events.length && events.isNotEmpty
                              ? Colors.green
                              : theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              ),
              // 打卡事件列表
              if (events.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: ModernEmptyState(
                    icon: Icons.flag_circle_outlined,
                    title: '暂无打卡项目',
                    subtitle: '点击右上角 “+” 创建你的第一个习惯打卡项目',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final eventItem = displayedEvents[index];
                        final event = eventItem.body;
                        final recordItem = records.cast<DataItem<CheckinRecord>?>().firstWhere(
                              (r) => r?.body.eventId == eventItem.id && r?.body.localDayKey == selectedKey,
                              orElse: () => null,
                            );
                        final isChecked = recordItem != null;
                        final color = Color(event.colorValue);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ModernCard(
                            selected: isChecked,
                            onLongPress: isFuture
                                ? null
                                : (isChecked
                                    ? () => _showEditRecordDialog(context, recordItem, event.name)
                                    : () => _showCheckinWithNoteDialog(context, eventItem, event.name)),
                            onTap: () async {
                              if (isFuture) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('不能预打未来的日期'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              if (isChecked) {
                                _confirmUndoCheckin(context, eventItem.id, selectedKey, event.name);
                              } else {
                                final eventCreatedDayKey = CheckinRepository.formatLocalDayKey(eventItem.createdAt);
                                if (selectedKey.compareTo(eventCreatedDayKey) < 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('不能补打事件创建前的日期'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }
                                await ref.read(checkinRepositoryProvider).checkin(
                                      eventId: eventItem.id,
                                      targetDate: _selectedDay,
                                      currentUserId: userId,
                                    );
                              }
                            },
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.name,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (event.description.isNotEmpty)
                                        Text(
                                          event.description,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      if (isChecked &&
                                          recordItem.body.note != null &&
                                          recordItem.body.note!.trim().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.notes_rounded, size: 13, color: color),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    recordItem.body.note!,
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: theme.colorScheme.onSurface,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (isChecked) ...[
                                  Text(
                                    _formatTime(recordItem.body.createdAtUtc),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    tooltip: '编辑打卡记录',
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _showEditRecordDialog(context, recordItem, event.name),
                                  ),
                                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                                ] else
                                  Icon(
                                    Icons.radio_button_unchecked,
                                    color: theme.colorScheme.outlineVariant,
                                    size: 24,
                                  ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  tooltip: '更多操作',
                                  padding: EdgeInsets.zero,
                                  onSelected: (val) {
                                    if (val == 'edit_event') {
                                      EditCheckinEventDialog.show(context, eventItem: eventItem);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'edit_event',
                                      child: Row(
                                        children: [
                                          Icon(Icons.tune_rounded, size: 18),
                                          SizedBox(width: 8),
                                          Text('编辑习惯项目'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: displayedEvents.length,
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  String _formatTime(DateTime utcTime) {
    final local = utcTime.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showEditRecordDialog(
    BuildContext context,
    DataItem<CheckinRecord> recordItem,
    String eventName,
  ) {
    DateTime recordDateTime = recordItem.body.createdAtUtc.toLocal();
    final noteCtrl = TextEditingController(text: recordItem.body.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final timeStr =
              '${recordDateTime.hour.toString().padLeft(2, '0')}:${recordDateTime.minute.toString().padLeft(2, '0')}';
          return AlertDialog(
            title: Text('编辑记录 · $eventName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: const Text('打卡时间'),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(recordDateTime),
                      );
                      if (pickedTime != null) {
                        setDialogState(() {
                          recordDateTime = DateTime(
                            recordDateTime.year,
                            recordDateTime.month,
                            recordDateTime.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    },
                    child: Text(timeStr),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: '打卡备注',
                    hintText: '写点今天的感受或备注...',
                    isDense: true,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () async {
                  final text = noteCtrl.text.trim();
                  await ref.read(checkinRepositoryProvider).updateRecordDetails(
                        recordId: recordItem.id,
                        recordTime: recordDateTime,
                        note: text.isEmpty ? null : text,
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmUndoCheckin(
    BuildContext context,
    String eventId,
    String dayKey,
    String eventName,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('撤销打卡'),
        content: Text('确认撤销「$eventName」的打卡记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(checkinRepositoryProvider).undoCheckin(
                    eventId: eventId,
                    dayKey: dayKey,
                  );
            },
            child: const Text('撤销'),
          ),
        ],
      ),
    );
  }

  void _showCheckinWithNoteDialog(
    BuildContext context,
    DataItem<CheckinEvent> eventItem,
    String eventName,
  ) {
    final eventCreatedDayKey = CheckinRepository.formatLocalDayKey(eventItem.createdAt);
    final selectedKey = CheckinRepository.formatLocalDayKey(_selectedDay);
    if (selectedKey.compareTo(eventCreatedDayKey) < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('不能补打事件创建前的日期'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    DateTime recordDateTime = DateTime.now();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final timeStr =
              '${recordDateTime.hour.toString().padLeft(2, '0')}:${recordDateTime.minute.toString().padLeft(2, '0')}';
          return AlertDialog(
            title: Text('打卡 · $eventName'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: const Text('记录时间'),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      final pickedTime = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(recordDateTime),
                      );
                      if (pickedTime != null) {
                        setDialogState(() {
                          recordDateTime = DateTime(
                            _selectedDay.year,
                            _selectedDay.month,
                            _selectedDay.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    },
                    child: Text(timeStr),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: '文字备注 (可选)',
                    hintText: '今日跑步 5 公里，状态良好...',
                    isDense: true,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () async {
                  final userId = ref.read(authProvider).userId;
                  final text = noteCtrl.text.trim();
                  await ref.read(checkinRepositoryProvider).checkin(
                        eventId: eventItem.id,
                        targetDate: _selectedDay,
                        currentUserId: userId,
                        note: text.isEmpty ? null : text,
                        recordTime: recordDateTime,
                      );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('打卡'),
              ),
            ],
          );
        },
      ),
    );
  }
}
