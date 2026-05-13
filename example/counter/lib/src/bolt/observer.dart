import 'bolt_base.dart';

base class BoltObserver {
  const BoltObserver();

  /// empty , if not used will be tree shaken
  /// override if needed
  ///
  void onAction(BoltBase<dynamic, dynamic> boltBase, Object action) {}

  /// empty , if not used will be tree shaken
  /// override if needed
  void finest(BoltBase<dynamic, dynamic> boltBase, String message) {}

  /// empty , if not used will be tree shaken
  /// override if needed
  void finer(BoltBase<dynamic, dynamic> boltBase, String message) {}

  /// empty , if not used will be tree shaken
  /// override if needed
  void fine(BoltBase<dynamic, dynamic> boltBase, String message) {}

  /// empty , if not used will be tree shaken
  /// override if needed
  void info(BoltBase<dynamic, dynamic> boltBase, String message) {}

  /// empty , if not used will be tree shaken
  /// override if needed
  void warning(BoltBase<dynamic, dynamic> boltBase, String message) {}

  /// empty , if not used will be tree shaken
  /// override if needed
  void severe(BoltBase<dynamic, dynamic> boltBase, String message) {}

  void onError(
    BoltBase<dynamic, dynamic> boltBase,
    Object error,
    StackTrace stackTrace,
  ) {}
}

/// typedefs for observers and loggers
typedef ActionObserver = void Function(
    BoltBase<dynamic, dynamic> blocBase, Object action);

typedef ErrorObserver = void Function(
  BoltBase<dynamic, dynamic> blocBase,
  Object error,
  StackTrace stackTrace,
);

typedef FinerObserver = void Function(
    BoltBase<dynamic, dynamic> blocBase, String message);

typedef FinestObserver = void Function(
    BoltBase<dynamic, dynamic> blocBase, String message);

typedef FineObserver = void Function(
    BoltBase<dynamic, dynamic> blocBase, String message);

typedef InfoObserver = void Function(
    BoltBase<dynamic, dynamic> blocBase, String message);

typedef WarningObserver = void Function(
    BoltBase<dynamic, dynamic> blocBase, String message);

typedef SevereObserver = void Function(
    BoltBase<dynamic, dynamic> blocBase, String message);

typedef Log = void Function(String message);
