import 'package:flutter/material.dart';

class ViewTaskOverview extends StatelessWidget {
  const ViewTaskOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Task', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                SizedBox(height: 12),
                Text('Task 模块骨架已接入 Home。下一步将补齐本地数据读写与活跃段管理。'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
