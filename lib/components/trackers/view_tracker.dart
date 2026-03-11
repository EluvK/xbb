import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/tracker/model.dart';

class ViewTracker extends StatelessWidget {
  const ViewTracker({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed('/tracker/edit-tracker', arguments: [null]);
        },
        child: const Icon(Icons.add),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 4.0),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
        child: const TrackerMatrix(),
      ),
    );
  }
}

extension on _TrackerMatrixState {
  Widget _buildEventWidget(TrackerConfig config, List<TrackerRecordDataItem> records, Color color) {
    return config.map(
      event: (c) {
        if (c.periodDays == null) {
          return Text('No period', style: Theme.of(context).textTheme.bodySmall);
        }
        final period = c.periodDays!;
        DateTime now = DateTime.now();
        DateTime? last;
        if (records.isNotEmpty) {
          records.sort((a, b) => b.body.timestamp.compareTo(a.body.timestamp));
          last = records.first.body.timestamp.toLocal();
        }
        final daysSince = last == null ? 9999 : now.difference(last).inDays;
        final progress = (daysSince / period).clamp(0.0, 1.0);
        final barColor = Color.lerp(Colors.green, Colors.red, progress) ?? color;
        final label = last == null ? 'Never done' : '$daysSince days ago';
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
  }

  Widget _buildMilestoneWidget(TrackerConfig config, List<TrackerRecordDataItem> records, Color color) {
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
        final barColor = Color.lerp(Colors.red, Colors.green, progress) ?? color;
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
  }

  Widget _buildAnniversaryWidget(TrackerConfig config, Color color) {
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
}

class TrackerMatrix extends StatefulWidget {
  const TrackerMatrix({super.key});

  @override
  State<TrackerMatrix> createState() => _TrackerMatrixState();
}

class _TrackerMatrixState extends State<TrackerMatrix> {
  final TrackerController trackerController = Get.find<TrackerController>();
  final TrackerRecordController recordController = Get.find<TrackerRecordController>();
  @override
  Widget build(BuildContext context) {
    final List<TrackerDataItem> trackers = trackerController.getTrackerDetails(selector: (t) => t);
    Color colorForType(BuildContext ctx, String type) {
      switch (type) {
        case 'event':
          return Colors.green;
        case 'milestone':
          return Colors.blueAccent;
        case 'anniversary':
          return Colors.pink;
        default:
          return Colors.teal;
      }
    }

    IconData iconForType(String type) {
      switch (type) {
        case 'milestone':
          return Icons.flag;
        case 'anniversary':
          return Icons.calendar_month_outlined;
        default:
          return Icons.repeat;
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
      itemCount: trackers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = trackers[index];
        final t = item.body;
        // fetch records for this tracker (parentId == tracker id)
        final List<TrackerRecordDataItem> records = recordController.getTrackerRecordDetails(
          selector: (r) => r,
          filters: [ParentIdFilter(item.id)],
        );
        final typeColor = colorForType(context, t.type);
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: InkWell(
            onTap: () => Get.toNamed('/tracker/edit-tracker', arguments: [item]),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: Icon(iconForType(t.type), color: typeColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
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
                              child: Text(
                                t.type,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: typeColor),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // type-specific widget
                        if (t.type == 'milestone')
                          _buildMilestoneWidget(t.config, records, typeColor)
                        else if (t.type == 'anniversary')
                          _buildAnniversaryWidget(t.config, typeColor)
                        else
                          _buildEventWidget(t.config, records, typeColor),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') Get.toNamed('/tracker/edit-tracker', arguments: [item]);
                      if (v == 'delete') {
                        // deletion flow: repository method exists on controller
                        try {
                          trackerController.deleteData(item.id);
                        } catch (_) {
                          // ignore for now; controller may expose other APIs
                        }
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
