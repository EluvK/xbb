import 'package:flutter/material.dart';
import 'package:xbb/utils/translation.dart';

class PingLatencyInline extends StatelessWidget {
  const PingLatencyInline({super.key, required this.isLoading, required this.latencyMs, required this.onRefresh});

  final bool isLoading;
  final int? latencyMs;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isOnline = latencyMs != null && latencyMs! >= 0;
    final color = isOnline ? Colors.green : theme.colorScheme.onSurfaceVariant;
    final text = switch (latencyMs) {
      final ms? when ms >= 0 => '$ms ms',
      _ => '-- ms',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLoading
                ? Colors.amber
                : (isOnline ? Colors.green : theme.colorScheme.error),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(width: 2),
        IconButton(
          tooltip: isLoading ? 'ping_latency_testing'.tr : 'ping_latency_test'.tr,
          onPressed: onRefresh,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          icon: isLoading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)),
                )
              : Icon(Icons.network_ping_rounded, size: 18, color: theme.colorScheme.primary),
        ),
      ],
    );
  }
}
