import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/models/tracker/model.dart';
import 'package:xbb/utils/double_click.dart';
import 'package:xbb/utils/list_tile_card.dart';

class TrackerCard extends StatefulWidget {
  const TrackerCard({super.key, required this.item, required this.records});
  final RxList<TrackerRecordDataItem> records;
  final TrackerDataItem item;

  @override
  State<TrackerCard> createState() => _TrackerCardState();
}

class _TrackerCardState extends State<TrackerCard> {
  bool _showActions = false;
  Timer? _actionsAutoHideTimer;

  void _toggleActions() {
    setState(() {
      _showActions = !_showActions;
    });

    if (_showActions) {
      _actionsAutoHideTimer?.cancel();
      _actionsAutoHideTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _showActions = false;
        });
      });
    } else {
      _actionsAutoHideTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _actionsAutoHideTimer?.cancel();
    super.dispose();
  }

  Widget _buildEventWidget(BuildContext context, TrackerConfig config) {
    return Obx(() {
      return config.map(
        event: (c) {
          DateTime now = DateTime.now();
          DateTime? last;
          if (widget.records.isNotEmpty) {
            final sortedRecords = widget.records.toList()..sort((a, b) => b.body.timestamp.compareTo(a.body.timestamp));
            last = sortedRecords.first.body.timestamp.toLocal();
          }
          final daysSince = last == null ? 9999 : now.difference(last).inDays;
          final label = last == null
              ? 'tracker_never_done'.tr
              : 'tracker_days_ago'.trParams({'days': daysSince.toString()});
          final period = c.periodDays;
          if (period <= 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              ],
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
              const SizedBox(height: 4),
              Text(
                '$label • ${'tracker_period_days'.trParams({'days': period.toString()})}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
            if (widget.records.isNotEmpty) {
              final trueCount = widget.records.where((r) => r.body.value == 'true').length;
              progress = widget.records.isEmpty ? 0.0 : (trueCount / widget.records.length);
            }
          } else if (goalType == 'number') {
            double sum = 0.0;
            for (var r in widget.records) {
              sum += double.tryParse(r.body.value ?? '') ?? 0.0;
            }
            if (target > 0) progress = (sum / target).clamp(0.0, 1.0);
          } else if (goalType == 'time') {
            Duration total = Duration.zero;
            for (var r in widget.records) {
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
              const SizedBox(height: 4),
              Text(
                '$displayPercent% • ${'tracker_target_value'.trParams({'value': c.targetValue})}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
          final info = daysUntil == 0
              ? 'tracker_today'.tr
              : (daysUntil > 0
                    ? 'tracker_in_days'.trParams({'days': daysUntil.toString()})
                    : 'tracker_passed_days'.trParams({'days': (-daysUntil).toString()}));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cake, color: color, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      info,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'tracker_since_base_days'.trParams({'days': daysSince.toString()}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        } else if (c.remindType == 'per_100_days') {
          final total = DateTime.now().difference(base).inDays;
          final next = ((total / 100).ceil()) * 100;
          final until = next - total;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'tracker_passed_days'.trParams({'days': total.toString()}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'tracker_next_at_days'.trParams({'next': next.toString(), 'until': until.toString()}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        } else {
          final days = now.difference(base).inDays;
          final tLabel = days >= 0
              ? 'tracker_passed_days'.trParams({'days': days.toString()})
              : 'tracker_in_days'.trParams({'days': (-days).toString()});
          final baseDateLabel =
              '${base.year}-${base.month.toString().padLeft(2, '0')}-${base.day.toString().padLeft(2, '0')}';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(tLabel, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'tracker_base_date_value'.trParams({'date': baseDateLabel}),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var showItem = widget.item;
    final TrackerController trackerController = Get.find<TrackerController>();
    final t = widget.item.body;
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

    var card = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // surfaceTintColor: showItem.colorTag.toColor() == Colors.transparent
      //     ? null
      //     : showItem.colorTag.toColor()?.withAlpha(132),
      elevation: 2,
      child: InkWell(
        onTap: () => Get.toNamed('/tracker/view-tracker', arguments: [widget.item]),
        onLongPress: () => {
          // pop up delete confirmation
          Get.defaultDialog(
            title: 'tracker_delete_title'.tr,
            middleText: 'tracker_delete_confirm'.tr,
            textCancel: 'cancel'.tr,
            textConfirm: 'delete'.tr,
            confirmTextColor: Colors.white,
            onConfirm: () {
              Get.find<TrackerController>().deleteData(widget.item.id);
              Navigator.pop(context);
              while (Get.routing.current == '/tracker/view-tracker') {
                Navigator.pop(context);
              }
            },
          ),
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // if (showItem.colorTag != ColorTag.none)
                //   Icon(Icons.brightness_1_rounded, color: showItem.colorTag.toColor(), size: 16),
                SizedBox(
                  width: 60,
                  child: Center(
                    child: InkWell(
                      onTap: _toggleActions,
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.12), shape: BoxShape.circle),
                            child: Icon(typeIcon, color: typeColor, size: 28),
                          ),
                          if (widget.item.syncStatus == SyncStatus.syncing)
                            const Positioned(
                              right: -4,
                              top: -4,
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _showActions
                        ? Container(
                            key: const ValueKey('actions'),
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  tooltip: 'edit'.tr,
                                  onPressed: () {
                                    Get.toNamed('/tracker/edit-tracker', arguments: [widget.item]);
                                  },
                                  icon: const Icon(Icons.edit),
                                ),
                                InlineColorPickerButton(
                                  value: widget.item.colorTag,
                                  onSelected: (color) {
                                    trackerController.onUpdateLocalField(widget.item.id, colorTag: color);
                                    setState(() {
                                      showItem.colorTag = color;
                                    });
                                  },
                                ),
                                DoubleClickButton(
                                  buttonBuilder: (onPressed) => IconButton(
                                    tooltip: 'delete'.tr,
                                    onPressed: onPressed,
                                    icon: const Icon(Icons.delete),
                                  ),
                                  onDoubleClick: () {
                                    trackerController.deleteData(widget.item.id);
                                    while (Get.routing.current == '/tracker/view-tracker') {
                                      Navigator.pop(context);
                                    }
                                  },
                                  firstClickHint: 'delete_tracker'.tr,
                                  upperPosition: true,
                                ),
                              ],
                            ),
                          )
                        : Column(
                            key: const ValueKey('content'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (t.description.isNotEmpty)
                                    Text(
                                      t.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: 4,
          right: 4,
          child: Row(
            children: [
              if (showItem.colorTag != ColorTag.none)
                Icon(Icons.brightness_1_rounded, color: showItem.colorTag.toColor(), size: 14),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 96),
                  child: Text(
                    t.type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: typeColor),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Positioned(
        //   bottom: 12,
        //   right: 4,
        //   child: Row(
        //     children: [
        //       IconButton(
        //         tooltip: 'edit'.tr,
        //         onPressed: () {
        //           Get.toNamed('/tracker/edit-tracker', arguments: [widget.item]);
        //         },
        //         icon: const Icon(Icons.edit),
        //       ),
        //       InlineColorPickerButton(
        //         value: widget.item.colorTag,
        //         onSelected: (color) {
        //           trackerController.onUpdateLocalField(widget.item.id, colorTag: color);
        //           setState(() {
        //             showItem.colorTag = color;
        //           });
        //         },
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
