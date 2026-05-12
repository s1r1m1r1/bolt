/// Event types for the counter
sealed class CounterEvent {
  const CounterEvent();
}

class CounterIncrement extends CounterEvent {
  const CounterIncrement();
}

class CounterDecrement extends CounterEvent {
  const CounterDecrement();
}
