import 'package:flutter/material.dart';

import 'src/app/counter_app.dart';
import 'src/bolt/bolt.dart';
import 'src/bolt/observer.dart';

void main() {
  Bolt.observer = const BoltObserver();
  runApp(const CounterApp());
}
