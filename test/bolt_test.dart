import 'dart:async';
import 'package:test/test.dart';
import 'package:bloc_bolt/bloc_bolt.dart';

// Модели для тестирования
sealed class TestEvent {}

class SyncEvent extends TestEvent {}

class AsyncEvent extends TestEvent {}

class LocalErrorEvent extends TestEvent {}

class SyncErrorEvent extends TestEvent {}

class AsyncErrorEvent extends TestEvent {}

class TestBolt extends Bolt<TestEvent, int> {
  final List<Object> caughtErrors = [];

  TestBolt() : super(0);

  @override
  FutureOr<void> onEvent(TestEvent event) async {
    switch (event) {
      case SyncEvent():
        emit(state + 1);

      case AsyncEvent():
        await Future<void>.delayed(const Duration(milliseconds: 10));
        emit(state + 1);

      case LocalErrorEvent():
        try {
          throw Exception('Local error');
        } catch (e, s) {
          emit(-1); // Специальный стейт при ошибке
          addError(e, s);
        }

      case SyncErrorEvent():
        throw Exception('Synchronous crash');

      case AsyncErrorEvent():
        await Future<void>.delayed(const Duration(milliseconds: 10));
        throw Exception('Asynchronous crash');
    }
  }

  // Перехватываем ошибки внутри класса для верификации тестов
  @override
  void onError(Object error, StackTrace stackTrace) {
    caughtErrors.add(error);
    super.onError(error, stackTrace);
  }
}

void main() {
  group('Bolt Core Tests', () {
    late TestBolt bolt;

    setUp(() {
      bolt = TestBolt();
    });

    tearDown(() async {
      await bolt.close();
    });

    test('should emit initial state correctly', () {
      expect(bolt.state, equals(0));
    });

    test('should handle synchronous events and emit new states', () async {
      final expectedStates = [1];
      expectLater(bolt.stream, emitsInOrder(expectedStates));

      bolt.add(SyncEvent());
    });

    test('should handle asynchronous events correctly', () async {
      final expectedStates = [1];
      expectLater(bolt.stream, emitsInOrder(expectedStates));

      bolt.add(AsyncEvent());
    });
  });

  group('Bolt Error Handling Tests', () {
    late TestBolt bolt;

    setUp(() {
      bolt = TestBolt();
    });

    tearDown(() async {
      await bolt.close();
    });

    test('should support local try-catch and continue execution', () async {
      expectLater(bolt.stream, emitsInOrder([-1]));

      bolt.add(LocalErrorEvent());

      // Даем микротаскам отработать, чтобы проверить, что ошибка дошла до onError
      await Future<void>.delayed(Duration.zero);
      expect(bolt.caughtErrors.length, equals(1));
      expect(bolt.caughtErrors.first.toString(), contains('Local error'));
    });

    test('should automatically catch synchronous top-level errors', () async {
      bolt.add(SyncErrorEvent());

      await Future<void>.delayed(Duration.zero);
      expect(bolt.caughtErrors.length, equals(1));
      expect(bolt.caughtErrors.first.toString(), contains('Synchronous crash'));
    });

    test('should automatically catch asynchronous top-level errors from Future',
        () async {
      bolt.add(AsyncErrorEvent());

      // Ждем завершения асинхронного Future внутри onEvent
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(bolt.caughtErrors.length, equals(1));
      expect(
          bolt.caughtErrors.first.toString(), contains('Asynchronous crash'));
    });
  });
}
