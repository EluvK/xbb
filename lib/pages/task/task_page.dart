import 'package:flutter/material.dart';

class TaskPage extends StatelessWidget {
  const TaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Task module scaffold is ready.\nNext step: DB and controller integration.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
