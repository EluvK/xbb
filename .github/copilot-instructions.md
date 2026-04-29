# Instructions

## Scope and repo layout
- Primary app is `xbb/` (Flutter + GetX + local SQLite sync cache).
- Local workspace package `../syncstore_client/` provides a sync protocol with code generator to help model definition.

## Architecture
- Each feature(example: Note/Tracker/Task) has a domain model which can be found in `lib/models/...` with a `model.dart` file using code generation annotations. The generated code includes repositories, controllers, and sync engines. Also has corresponding UI in `lib/components/...` which reads from controllers and triggers sync explicitly.

## Generated-code workflow (critical)
- Do not hand-edit generated files: `lib/models/notes/model.g.dart`, `lib/models/notes/model.freezed.dart`.
- When changing model fields/annotations in `model.dart`, regenerate with: `flutter pub run build_runner build --delete-conflicting-outputs`

## Implementation patterns to follow
- UI components should need to refresh data automatically when controller state changes (using GetX's reactive state management).
