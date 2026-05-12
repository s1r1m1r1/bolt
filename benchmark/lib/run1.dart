import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:riverpod/riverpod.dart';

// ==========================================
// 3. РАННЕР БЕНЧМАРКА
// ==========================================
void main() async {
  final runner = BenchmarkRunner();
  await runner.run();
}

///
typedef ActionObserver = void Function(
    BlocBase<dynamic> blocBase, Object action);

///
typedef ErrorObserver = void Function(
    BlocBase<dynamic> blocBase, Object error, StackTrace stackTrace);

// ==========================================
// 1. РЕАЛИЗАЦИЯ КАРКАСА BOLT
// ==========================================
abstract class Bolt<Event extends Object, State> extends BlocBase<State> {
  Bolt(State state) : super(state);

  /// directly inline , this will be tree shaken when method empty
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  ActionObserver get actionObserver => (_, __) {};

  /// directly inline , this will be tree shaken when method empty
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  // ignore: invalid_use_of_protected_member
  ErrorObserver get errorObserver => Bloc.observer.onError;

  void add(Event event) {
    actionObserver(this, event);
    try {
      final result = onEvent(event);
      if (result is Future) {
        result.catchError(errorObserver);
      }
    } catch (e, s) {
      errorObserver(this, e, s);
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

class CounterIncrement implements CounterEvent {
  const CounterIncrement();
}

class CounterDecrement implements CounterEvent {
  const CounterDecrement();
}

// Реализация Bolt
class BoltBenchmark extends Bolt<CounterEvent, int> {
  BoltBenchmark() : super(0);

  @override
  void onEvent(CounterEvent event) {
    switch (event) {
      case CounterIncrement():
        _increment();
      case CounterDecrement():
        _decrement();
    }
  }

  void _increment() => emit(state + 1);
  void _decrement() => emit(state - 1);
}

// Реализация Cubit
class CubitBenchmark extends Cubit<int> {
  CubitBenchmark() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}

// Реализация Bloc
class BlocBenchmark extends Bloc<CounterEvent, int> {
  BlocBenchmark() : super(0) {
    on<CounterIncrement>((event, emit) => emit(state + 1));
    on<CounterDecrement>((event, emit) => emit(state - 1));
  }
}

// Реализация Riverpod Notifier
class RiverpodBenchmark extends Notifier<int> {
  @override
  int build() => 0;

  void increment() => state = state + 1;
  void decrement() => state = state - 1;
}

class BenchmarkRunner {
  static const int iterations = 100000;
  static const int stepsPerIteration =
      10; // 10 инкрементов + 10 декрементов = 20 изменений

  Future<void> run() async {
    print('Running State Management Benchmark Suite');
    print('========================================');
    print(
        'Iterations: $iterations (${stepsPerIteration * 2} updates per iteration)');
    print('');

    print('Running warmup...');
    await _warmup();
    print('Warmup complete.\n');

    await _benchmarkRiverpod();
    await _benchmarkBolt();
    // await Future.delayed(const Duration(seconds: 1));
    await _benchmarkCubit();

    // await Future.delayed(const Duration(seconds: 1));

    // await Future.delayed(const Duration(seconds: 1));

    // await Future.delayed(const Duration(seconds: 1));
    await _benchmarkBloc();
    // await Future.delayed(const Duration(seconds: 1));

    print('\n========================================');
    print('Benchmark complete.');
  }

  Future<void> _warmup() async {
    final bolt = BoltBenchmark();
    final cubit = CubitBenchmark();
    final bloc = BlocBenchmark();
    final container = ProviderContainer();
    final riverpodProvider =
        NotifierProvider<RiverpodBenchmark, int>(RiverpodBenchmark.new);

    for (int i = 0; i < 1000; i++) {
      bolt.add(const CounterIncrement());
      cubit.increment();
      bloc.add(const CounterIncrement());
      container.read(riverpodProvider.notifier).increment();
    }

    await bolt.close();
    await cubit.close();
    await bloc.close();
    container.dispose();
  }

  Future<void> _benchmarkBolt() async {
    print('------------------------------------------------');
    print('Benchmark: Bolt (with subscribers)');

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      final bolt = BoltBenchmark();
      var receivedCount = 0;
      final expectedCount = stepsPerIteration * 2;
      final completer = Completer<void>();

      final subscription = bolt.stream.listen((_) {
        receivedCount++;
        if (receivedCount >= expectedCount) completer.complete();
      });

      for (int j = 0; j < stepsPerIteration; j++) {
        bolt
          ..add(const CounterIncrement())
          ..add(const CounterDecrement());
      }

      await completer.future;
      await subscription.cancel();
      await bolt.close();
    }

    stopwatch.stop();
    _printResults(stopwatch.elapsedMicroseconds);
  }

  Future<void> _benchmarkCubit() async {
    print('------------------------------------------------');
    print('Benchmark: Cubit (with subscribers)');

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      final cubit = CubitBenchmark();
      var receivedCount = 0;
      final expectedCount = stepsPerIteration * 2;
      final completer = Completer<void>();

      final subscription = cubit.stream.listen((_) {
        receivedCount++;
        if (receivedCount >= expectedCount) completer.complete();
      });

      for (int j = 0; j < stepsPerIteration; j++) {
        cubit
          ..increment()
          ..decrement();
      }

      await completer.future;
      await subscription.cancel();
      await cubit.close();
    }

    stopwatch.stop();
    _printResults(stopwatch.elapsedMicroseconds);
  }

  Future<void> _benchmarkRiverpod() async {
    print('------------------------------------------------');
    print('Benchmark: Riverpod Notifier (with subscribers)');

    final stopwatch = Stopwatch()..start();
    final riverpodProvider =
        NotifierProvider<RiverpodBenchmark, int>(RiverpodBenchmark.new);

    for (int i = 0; i < iterations; i++) {
      final container = ProviderContainer();
      var receivedCount = 0;
      final expectedCount = stepsPerIteration * 2;
      final completer = Completer<void>();

      // В Riverpod слушаем через container.listen (это аналог stream.listen)
      final listener = container.listen<int>(riverpodProvider, (_, __) {
        receivedCount++;
        if (receivedCount >= expectedCount) completer.complete();
      }, fireImmediately: false);

      final notifier = container.read(riverpodProvider.notifier);

      for (int j = 0; j < stepsPerIteration; j++) {
        notifier.increment();
        notifier.decrement();
      }

      await completer.future;
      listener.close();
      container.dispose();
    }

    stopwatch.stop();
    _printResults(stopwatch.elapsedMicroseconds);
  }

  Future<void> _benchmarkBloc() async {
    print('------------------------------------------------');
    print('Benchmark: Bloc (with subscribers)');

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      final bloc = BlocBenchmark();
      var receivedCount = 0;
      final expectedCount = stepsPerIteration * 2;
      final completer = Completer<void>();

      final subscription = bloc.stream.listen((_) {
        receivedCount++;
        if (receivedCount >= expectedCount) completer.complete();
      });

      for (int j = 0; j < stepsPerIteration; j++) {
        bloc
          ..add(const CounterIncrement())
          ..add(const CounterDecrement());
      }

      await completer.future;
      await subscription.cancel();
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
