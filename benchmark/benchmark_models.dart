import 'dart:async';
import 'package:meta/meta.dart';

/// Base class for all bloc implementations
abstract class BlocBase<State> {
  BlocBase(this._state) {
    _blocObserver.onCreate(this);
  }

  final _blocObserver = BlocObserver.observer;

  late final _stateController = StreamController<State>.broadcast();

  State _state;

  bool _emitted = false;

  @override
  State get state => _state;

  @override
  Stream<State> get stream => _stateController.stream;

  @override
  bool get isClosed => _stateController.isClosed;

  @override
  void emit(State state) {
    try {
      if (isClosed) {
        throw StateError('Cannot emit new states after calling close');
      }
      if (state == _state && _emitted) return;
      onChange(Change<State>(currentState: this.state, nextState: state));
      _state = state;
      _stateController.add(_state);
      _emitted = true;
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      rethrow;
    }
  }

  @protected
  @mustCallSuper
  void onChange(Change<State> change) {
    _blocObserver.onChange(this, change);
  }

  @protected
  @mustCallSuper
  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    onError(error, stackTrace ?? StackTrace.current);
  }

  @protected
  @mustCallSuper
  void onError(Object error, StackTrace stackTrace) {
    _blocObserver.onError(this, error, stackTrace);
  }

  @mustCallSuper
  @override
  Future<void> close() async {
    _blocObserver.onClose(this);
    await _stateController.close();
  }
}

/// BlocObserver for benchmarking
class BlocObserver {
  static final BlocObserver observer = BlocObserver._();

  BlocObserver._();

  void onCreate(BlocBase<dynamic> bloc) {}

  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {}

  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {}

  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {}

  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {}

  void onDone(
    Bloc<dynamic, dynamic> bloc,
    Object? event, [
    Object? error,
    StackTrace? stackTrace,
  ]) {}

  void onClose(BlocBase<dynamic> bloc) {}
}

/// Transition class for benchmarking
@immutable
class Transition<Event, State> extends Change<State> {
  const Transition({
    required State currentState,
    required this.event,
    required State nextState,
  }) : super(currentState: currentState, nextState: nextState);

  final Event event;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transition<Event, State> &&
          runtimeType == other.runtimeType &&
          currentState == other.currentState &&
          event == other.event &&
          nextState == other.nextState;

  @override
  int get hashCode => Object.hashAll([currentState, event, nextState]);

  @override
  String toString() {
    return '''Transition { currentState: $currentState, event: $event, nextState: $nextState }''';
  }
}

/// Change class for benchmarking
@immutable
class Change<State> {
  const Change({required this.currentState, required this.nextState});

  final State currentState;
  final State nextState;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Change<State> &&
          runtimeType == other.runtimeType &&
          currentState == other.currentState &&
          nextState == other.nextState;

  @override
  int get hashCode => Object.hashAll([currentState, nextState]);

  @override
  String toString() {
    return 'Change { currentState: $currentState, nextState: $nextState }';
  }
}

/// Emitter interface for benchmarking
abstract class Emitter<State> {
  Future<void> onEach<T>(
    Stream<T> stream, {
    required void Function(T data) onData,
    void Function(Object error, StackTrace stackTrace)? onError,
  });

  Future<void> forEach<T>(
    Stream<T> stream, {
    required State Function(T data) onData,
    State Function(Object error, StackTrace stackTrace)? onError,
  });

  bool get isDone;

  void call(State state);
}

/// EventHandler type for benchmarking
typedef EventHandler<Event, State> = FutureOr<void> Function(
  Event event,
  Emitter<State> emit,
);

/// Cubit implementation for benchmarking - standalone version
abstract class Cubit<State> extends BlocBase<State> {
  Cubit(State initialState) : super(initialState);
}

/// Bloc implementation for benchmarking - standalone version (simplified)
abstract class Bloc<Event extends Object?, State> extends BlocBase<State> {
  Bloc(State initialState) : super(initialState);

  final _eventController = StreamController<Event>.broadcast();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _handlers = <_Handler>[];
  final _emitters = <_Emitter<dynamic>>[];

