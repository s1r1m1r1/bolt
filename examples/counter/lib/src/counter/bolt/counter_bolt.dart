import 'package:bolt/bolt.dart';

import '../../../counter.dart';

class CounterBolt extends Bolt<CounterEvent, int> {
  CounterBolt() : super(0);

  @override
  void onEvent(CounterEvent event) {
    switch (event) {
      case CounterIncrement():
        emit(state + 1);
      case CounterDecrement():
        emit(state - 1);
    }
  }
}
