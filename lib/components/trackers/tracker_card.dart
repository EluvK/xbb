import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncstore_client/syncstore_client.dart';
import 'package:xbb/components/common/permission.dart';
import 'package:xbb/components/utils.dart';
import 'package:xbb/controller/user.dart';
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

  Widget _buildEventWidget(BuildContext context, TrackerConfig config, {double reserveRight = 0}) {
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
                Padding(
                  padding: EdgeInsets.only(right: reserveRight),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
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
              Padding(
                padding: EdgeInsets.only(right: reserveRight),
                child: Text(
                  '$label • ${'tracker_period_days'.trParams({'days': period.toString()})}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
        milestone: (c) => const SizedBox.shrink(),
        anniversary: (c) => const SizedBox.shrink(),
      );
    });
  }

  Widget _buildMilestoneWidget(BuildContext context, TrackerConfig config, {double reserveRight = 0}) {
    return Obx(() {
      return config.map(
        event: (c) => const SizedBox.shrink(),
        milestone: (c) {
          final goalType = c.goalType;
          final target = double.tryParse(c.targetValue) ?? 0.0;
          final progressMode = c.progressMode;
          final sortedRecords = widget.records.toList()..sort((a, b) => b.body.timestamp.compareTo(a.body.timestamp));
          final latestValue = sortedRecords.isNotEmpty ? sortedRecords.first.body.value : null;
          var displayTargetValue = c.targetValue;
          var displayCurrentValue = '0';
          double progress = 0.0;
          if (goalType == 'boolean') {
            if (progressMode == 'latest') {
              final latestDone = latestValue == 'true';
              progress = latestDone ? 1.0 : 0.0;
              displayCurrentValue = latestDone ? '1' : '0';
            } else if (widget.records.isNotEmpty) {
              final trueCount = widget.records.where((r) => r.body.value == 'true').length;
              progress = widget.records.isEmpty ? 0.0 : (trueCount / widget.records.length);
              displayCurrentValue = '$trueCount/${widget.records.length}';
            }
          } else if (goalType == 'number') {
            if (progressMode == 'latest') {
              final latest = double.tryParse(latestValue ?? '') ?? 0.0;
              if (target > 0) progress = (latest / target).clamp(0.0, 1.0);
              displayCurrentValue = latest
                  .toStringAsFixed(2)
                  .replaceFirst(RegExp(r'0+$'), '')
                  .replaceFirst(RegExp(r'\.$'), '');
            } else {
              double sum = 0.0;
              for (var r in widget.records) {
                sum += double.tryParse(r.body.value ?? '') ?? 0.0;
              }
              if (target > 0) progress = (sum / target).clamp(0.0, 1.0);
              displayCurrentValue = sum
                  .toStringAsFixed(2)
                  .replaceFirst(RegExp(r'0+$'), '')
                  .replaceFirst(RegExp(r'\.$'), '');
            }
          } else if (goalType == 'time') {
            final targetMinutes = target.toInt();
            final targetDuration = Duration(minutes: targetMinutes);
            if (progressMode == 'latest') {
              final latestMinutes = int.tryParse(latestValue ?? '') ?? 0;
              if (targetDuration.inMinutes > 0) {
                progress = (latestMinutes / targetDuration.inMinutes).clamp(0.0, 1.0);
              }
              final currentHours = latestMinutes / 60;
              final currentHourText = currentHours == currentHours.roundToDouble()
                  ? currentHours.toStringAsFixed(0)
                  : currentHours.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
              displayCurrentValue = 'tracker_hours_value'.trParams({'hours': currentHourText});
            } else {
              Duration total = Duration.zero;
              for (var r in widget.records) {
                final minutes = int.tryParse(r.body.value ?? '') ?? 0;
                total += Duration(minutes: minutes);
              }
              if (targetDuration.inMinutes > 0) progress = (total.inMinutes / targetDuration.inMinutes).clamp(0.0, 1.0);
              final currentHours = total.inMinutes / 60;
              final currentHourText = currentHours == currentHours.roundToDouble()
                  ? currentHours.toStringAsFixed(0)
                  : currentHours.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
              displayCurrentValue = 'tracker_hours_value'.trParams({'hours': currentHourText});
            }
            final hours = targetMinutes / 60;
            final hourText = hours == hours.roundToDouble()
                ? hours.toStringAsFixed(0)
                : hours.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
            displayTargetValue = 'tracker_hours_value'.trParams({'hours': hourText});
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
              Padding(
                padding: EdgeInsets.only(right: reserveRight),
                child: Text(
                  '$displayPercent% • ${'tracker_current_target_value'.trParams({'current': displayCurrentValue, 'target': displayTargetValue})}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
        anniversary: (c) => const SizedBox.shrink(),
      );
    });
  }

  Widget _buildAnniversaryWidget(BuildContext context, TrackerConfig config, Color color, {double reserveRight = 0}) {
    return config.map(
      event: (c) => const SizedBox.shrink(),
      milestone: (c) => const SizedBox.shrink(),
      anniversary: (c) {
        final base = c.baseDate.toLocal();
        final now = DateTime.now();
        if (c.remindType == 'per_year') {
          final today = DateTime(now.year, now.month, now.day);
          DateTime next = DateTime(today.year, base.month, base.day);
          if (next.isBefore(today)) next = DateTime(today.year + 1, base.month, base.day);
          final daysUntil = next.difference(today).inDays;
          final daysSinceBase = today.difference(DateTime(base.year, base.month, base.day)).inDays;
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
              Padding(
                padding: EdgeInsets.only(right: reserveRight),
                child: Text(
                  'tracker_since_base_days'.trParams({'days': daysSinceBase.toString()}),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
              Padding(
                padding: EdgeInsets.only(right: reserveRight),
                child: Text(
                  'tracker_passed_days'.trParams({'days': total.toString()}),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(right: reserveRight),
                child: Text(
                  'tracker_next_at_days'.trParams({'next': next.toString(), 'until': until.toString()}),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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
              Padding(
                padding: EdgeInsets.only(right: reserveRight),
                child: Text(
                  'tracker_base_date_value'.trParams({'date': baseDateLabel}),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Color _resolveTypeColor(String type) {
    return switch (type) {
      'event' => Colors.green,
      'milestone' => Colors.blueAccent,
      'anniversary' => Colors.pink,
      _ => Colors.teal,
    };
  }

  IconData _resolveTypeIcon(String type) {
    return switch (type) {
      'milestone' => Icons.flag,
      'anniversary' => Icons.calendar_month_outlined,
      _ => Icons.repeat,
    };
  }

  Widget _buildTypeBadge(
    BuildContext context, {
    required ThemeData theme,
    required String type,
    required Color typeColor,
    required Color typeTintBg,
    required Color typeTintEdge,
    required bool sharedFromOthers,
    required bool sharedToOthers,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: typeTintBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: typeTintEdge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (sharedFromOthers) ...[
            const RotatedBox(
              quarterTurns: 2,
              child: Icon(Icons.switch_access_shortcut_outlined, size: 12, color: Colors.blueAccent),
            ),
            const SizedBox(width: 3),
          ],
          if (sharedToOthers) ...[
            const Icon(Icons.switch_access_shortcut_outlined, size: 12, color: Colors.orangeAccent),
            const SizedBox(width: 3),
          ],
          Text(
            type,
            style: theme.textTheme.labelSmall?.copyWith(color: typeColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMetaBadge(BuildContext context, {required dynamic userProfile, required ColorTag colorTag}) {
    if (userProfile == null && colorTag == ColorTag.none) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (userProfile != null) ...[
            buildUserAvatar(context, userProfile.avatarUrl, size: 10, selected: false),
            if (colorTag != ColorTag.none) const SizedBox(width: 3),
          ],
          if (colorTag != ColorTag.none) Icon(Icons.circle, color: colorTag.toColor(), size: 7),
        ],
      ),
    );
  }

  Widget _buildTrackerContent(
    BuildContext context, {
    required ThemeData theme,
    required TrackerDataItem item,
    required Color typeColor,
    required Color typeTintBg,
    required Color typeTintEdge,
    required bool canEdit,
    required bool sharedFromOthers,
    required bool sharedToOthers,
    required dynamic userProfile,
  }) {
    final t = item.body;
    final progressWidget = switch (t.type) {
      'milestone' => _buildMilestoneWidget(context, t.config, reserveRight: canEdit ? 72 : 0),
      'anniversary' => _buildAnniversaryWidget(context, t.config, typeColor, reserveRight: canEdit ? 72 : 0),
      _ => _buildEventWidget(context, t.config, reserveRight: canEdit ? 72 : 0),
    };
    return Column(
      key: const ValueKey('content'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            _buildTypeBadge(
              context,
              theme: theme,
              type: t.type,
              typeColor: typeColor,
              typeTintBg: typeTintBg,
              typeTintEdge: typeTintEdge,
              sharedFromOthers: sharedFromOthers,
              sharedToOthers: sharedToOthers,
            ),
            if (userProfile != null || item.colorTag != ColorTag.none) ...[
              const SizedBox(width: 6),
              _buildTopMetaBadge(context, userProfile: userProfile, colorTag: item.colorTag),
            ],
          ],
        ),
        if (t.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            t.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 10),
        progressWidget,
      ],
    );
  }

  Widget _buildActionsPanel(
    BuildContext context, {
    required ThemeData theme,
    required TrackerController trackerController,
    required TrackerDataItem showItem,
  }) {
    return Container(
      key: const ValueKey('actions'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
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
            value: showItem.colorTag,
            onSelected: (color) {
              trackerController.onUpdateLocalField(widget.item.id, colorTag: color);
              setState(() {
                showItem.colorTag = color;
              });
            },
          ),
          DoubleClickButton(
            buttonBuilder: (onPressed) =>
                IconButton(tooltip: 'delete'.tr, onPressed: onPressed, icon: const Icon(Icons.delete)),
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
    );
  }

  Widget _buildBottomEditToggle(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _toggleActions,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                duration: const Duration(milliseconds: 180),
                turns: _showActions ? 0.125 : 0,
                child: Icon(
                  _showActions ? Icons.close_rounded : Icons.tune_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Text(_showActions ? 'cancel'.tr : 'edit'.tr, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showItem = widget.item;
    final TrackerController trackerController = Get.find<TrackerController>();
    final t = widget.item.body;
    final cachedAcl = trackerController.getAclCached(widget.item.id);
    final typeColor = _resolveTypeColor(t.type);
    final typeIcon = _resolveTypeIcon(t.type);
    final theme = Theme.of(context);
    final neutralBg = theme.colorScheme.surfaceContainerLow;
    final neutralBorder = theme.colorScheme.outlineVariant.withValues(alpha: 0.35);
    final typeTintBg = typeColor.withValues(alpha: 0.1);
    final typeTintEdge = typeColor.withValues(alpha: 0.28);
    final UserManagerController userCtrl = Get.find<UserManagerController>();
    final selfId = userCtrl.settingController.userId;
    final ownedId = widget.item.owner;
    final userProfile = userCtrl.getUserProfile(ownedId);
    final sharedToOthers = cachedAcl.any((p) => p.user != selfId);
    final sharedFromOthers = selfId != ownedId;
    final canEdit = oncePermissionCheck(TrackerFeatureRequires.update, ownedId, cachedAcl, null);

    var card = Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: neutralBg,
            border: Border.all(color: neutralBorder),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 96),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 76,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 60,
                    child: Center(
                      child: InkWell(
                        onTap: _toggleActions,
                        borderRadius: BorderRadius.circular(18),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: typeTintBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: typeTintEdge),
                                boxShadow: [
                                  BoxShadow(
                                    color: typeColor.withValues(alpha: 0.18),
                                    blurRadius: 12,
                                    spreadRadius: -4,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(typeIcon, color: typeColor, size: 28),
                            ),
                            if (widget.item.syncStatus == SyncStatus.syncing)
                              const Positioned(
                                right: -5,
                                top: -5,
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
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
                      child: Padding(
                        padding: EdgeInsets.only(bottom: canEdit ? 24 : 0),
                        child: _showActions
                            ? _buildActionsPanel(
                                context,
                                theme: theme,
                                trackerController: trackerController,
                                showItem: showItem,
                              )
                            : _buildTrackerContent(
                                context,
                                theme: theme,
                                item: widget.item,
                                typeColor: typeColor,
                                typeTintBg: typeTintBg,
                                typeTintEdge: typeTintEdge,
                                canEdit: canEdit,
                                sharedFromOthers: sharedFromOthers,
                                sharedToOthers: sharedToOthers,
                                userProfile: userProfile,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(bottom: 4, right: 8, child: canEdit ? _buildBottomEditToggle(context) : const SizedBox.shrink()),
      ],
    );
  }
}
