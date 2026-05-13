import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:riverpod/riverpod.dart';
import 'package:mobx/mobx.dart';
import 'package:state_notifier/state_notifier.dart';

abstract class Bolt<Event extends Object, State> extends BlocBase<State> {
  Bolt(super.initialState);

  void add(Event event) {
    try {
      final result = onEvent(event);
      if (result is Future) {
        result.catchError(addError);
      }
    } catch (e, s) {
      addError(e, s);
    }
  }

  FutureOr<void> onEvent(Event event);
}

/// Bolt simple Bloc implementation ,
/// simple and fast , without the overhead
abstract class BoltNotifier<Event extends Object, State>
    extends StateNotifier<State> {
  ///
  BoltNotifier(State initialState) : super(initialState);
  static BoltNotifierObserver observer = const BoltNotifierObserver();

  /// directly inline , this will be tree shaken when method empty
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  ActionObserver get actionObserver => observer.onAction;

  /// directly inline , this will be tree shaken when method empty
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  // ignore: invalid_use_of_protected_member
  ErrorObserver get errorObserver => observer.onError;

  /// Adds a new [event] to be processed by the [Bolt].
  void add(Event event) {
    actionObserver(this, event);

    try {
      final result = onEvent(event);
      if (result is Future) {
        result.catchError((e, s) => errorObserver(this, e, s));
      }
    } catch (e, s) {
      errorObserver(this, e, s);
    }
  }

  /// must be implemented by the user to handle incoming events and emit new states
  FutureOr<void> onEvent(Event event);
}

///
typedef ActionObserver = void Function(
    BoltNotifier<dynamic, dynamic> blocBase, Object action);

///
typedef ErrorObserver = void Function(
  BoltNotifier<dynamic, dynamic> boltNotifier,
  Object error,
  StackTrace stackTrace,
);

sealed class CounterEvent {
  const CounterEvent();
}

class CounterIncrement extends CounterEvent {
  const CounterIncrement();
}

class CounterDecrement extends CounterEvent {
  const CounterDecrement();
}

enum BoltEvent { increment, decrement }

class BoltBenchmark extends Bolt<BoltEvent, int> {
  BoltBenchmark() : super(0);

  @override
  void onEvent(BoltEvent event) {
    return switch (event) {
      BoltEvent.increment => _increment(),
      BoltEvent.decrement => _decrement(),
    };
  }

  void _increment() => emit(state + 1);
  void _decrement() => emit(state - 1);
}

class FireBoltBenchmark extends BoltNotifier<BoltEvent, int> {
  FireBoltBenchmark() : super(0);

  @override
  void onEvent(BoltEvent event) {
    return switch (event) {
      BoltEvent.increment => _increment(),
      BoltEvent.decrement => _decrement(),
    };
  }

  void _increment() => state = state + 1;
  void _decrement() => state = state - 1;
}

class CubitBenchmark extends Cubit<int> {
  CubitBenchmark() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}

class BlocBenchmark extends Bloc<CounterEvent, int> {
  BlocBenchmark() : super(0) {
    on<CounterIncrement>((event, emit) => emit(state + 1));
    on<CounterDecrement>((event, emit) => emit(state - 1));
  }
}

class RiverpodBenchmark extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state = state + 1;
  void decrement() => state = state - 1;
}

class StateNotifierBenchmark extends StateNotifier<int> {
  StateNotifierBenchmark() : super(0);

  void increment() => state = state + 1;
  void decrement() => state = state - 1;
}

class MobxBenchmark {
  final _count = Observable(0);
  final _controller = StreamController<int>.broadcast();

  MobxBenchmark() {
    _count.observe((change) {
      final v = change.newValue;
      if (v == null) return;
      _controller.add(v);
    });
  }

  int get count => _count.value;

  Stream<int> get stream => _controller.stream;

  void increment() => _count.value++;
  void decrement() => _count.value--;
}

// ==========================================
// 6. БЕНЧМАРК РЕЗУЛЬТАТЫ
// ==========================================
class BenchmarkResult {
  final int subscribers;
  final double bolt;
  final double bolt_notifier;
  final double cubit;
  final double riverpod;
  final double bloc;
  final double mobx;
  final double value_notifier;

  BenchmarkResult({
    required this.subscribers,
    required this.bolt,
    required this.bolt_notifier,
    required this.cubit,
    required this.riverpod,
    required this.bloc,
    required this.mobx,
    required this.value_notifier,
  });

  String get leader {
    final values = {
      'Bolt': bolt,
      'BoltStateNotifier': bolt_notifier,
      'Cubit': cubit,
      'Riverpod': riverpod,
      'Bloc': bloc,
      'MobX': mobx,
      'StateNotifier': value_notifier,
    };
    final min = values.values.reduce((a, b) => a < b ? a : b);
    return values.entries
        .where((e) => e.value == min)
        .map((e) => e.key)
        .join(' / ');
  }

