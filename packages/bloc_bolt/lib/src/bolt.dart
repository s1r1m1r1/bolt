import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bolt_core/bolt_core.dart';

/// Bolt simple Bloc implementation ,
/// simple and fast , without the overhead
abstract class Bolt<Event extends Object, State> extends BlocBase<State>
    implements BoltBase<Event, State> {
  ///
  Bolt(State initialState) : super(initialState);

  /// directly inline , this will be tree shaken when method empty
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  ActionObserver get _actionObserver => BoltBase.observer.onAction;

  /// Adds a new [event] to be processed by the [Bolt].
  void add(Event event) {
    _actionObserver(this, event);

    try {
      final result = onEvent(event);
      if (result is Future) {
        result.catchError(addError);
      }
    } catch (e, s) {
      addError(e, s);
    }
  }

  /// must be implemented by the user to handle incoming events and emit new states
  FutureOr<void> onEvent(Event event);
}