  void on<E extends Event>(EventHandler<E, State> handler) {
    assert(() {
      final handlerExists = _handlers.any((h) => h.type == E);
      if (handlerExists) {
        throw StateError(
          'on<$E> was called multiple times. '
          'There should only be a single event handler per event type.',
        );
      }
      _handlers.add(_Handler(isType: (dynamic e) => e is E, type: E));
      return true;
    }());

    final subscription = _eventController.stream
        .where((event) => event is E)
        .cast<E>()
        .listen((event) {
      void onEmit(State state) {
        if (isClosed) return;
        if (state == this.state && _emitted) return;
        onTransition(
          Transition(
            currentState: this.state,
            event: event,
            nextState: state,
          ),
        );
        emit(state);
      }

      final emitter = _Emitter(onEmit);
      final controller = StreamController<E>.broadcast(
        sync: true,
        onCancel: emitter.cancel,
      );

      Future<void> handleEvent() async {
        void tearDown() {
          emitter.complete();
          _emitters.remove(emitter);
          if (!controller.isClosed) controller.close();
        }

        try {
          _emitters.add(emitter);
          await handler(event, emitter);
          onDone(event);
        } catch (error, stackTrace) {
          onError(error, stackTrace);
          onDone(event, error, stackTrace);
          rethrow;
        } finally {
          tearDown();
        }
      }

      handleEvent();
    });
    _subscriptions.add(subscription);
  }

  @override
  void add(Event event) {
    assert(() {
      final handlerExists = _handlers.any((handler) => handler.isType(event));
      if (!handlerExists) {
        final eventType = event.runtimeType;
        throw StateError(
          '''add($eventType) was called without a registered event handler.\n'''
          '''Make sure to register a handler via on<$eventType>((event, emit) {...})''',
        );
      }
      return true;
    }());
    try {
      onEvent(event);
      _eventController.add(event);
    } catch (error, stackTrace) {
      onError(error, stackTrace);
      rethrow;
    }
  }

  @protected
  @mustCallSuper
  void onEvent(Event event) {}

  @protected
  @mustCallSuper
  void onTransition(Transition<Event, State> transition) {}

  @protected
  @mustCallSuper
  void onDone(Event event, [Object? error, StackTrace? stackTrace]) {}

  @override
  Future<void> close() async {
    await _eventController.close();
    for (final emitter in _emitters) {
      emitter.cancel();
    }
    await Future.wait<void>(_emitters.map((e) => e.future));
    await Future.wait<void>(_subscriptions.map((s) => s.cancel()));
    return super.close();
  }
}

class _Handler {
  const _Handler({required this.isType, required this.type});
  final bool Function(dynamic value) isType;
  final Type type;
}

class _Emitter<State> implements Emitter<State> {
  _Emitter(this._emit);

  final void Function(State state) _emit;
  final _completer = Completer<void>();
  final _disposables = <FutureOr<void> Function()>[];

  var _isCanceled = false;
  var _isCompleted = false;

  @override
  Future<void> onEach<T>(
    Stream<T> stream, {
    required void Function(T data) onData,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    final completer = Completer<void>();
    final subscription = stream.listen(
      onData,
      onDone: completer.complete,
      onError: onError ?? completer.completeError,
      cancelOnError: onError == null,
    );
    _disposables.add(subscription.cancel);
    return Future.any([future, completer.future]).whenComplete(() {
      subscription.cancel();
      _disposables.remove(subscription.cancel);
    });
  }

  @override
  Future<void> forEach<T>(
    Stream<T> stream, {
    required State Function(T data) onData,
    State Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return onEach<T>(
      stream,
      onData: (data) => call(onData(data)),
      onError: onError != null
          ? (Object error, StackTrace stackTrace) {
              call(onError(error, stackTrace));
            }
          : null,
    );
  }

  @override
  void call(State state) {
    assert(
      !_isCompleted,
      'emit was called after an event handler completed normally.',
    );
    if (!_isCanceled) _emit(state);
  }

  @override
  bool get isDone => _isCanceled || _isCompleted;

  void cancel() {
    if (isDone) return;
    _isCanceled = true;
    _close();
  }

  void complete() {
    if (isDone) return;
    assert(
      _disposables.isEmpty,
      'An event handler completed but left pending subscriptions behind.',
    );
    _isCompleted = true;
    _close();
  }

  void _close() {
    for (final disposable in _disposables) {
      disposable.call();
    }
    _disposables.clear();
    if (!_completer.isCompleted) _completer.complete();
  }

  Future<void> get future => _completer.future;
}
