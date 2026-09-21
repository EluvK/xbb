import 'package:flutter_test/flutter_test.dart';
import 'package:xbb/models/task/model.dart';

void main() {
  group('Task Archive Logic Tests', () {
    test('filters completed and remaining tasks correctly', () {
      final now = DateTime.now();
      final tasks = [
        TaskItem(id: '1', content: 'Task 1', done: false, lastModifiedAt: now, sortOrder: 0),
        TaskItem(id: '2', content: 'Task 2', done: true, doneAt: now, lastModifiedAt: now, sortOrder: 1),
        TaskItem(id: '3', content: 'Task 3', done: false, lastModifiedAt: now, sortOrder: 2),
        TaskItem(id: '4', content: 'Task 4', done: true, doneAt: now, lastModifiedAt: now, sortOrder: 3),
      ];

      final hasCompleted = tasks.any((t) => t.done);
      expect(hasCompleted, isTrue);

      final completed = tasks.where((t) => t.done).toList();
      final remaining = tasks.where((t) => !t.done).toList();

      expect(completed.length, equals(2));
      expect(completed.map((t) => t.id).toList(), equals(['2', '4']));

      expect(remaining.length, equals(2));
      expect(remaining.map((t) => t.id).toList(), equals(['1', '3']));

      // Normalize sort order for remaining
      final normalizedRemaining = [
        for (var i = 0; i < remaining.length; i++) remaining[i].copyWith(sortOrder: i),
      ];
      expect(normalizedRemaining[0].sortOrder, equals(0));
      expect(normalizedRemaining[1].sortOrder, equals(1));
    });

    test('no completed tasks returns hasCompleted false', () {
      final now = DateTime.now();
      final tasks = [
        TaskItem(id: '1', content: 'Task 1', done: false, lastModifiedAt: now, sortOrder: 0),
        TaskItem(id: '2', content: 'Task 2', done: false, lastModifiedAt: now, sortOrder: 1),
      ];

      expect(tasks.any((t) => t.done), isFalse);
    });

    test('all tasks completed results in empty remaining workspace', () {
      final now = DateTime.now();
      final tasks = [
        TaskItem(id: '1', content: 'Task 1', done: true, doneAt: now, lastModifiedAt: now, sortOrder: 0),
        TaskItem(id: '2', content: 'Task 2', done: true, doneAt: now, lastModifiedAt: now, sortOrder: 1),
      ];

      final completed = tasks.where((t) => t.done).toList();
      final remaining = tasks.where((t) => !t.done).toList();

      expect(completed.length, equals(2));
      expect(remaining, isEmpty);

      final encodedWorkspace = encodeTaskItems(remaining);
      expect(encodedWorkspace, equals('[]'));
    });
  });
}
