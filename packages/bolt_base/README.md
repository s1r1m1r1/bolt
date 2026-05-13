# Bolt ⚡

A minimal, ultra-high-performance event-driven state management on top of StateNotifier.
## Features

- **Strict Event-Driven Contract:** Keep your business logic isolated. UI only communicates via explicit events.
- **Zero Inbound Overhead:** No stream buffers or microtask delays between event dispatch and execution.

## Quick Start

### 1. Define Events and State
Leverage modern Dart sealed classes for type-safe event payloads:

```dart
sealed class CounterEvent { const CounterEvent(); }
class Increment extends CounterEvent { const Increment(); }
class Decrement extends CounterEvent { const Decrement(); }
```

### 2. Create your Bolt Container
Implement the synchronous/asynchronous `onEvent` handler:

```dart
class CounterBolt extends BoltStateNotifier<CounterEvent, int> {
  CounterBolt() : super(0);

  @override
  void onEvent(CounterEvent event) {
    switch (event) {
      case Increment(): state =state + 1;
      case Decrement(): state =state - 1;
    }
  }
}
```

