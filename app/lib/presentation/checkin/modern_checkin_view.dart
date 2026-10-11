import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:xbb/core/theme/tokens.dart';
import 'package:xbb/data/repositories/checkin_repository.dart';
import 'package:xbb/models/checkin/model.dart';
import 'package:xbb/presentation/checkin/checkin_providers.dart';
import 'package:xbb/presentation/providers/auth_provider.dart';
import 'package:xbb/presentation/widgets/modern_widgets.dart';

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
    final userId = ref.watch(authProvider).userId;

    final selectedKey = CheckinRepository.formatLocalDayKey(_selectedDay);
    final todayKey = CheckinRepository.formatLocalDayKey(DateTime.now());
    final isFuture = selectedKey.compareTo(todayKey) > 0;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '习惯打卡',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: '新建打卡项目',
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateEventDialog(context),
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

          return CustomScrollView(
            slivers: [
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
                      availableCalendarFormats: const {
                        CalendarFormat.twoWeeks: '两周',
                        CalendarFormat.month: '月',
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
                      },
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, _) {
                          final dayKey = CheckinRepository.formatLocalDayKey(date);
                          final hasCheckin = records.any((r) => r.body.localDayKey == dayKey);
                          if (!hasCheckin) return null;
                          return Positioned(
                            bottom: 4,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
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
                        final eventItem = events[index];
                        final event = eventItem.body;
                        final isChecked = checkedEventIds.contains(eventItem.id);
                        final color = Color(event.colorValue);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ModernCard(
                            selected: isChecked,
                            onTap: isFuture
                                ? null
                                : () async {
                                    if (isChecked) {
                                      await ref.read(checkinRepositoryProvider).undoCheckin(
                                            eventId: eventItem.id,
                                            dayKey: selectedKey,
                                          );
                                    } else {
                                      await ref.read(checkinRepositoryProvider).checkin(
                                            eventId: eventItem.id,
                                            targetDate: _selectedDay,
                                            currentUserId: userId,
                                          );
                                    }
                                  },
                            child: Row(
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
                                    ],
                                  ),
                                ),
                                if (isChecked)
                                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24)
                                else
                                  Icon(
                                    Icons.radio_button_unchecked,
                                    color: theme.colorScheme.outlineVariant,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: events.length,
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

  void _showCreateEventDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int selectedColor = Colors.teal.value;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建习惯项目'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '习惯名称', isDense: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: '描述或目标 (可选)', isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final userId = ref.read(authProvider).userId;
                ref.read(checkinRepositoryProvider).createEvent(
                      name: nameCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      colorValue: selectedColor,
                      currentUserId: userId,
                    );
              }
              Navigator.pop(ctx);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}
