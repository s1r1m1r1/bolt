import 'package:bloc/bloc.dart';

extension BoltObserverExt on BlocBase<dynamic> {
  static BoltObserver observer = const BoltObserver();

  /// directly inline , this will be tree shaken when method empty
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  ActionObserver get actionObserver => observer.onAction;

  /// directly inline , this will be tree shaken when method empty
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  // ignore: invalid_use_of_protected_member
  ErrorObserver get errorObserver => Bloc.observer.onError;
}

///
typedef ActionObserver = void Function(
    BlocBase<dynamic> blocBase, Object action);

///
typedef ErrorObserver = void Function(
    BlocBase<dynamic> blocBase, Object error, StackTrace stackTrace);

base class BoltObserver {
  const BoltObserver();

  /// empty , if not used will be tree shaken
  /// override if needed
  void onAction(BlocBase<dynamic> blocBase, Object action) {}
}
