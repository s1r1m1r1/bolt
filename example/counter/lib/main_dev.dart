import 'package:flutter/material.dart';

import 'src/app/counter_app.dart';
import 'src/bolt/bolt.dart';
import 'src/bolt/dev_observer.dart';

void main() {
  Bolt.observer = DevBoltObserver();
  runApp(const CounterApp());
}
