import 'dart:async';

import 'package:bolt/bolt.dart';

import 'benchmark_models.dart';

void main() async {
  final runner = BenchmarkRunner();
  await runner.run();
}

extension _Track on Cubit {
  static log(String name) {
    // print('$name start');
  }

  void track(void Function() fn, String name) {
    log('$name start ');
    try {
      fn();
    } catch (e, s) {
      log('Error in track: $e\nStackTrace: $s');
    }
  }
}

extension _TrackAsync on Future<void> Function() {
  static log(String name) {
    // print('$name start');
  }
}

/// Event types for benchmarking
sealed class CounterEvent {
  const CounterEvent();
}

class CounterIncrement extends CounterEvent {
  const CounterIncrement();
}

class CounterDecrement extends CounterEvent {
  const CounterDecrement();
}

/// Cubit implementation for benchmarking
class CubitBenchmark extends Cubit<int> {
  CubitBenchmark() : super(0);

  void increment() {
    emit(state + 1);
  }

  Future<void> decrement() async {
    emit(state + 1);
  }
}

typedef EmitterCallback<State> = void Function(State state);

/// Bloc implementation for benchmarking
class BlocBenchmark extends Bloc<CounterEvent, int> {
  BlocBenchmark() : super(0) {
    on<CounterIncrement>((event, emit) {
      emit(state + 1);
    });
    on<CounterDecrement>((event, emit) async {
      emit(state - 1);
    });
  }
}

// /// SimpleBloc implementation for benchmarking
class SimpleBlocBenchmark extends Bolt<CounterEvent, int> {
  SimpleBlocBenchmark() : super(0);

  @override
  Future<void> onEvent(CounterEvent event) async {
    try {
      switch (event) {
        case CounterIncrement():
          _increment();
        case CounterDecrement():
          // _increment();
          await _decrement();
      }
    } catch (e, s) {
      addError(e, s);
    }
  }

  void _increment() {
    emit(state + 1);
  }

  Future<void> _decrement() async {
    emit(state + 1);
  }
}

/// Benchmark runner
class BenchmarkRunner {
  static const int iterations = 1000;
  static const int warmupIterations = 10;

  Future<void> run() async {
    print('Running Bloc Benchmark Suite');
    print('==============================');
    print('Iterations: $iterations');
    print('');

    // Warmup
    print('Running warmup...');
    await _warmup();
    print('Warmup complete.');
    print('');

    // Run benchmarks
    await _benchmarkCubit();
    await _benchmarkBloc();
    await _benchmarkBolt();

    print('');
    print('Benchmark complete.');
  }

  Future<void> _warmup() async {
    final cubit = CubitBenchmark();
    final bloc = BlocBenchmark();
    final bolt = SimpleBlocBenchmark();

    for (int i = 0; i < warmupIterations; i++) {
      cubit.increment();
      bloc.add(const CounterIncrement());
      bolt.add(const CounterIncrement());
    }

    cubit.close();
    bloc.close();
    // bolt.close();
  }

  Future<void> _benchmarkCubit() async {
    print('\n\n----------------');
    print('Benchmark: Cubit (with subscribers)');

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      final cubit = CubitBenchmark();
      var receivedCount = 0;
      final expectedCount = 20; // 10 increments + 10 decrements

      // Add subscribers that will wait for data
      final subscription = cubit.stream.listen((state) {
        receivedCount++;
        if (receivedCount >= expectedCount) {}
      });

      for (int j = 0; j < 10; j++) {
        cubit.increment();
        await cubit.decrement();
      }

      // Close the subscription and cubit
      await subscription.cancel();
      await cubit.close();
    }

    stopwatch.stop();
    final duration = stopwatch.elapsedMicroseconds;
    final avgPerIteration = duration / iterations;

    print('Total time: $duration microseconds');
    print('Average per iteration: $avgPerIteration microseconds');
  }

  Future<void> _benchmarkBloc() async {
    print('\n\n---------------------------------------');
    print('Benchmark: Bloc (with subscribers)');

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      final bloc = BlocBenchmark();
      final completer = Completer<void>();
      var receivedCount = 0;
      final expectedCount = 20; // 10 increments + 10 decrements

      // Add subscribers that will wait for data
      final subscription = bloc.stream.listen((state) {
        receivedCount++;
        if (receivedCount >= expectedCount) {
          completer.complete();
        }
      });

      for (int j = 0; j < 10; j++) {
        bloc.add(CounterIncrement());
        bloc.add(CounterDecrement());
      }

      // Wait for all subscribers to receive data before closing
      await completer.future;

      // Close the subscription and bloc
      await subscription.cancel();
      await bloc.close();
    }

    stopwatch.stop();
    final duration = stopwatch.elapsedMicroseconds;
    final avgPerIteration = duration / iterations;

    print('Total time: $duration microseconds');
    print('Average per iteration: $avgPerIteration microseconds');
  }

  Future<void> _benchmarkBolt() async {
    print('\n\n------------------------------------------------');
    print('Benchmark: Bolt (with subscribers)');

    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      final simpleBloc = SimpleBlocBenchmark();
      var receivedCount = 0;
      final expectedCount = 20; // 10 increments + 10 decrements
      final completer = Completer<void>();
      // Add subscribers that will wait for data
      final subscription = simpleBloc.stream.listen((state) {
        receivedCount++;
        if (receivedCount >= expectedCount) {
          completer.complete();
        }
      });

      for (int j = 0; j < 10; j++) {
        simpleBloc
          ..add(const CounterIncrement())
          ..add(const CounterDecrement());
      }

      // Wait for all subscribers to receive data before closing
      await completer.future;

      // Close the subscription and bolt
      await subscription.cancel();
      await simpleBloc.close();
    }

    stopwatch.stop();
    final duration = stopwatch.elapsedMicroseconds;
    final avgPerIteration = duration / iterations;

    print('Total time: $duration microseconds');
    print('Average per iteration: $avgPerIteration microseconds');
  }
}
