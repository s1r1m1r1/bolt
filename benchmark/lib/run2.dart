import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:riverpod/riverpod.dart';

// ==========================================
// 3. RANNER БЕНЧМАРКА (5 ПОДПИСЧИКОВ)
// ==========================================
void main() async {
  final runner = BenchmarkRunner();
  await runner.run();
}

// ==========================================
// 1. РЕАЛИЗАЦИЯ КАРКАСА BOLT
// ==========================================
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

// ==========================================
// 2. МОДЕЛИ И РЕАЛИЗАЦИИ ДЛЯ ТЕСТОВ
// ==========================================
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

class BenchmarkRunner {
  static const int iterations = 100000; // Оптимально для замера подписок
  static const int stepsPerIteration = 10;
  static const int subscriberCount = 15; // Количество подписчиков на контейнер

  Future<void> run() async {
    print('Running State Management Benchmark Suite (Multi-Subscriber)');
    print('===========================================================');
    print('Iterations: $iterations');
    print('Subscribers per container: $subscriberCount');
    print(
        'Total notifications per iteration: ${stepsPerIteration * 2 * subscriberCount}');
    print('');

    print('Running warmup...');
    await _warmup();
    print('Warmup complete.\n');

    // Небольшие задержки для изоляции сборщика мусора (GC)
    await Future.delayed(const Duration(milliseconds: 500));
    await _benchmarkBolt();

    await Future.delayed(const Duration(milliseconds: 500));
    await _benchmarkCubit();

    await Future.delayed(const Duration(milliseconds: 500));
    await _benchmarkRiverpod();

    await Future.delayed(const Duration(milliseconds: 500));
    await _benchmarkBloc();

    print('\n===========================================================');
    print('Benchmark complete.');
  }

  Future<void> _warmup() async {
    final bolt = BoltBenchmark();
    final cubit = CubitBenchmark();
    final container = ProviderContainer();
    final riverpodProvider =
        NotifierProvider<RiverpodBenchmark, int>(RiverpodBenchmark.new);

    for (int i = 0; i < 10000; i++) {
      bolt.add(BoltEvent.increment);
      cubit.increment();
      container.read(riverpodProvider.notifier).increment();
    }

    await bolt.close();
    await cubit.close();
    container.dispose();
  }

  Future<void> _benchmarkBolt() async {
    print('------------------------------------------------');
    print('Benchmark: Bolt (with $subscriberCount subscribers)');

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      final bolt = BoltBenchmark();
      var receivedCount = 0;
      final expectedCount = stepsPerIteration * 2 * subscriberCount;
      final completer = Completer<void>();
      final subscriptions = <StreamSubscription<int>>[];

      for (int s = 0; s < subscriberCount; s++) {
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

    stopwatch.stop();
    _printResults(stopwatch.elapsedMicroseconds);
  }

  Future<void> _benchmarkCubit() async {
    print('------------------------------------------------');
    print('Benchmark: Cubit (with $subscriberCount subscribers)');

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      final cubit = CubitBenchmark();
      var receivedCount = 0;
      final expectedCount = stepsPerIteration * 2 * subscriberCount;
      final completer = Completer<void>();
      final subscriptions = <StreamSubscription<int>>[];

      for (int s = 0; s < subscriberCount; s++) {
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

    stopwatch.stop();
    _printResults(stopwatch.elapsedMicroseconds);
  }

  Future<void> _benchmarkRiverpod() async {
    print('------------------------------------------------');
    print('Benchmark: Riverpod Notifier (with $subscriberCount subscribers)');

    final stopwatch = Stopwatch()..start();
    final riverpodProvider =
        NotifierProvider<RiverpodBenchmark, int>(RiverpodBenchmark.new);

    for (int i = 0; i < iterations; i++) {
      final container = ProviderContainer();
      var receivedCount = 0;
      final expectedCount = stepsPerIteration * 2 * subscriberCount;
      final completer = Completer<void>();
      final listeners = <ProviderSubscription<int>>[];

      for (int s = 0; s < subscriberCount; s++) {
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

    stopwatch.stop();
    _printResults(stopwatch.elapsedMicroseconds);
  }

  Future<void> _benchmarkBloc() async {
    print('------------------------------------------------');
    print('Benchmark: Bloc (with $subscriberCount subscribers)');

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      final bloc = BlocBenchmark();
      var receivedCount = 0;
      final expectedCount = stepsPerIteration * 2 * subscriberCount;
      final completer = Completer<void>();
      final subscriptions = <StreamSubscription<int>>[];

      for (int s = 0; s < subscriberCount; s++) {
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

    stopwatch.stop();
    _printResults(stopwatch.elapsedMicroseconds);
  }

  void _printResults(int microseconds) {
    final avgPerIteration = microseconds / iterations;
    print('Total time: $microseconds microseconds');
    print(
        'Average per iteration: ${avgPerIteration.toStringAsFixed(3)} microseconds');
  }
}
