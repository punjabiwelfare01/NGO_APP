// Conditional export: Dart picks the right file at compile time.
//   dart.library.html  → web browser build  → auth0_strategy_web.dart
//   dart.library.io    → Android / iOS      → auth0_strategy_io.dart
export 'auth0_strategy_stub.dart'
    if (dart.library.html) 'auth0_strategy_web.dart'
    if (dart.library.io) 'auth0_strategy_io.dart';