  String format(double value) => value.toStringAsFixed(2);
}

Future<BenchmarkResult> runBenchmark({required int subscribers}) async {
  const int iterations = 10000;
  const int stepsPerIteration = 10;

  // Warmup
  final boltWarmup = BoltBenchmark();
  final cubitWarmup = CubitBenchmark();
  final containerWarmup = ProviderContainer();
  final riverpodProviderWarmup =
      NotifierProvider<RiverpodBenchmark, int>(RiverpodBenchmark.new);

  for (int i = 0; i < 10000; i++) {
    boltWarmup.add(BoltEvent.increment);
    cubitWarmup.increment();
    containerWarmup.read(riverpodProviderWarmup.notifier).increment();
  }
  await boltWarmup.close();
  await cubitWarmup.close();
  containerWarmup.dispose();

  await Future.delayed(const Duration(milliseconds: 500));

// Bolt
  final fireboltStopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    final bolt = FireBoltBenchmark();
    var receivedCount = 0;
    final expectedCount = stepsPerIteration * 2 * subscribers;
    final completer = Completer<void>();

    for (int s = 0; s < subscribers; s++) {
      final listener = (int v) {
        receivedCount++;
        if (receivedCount >= expectedCount && !completer.isCompleted) {
          completer.complete();
        }
      };
      bolt.addListener(listener);
    }

    for (int j = 0; j < stepsPerIteration; j++) {
      bolt
        ..add(BoltEvent.increment)
        ..add(BoltEvent.decrement);
    }

    await completer.future;

    bolt.dispose();
  }
  fireboltStopwatch.stop();
  final boltNotifierTime = fireboltStopwatch.elapsedMicroseconds / iterations;

  // Bolt
  final boltStopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    final bolt = BoltBenchmark();
    var receivedCount = 0;
    final expectedCount = stepsPerIteration * 2 * subscribers;
    final completer = Completer<void>();
    final subscriptions = <StreamSubscription<int>>[];

    for (int s = 0; s < subscribers; s++) {
      final sub = bolt.stream.listen((_) {
        receivedCount++;
        if (receivedCount >= expectedCount && !completer.isCompleted) {
          completer.complete();
        }
      });
      subscriptions.add(sub);
    }

    for (int j = 0; j < stepsPerIteration; j++) {
      bolt
        ..add(BoltEvent.increment)
        ..add(BoltEvent.decrement);
    }

    await completer.future;
    for (final sub in subscriptions) {
      await sub.cancel();
    }
    await bolt.close();
  }
  boltStopwatch.stop();
  final boltTime = boltStopwatch.elapsedMicroseconds / iterations;

  await Future.delayed(const Duration(milliseconds: 500));

  // Cubit
  final cubitStopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    final cubit = CubitBenchmark();
    var receivedCount = 0;
    final expectedCount = stepsPerIteration * 2 * subscribers;
    final completer = Completer<void>();
    final subscriptions = <StreamSubscription<int>>[];

    for (int s = 0; s < subscribers; s++) {
      final sub = cubit.stream.listen((_) {
        receivedCount++;
        if (receivedCount >= expectedCount && !completer.isCompleted) {
          completer.complete();
        }
      });
      subscriptions.add(sub);
    }

    for (int j = 0; j < stepsPerIteration; j++) {
      cubit
        ..increment()
        ..decrement();
    }

    await completer.future;
    for (final sub in subscriptions) {
      await sub.cancel();
    }
    await cubit.close();
  }
  cubitStopwatch.stop();
  final cubitTime = cubitStopwatch.elapsedMicroseconds / iterations;

  await Future.delayed(const Duration(milliseconds: 500));

  // Riverpod
  final riverpodStopwatch = Stopwatch()..start();
  final riverpodProvider =
      NotifierProvider<RiverpodBenchmark, int>(RiverpodBenchmark.new);
  for (int i = 0; i < iterations; i++) {
    final container = ProviderContainer();
    var receivedCount = 0;
    final expectedCount = stepsPerIteration * 2 * subscribers;
    final completer = Completer<void>();
    final listeners = <ProviderSubscription<int>>[];

    for (int s = 0; s < subscribers; s++) {
      final sub = container.listen<int>(riverpodProvider, (_, __) {
        receivedCount++;
        if (receivedCount >= expectedCount && !completer.isCompleted) {
          completer.complete();
        }
      }, fireImmediately: false);
      listeners.add(sub);
    }

    final notifier = container.read(riverpodProvider.notifier);

    for (int j = 0; j < stepsPerIteration; j++) {
      notifier.increment();
      notifier.decrement();
    }

    await completer.future;
    for (final listener in listeners) {
      listener.close();
    }
    container.dispose();
  }
  riverpodStopwatch.stop();
  final riverpodTime = riverpodStopwatch.elapsedMicroseconds / iterations;

  await Future.delayed(const Duration(milliseconds: 500));

  // Bloc
  final blocStopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    final bloc = BlocBenchmark();
    var receivedCount = 0;
    final expectedCount = stepsPerIteration * 2 * subscribers;
    final completer = Completer<void>();
    final subscriptions = <StreamSubscription<int>>[];

    for (int s = 0; s < subscribers; s++) {
      final sub = bloc.stream.listen((_) {
        receivedCount++;
        if (receivedCount >= expectedCount && !completer.isCompleted) {
          completer.complete();
        }
      });
      subscriptions.add(sub);
    }

    for (int j = 0; j < stepsPerIteration; j++) {
      bloc
        ..add(const CounterIncrement())
        ..add(const CounterDecrement());
    }

    await completer.future;
    for (final sub in subscriptions) {
      await sub.cancel();
    }
    await bloc.close();
  }
  blocStopwatch.stop();
  final blocTime = blocStopwatch.elapsedMicroseconds / iterations;

  await Future.delayed(const Duration(milliseconds: 500));

  // MobX
  final mobxStopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    final mobx = MobxBenchmark();
    var receivedCount = 0;
    final expectedCount = stepsPerIteration * 2 * subscribers;
    final completer = Completer<void>();
    final subscriptions = <StreamSubscription<int>>[];

    for (int s = 0; s < subscribers; s++) {
      final sub = mobx.stream.listen((_) {
        receivedCount++;
        if (receivedCount >= expectedCount && !completer.isCompleted) {
          completer.complete();
        }
      });
      subscriptions.add(sub);
    }

    for (int j = 0; j < stepsPerIteration; j++) {
      mobx
        ..increment()
        ..decrement();
    }

    await completer.future;
    for (final sub in subscriptions) {
      await sub.cancel();
    }
  }
  mobxStopwatch.stop();
  final mobxTime = mobxStopwatch.elapsedMicroseconds / iterations;

  await Future.delayed(const Duration(milliseconds: 500));

  // ValueNotifier
  final valueNotifierStopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    final stateNotifier = StateNotifierBenchmark();
    var receivedCount = 0;
    final expectedCount = stepsPerIteration * 2 * subscribers;
    final completer = Completer<void>();

    for (int s = 0; s < subscribers; s++) {
      final listener = (int value) {
        receivedCount++;
        if (receivedCount >= expectedCount && !completer.isCompleted) {
          completer.complete();
        }
      };
      stateNotifier.addListener(listener);
      // final sub = valueNotifier.stream.listen((_) {});
    }

    for (int j = 0; j < stepsPerIteration; j++) {
      stateNotifier
        ..increment()
        ..decrement();
    }

    await completer.future;
    stateNotifier.dispose();
  }
  valueNotifierStopwatch.stop();
  final valueNotifierTime =
      valueNotifierStopwatch.elapsedMicroseconds / iterations;

  return BenchmarkResult(
    subscribers: subscribers,
    bolt: boltTime,
    bolt_notifier: boltNotifierTime,
    cubit: cubitTime,
    riverpod: riverpodTime,
    bloc: blocTime,
    mobx: mobxTime,
    value_notifier: valueNotifierTime,
  );
}

