import 'dart:async';

abstract class BoltBase<Event extends Object, State> {
  /// adds a new [event] to be processed by the [Bolt].
  void add(Event event);

  /// must be implemented by the user to handle incoming events and emit new states
  FutureOr<void> onEvent(Event event);
}
