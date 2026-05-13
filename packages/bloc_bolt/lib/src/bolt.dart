import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_bolt/src/observer.dart';

/// Bolt simple Bloc implementation ,
/// simple and fast , without the overhead
abstract class Bolt<Event extends Object, State> extends BlocBase<State> {
  ///
  Bolt(State initialState) : super(initialState);

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

  /// Adds a new [event] to be processed by the [Bolt].
  void add(Event event) {
    actionObserver(this, event);

    try {
      final result = onEvent(event);
      if (result is Future) {
        result.catchError(addError);
      }
    } catch (e, s) {
      addError(e, s);
      errorObserver(this, e, s);
    }
  }

  /// must be implemented by the user to handle incoming events and emit new states
  FutureOr<void> onEvent(Event event);
}
