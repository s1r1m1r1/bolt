import 'dart:async';

import 'package:bolt_core/bolt_core.dart';
import 'package:bolt_core/bolt_core.dart' as core;
import 'package:state_notifier/state_notifier.dart';

/// Bolt simple Event driven state management based on state_notifier,
/// simple and fast , without the overhead
abstract class BoltStateNotifier<Event extends Object, State>
    extends StateNotifier<State>
    implements BoltBase<Event, State> {
  ///
  BoltStateNotifier(State initialState) : super(initialState);

  /// directly inline , this will be tree shaken when method empty
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  core.ActionObserver get _actionObserver => BoltBase.observer.onAction;

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  core.ErrorObserver get _errorObserver => BoltBase.observer.onError;

  /// Adds a new [event] to be processed by the [Bolt].
  void add(Event event) {
    _actionObserver(this, event);

    try {
      final result = onEvent(event);
      if (result is Future) {
        result.catchError(
          (error, stackTrace) => _errorObserver(this, error, stackTrace),
        );
      }
    } catch (e, s) {
      _errorObserver(this, e, s);
    }
  }

  /// must be implemented by the user to handle incoming events and emit new states
  FutureOr<void> onEvent(Event event);
}
