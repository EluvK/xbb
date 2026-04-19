import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PingLatencyInline extends StatelessWidget {
  const PingLatencyInline({
    super.key,
    required this.isLoading,
    required this.latencyMs,
    required this.onRefresh,
  });

  final bool isLoading;
  final int? latencyMs;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final text = latencyMs == null ? '-- ms' : '$latencyMs ms';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                )
              : Icon(Icons.network_ping_rounded, size: 18, color: color),
        ),
      ],
    );
  }
}