Future<void> main() async {
  final results = <BenchmarkResult>[];
  final subscriberCounts = [1, 5, 15, 30];

  for (final count in subscriberCounts) {
    print('Running benchmark with $count subscribers...');
    final result = await runBenchmark(subscribers: count);
    results.add(result);
    print('Done: ${result.leader} is the leader');
  }

  // Generate Results.md
  var markdown = '''# Benchmark Results

| Active Subscribers | Bolt (μs) | Cubit (μs) | Riverpod (μs) | Bloc (μs) | MobX (μs) | StateNotifier (μs) | BoltStateNotifier (μs) | Leader |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
''';

  for (final result in results) {
    final subscriberText = result.subscribers == 1
        ? '1 Subscriber'
        : '${result.subscribers} Subscribers';
    markdown +=
        '| **$subscriberText** | ${result.format(result.bolt)} | ${result.format(result.cubit)} | ${result.format(result.riverpod)} | ${result.format(result.bloc)} | ${result.format(result.mobx)} | ${result.format(result.value_notifier)} | ${result.format(result.bolt_notifier)} | **${result.leader}** |\n';
  }

  // Write to parent directory (packages/bolt)
  final file = File('../Results.md');
  await file.writeAsString(markdown);
  print('Results written to ../Results.md');
}

base class BoltNotifierObserver {
  const BoltNotifierObserver();

  /// empty , if not used will be tree shaken
  /// override if needed
  void onAction(BoltNotifier<dynamic, dynamic> state, Object action) {}

  void onError(BoltNotifier<dynamic, dynamic> state, Object error,
      StackTrace stackTrace) {}
}
