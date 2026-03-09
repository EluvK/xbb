import 'package:flutter/material.dart';

class EditTrackerPage extends StatelessWidget {
  const EditTrackerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Tracker')),
      body: const Center(child: Text('Tracker editing UI goes here')),
    );
  }
}
