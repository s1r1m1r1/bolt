import 'package:counter/src/bolt/bolt.dart';

import '../../../counter.dart';
import '../../bolt/bolt_observer_extension.dart';

class CounterBolt extends Bolt<CounterEvent, int> {
  CounterBolt() : super(0);

  @override
  void onEvent(CounterEvent event) {
    fine('CounterBolt receive event: $event');
    switch (event) {
      case CounterIncrement():
        _increment();
      case CounterDecrement():
        _decrement();
    }
  }

  void _increment() {
    info('incrementInfo');
    emit(state + 1);
  }

  void _decrement() {
    info('decrementInfo');
    emit(state - 1);
  }
}
