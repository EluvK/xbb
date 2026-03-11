import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/tracker/model.dart';

class TrackerCard extends StatelessWidget {
  const TrackerCard({super.key, required this.item, required this.records});
  final RxList<TrackerRecordDataItem> records;
  final TrackerDataItem item;

  Widget _buildEventWidget(BuildContext context, TrackerConfig config) {
    return Obx(() {
      return config.map(
        event: (c) {
          DateTime now = DateTime.now();
          DateTime? last;
          if (records.isNotEmpty) {
            records.sort((a, b) => b.body.timestamp.compareTo(a.body.timestamp));
            last = records.first.body.timestamp.toLocal();
          }
          final daysSince = last == null ? 9999 : now.difference(last).inDays;
          final label = last == null ? 'Never done' : '$daysSince days ago';
          final period = c.periodDays;
          if (period <= 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(label, style: Theme.of(context).textTheme.bodySmall)],
            );
          }
          // is a countdown if period > 0, otherwise count up
          final progress = 1 - (daysSince / period).clamp(0.0, 1.0);
          final barColor = Color.lerp(Colors.red, Colors.green, progress)!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: progress,
                color: barColor,
                backgroundColor: barColor.withValues(alpha: 0.14),
              ),
              const SizedBox(height: 6),
              Text('$label • Period: $period days', style: Theme.of(context).textTheme.bodySmall),
            ],
          );
        },
        milestone: (c) => const SizedBox.shrink(),
        anniversary: (c) => const SizedBox.shrink(),
      );
    });
  }

  Widget _buildMilestoneWidget(BuildContext context, TrackerConfig config) {
    return Obx(() {
      return config.map(
        event: (c) => const SizedBox.shrink(),
        milestone: (c) {
          final goalType = c.goalType;
          final target = double.tryParse(c.targetValue) ?? 0.0;
          double progress = 0.0;
          if (goalType == 'boolean') {
            if (records.isNotEmpty) {
              final trueCount = records.where((r) => r.body.value == 'true').length;
              progress = records.isEmpty ? 0.0 : (trueCount / records.length);
            }
          } else if (goalType == 'number') {
            double sum = 0.0;
            for (var r in records) {
              sum += double.tryParse(r.body.value ?? '') ?? 0.0;
            }
            if (target > 0) progress = (sum / target).clamp(0.0, 1.0);
          } else if (goalType == 'time') {
            Duration total = Duration.zero;
            for (var r in records) {
              final minutes = int.tryParse(r.body.value ?? '') ?? 0;
              total += Duration(minutes: minutes);
            }
            final targetDuration = Duration(minutes: target.toInt());
            if (targetDuration.inMinutes > 0) progress = (total.inMinutes / targetDuration.inMinutes).clamp(0.0, 1.0);
          }
          final displayPercent = (progress * 100).toStringAsFixed(0);
          final barColor = Color.lerp(Colors.red, Colors.green, progress)!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: progress,
                color: barColor,
                backgroundColor: barColor.withValues(alpha: 0.18),
              ),
              const SizedBox(height: 6),
              Text('$displayPercent% • Target: ${c.targetValue}', style: Theme.of(context).textTheme.bodySmall),
            ],
          );
        },
        anniversary: (c) => const SizedBox.shrink(),
      );
    });
  }

  Widget _buildAnniversaryWidget(BuildContext context, TrackerConfig config, Color color) {
    return config.map(
      event: (c) => const SizedBox.shrink(),
      milestone: (c) => const SizedBox.shrink(),
      anniversary: (c) {
        final base = c.baseDate.toLocal();
        final now = DateTime.now();
        if (c.remindType == 'per_year') {
          DateTime next = DateTime(now.year, base.month, base.day);
          if (!next.isAfter(now)) next = DateTime(now.year + 1, base.month, base.day);
          final last = DateTime(next.year - 1, base.month, base.day);
          final daysUntil = next.difference(now).inDays;
          final daysSince = now.difference(last).inDays;
          final info = daysUntil == 0 ? 'Today' : (daysUntil > 0 ? 'In $daysUntil days' : 'Passed ${-daysUntil} days');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cake, color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(info, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 6),
              Text('Since base: $daysSince days', style: Theme.of(context).textTheme.bodySmall),
            ],
          );
        } else if (c.remindType == 'per_100_days') {
          final total = DateTime.now().difference(base).inDays;
          final next = ((total / 100).ceil()) * 100;
          final until = next - total;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Passed $total days', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Text('Next at $next days (in $until days)', style: Theme.of(context).textTheme.bodySmall),
            ],
          );
        } else {
          final days = now.difference(base).inDays;
          return Text('T ${days >= 0 ? '+$days' : days.toString()}', style: Theme.of(context).textTheme.bodySmall);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = item.body;
    final typeColor = (() {
      switch (t.type) {
        case 'event':
          return Colors.green;
        case 'milestone':
          return Colors.blueAccent;
        case 'anniversary':
          return Colors.pink;
        default:
          return Colors.teal;
      }
    })();
    final typeIcon = (() {
      switch (t.type) {
        case 'milestone':
          return Icons.flag;
        case 'anniversary':
          return Icons.calendar_month_outlined;
        default:
          return Icons.repeat;
      }
    })();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => Get.toNamed('/tracker/view-tracker', arguments: [item]),
        onLongPress: () => {
          // pop up delete confirmation
          Get.defaultDialog(
            title: 'Delete Tracker',
            middleText: 'Are you sure you want to delete this tracker?',
            textCancel: 'Cancel',
            textConfirm: 'Delete',
            confirmTextColor: Colors.white,
            onConfirm: () {
              Get.find<TrackerController>().deleteData(item.id);
              Get.back();
            },
          ),
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          child: Row(
            children: [
              Column(
                children: [
                  // todo add sync status indicator here if needed
                  if (item.syncStatus == SyncStatus.syncing)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(typeIcon, color: typeColor, size: 28),
                  ),
                  IconButton(
                    onPressed: () {
                      Get.toNamed('/tracker/edit-tracker', arguments: [item]);
                    },
                    icon: const Icon(Icons.edit),
                  ),
                  // todo color tag button?
                  // delete button use double click.
                  // IconButton(
                  //   onPressed: () {
                  //     Get.find<TrackerController>().deleteData(item.id);
                  //   },
                  //   icon: const Icon(Icons.delete),
                  // ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(child: Text(t.category, style: Theme.of(context).textTheme.bodySmall)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(t.type, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: typeColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (t.type == 'milestone')
                      _buildMilestoneWidget(context, t.config)
                    else if (t.type == 'anniversary')
                      _buildAnniversaryWidget(context, t.config, typeColor)
                    else
                      _buildEventWidget(context, t.config),
                  ],
                ),
              ),
              // Column(children: [                ],),
            ],
          ),
        ),
      ),
    );
  }
}
