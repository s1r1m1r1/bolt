import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bolt/src/observer.dart';

/// Bolt simple Bloc implementation ,
/// simple and fast , without the overhead
abstract class Bolt<Event extends Object, State> extends BlocBase<State> {
  ///
  Bolt(State initialState) : super(initialState);

  /// Adds a new [event] to be processed by the [Bolt].
  void add(Event event) {
    actionObserver(this, event);

    try {
      final result = onEvent(event);
      if (result is Future) {
        result.catchError(addError);
      }
    } catch (e, s) {
      errorObserver(this, e, s);
    }
  }

  /// must be implemented by the user to handle incoming events and emit new states
  FutureOr<void> onEvent(Event event);
}
