import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:counter/counter.dart';

import '../bolt/counter_bolt.dart';

/// CounterPage - UI layer
/// Displays the counter and handles user interactions
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterBolt(),
      child: const CounterView(),
    );
  }
}

/// CounterView - Presentational widget
class CounterView extends StatelessWidget {
  const CounterView({super.key});

  @override
  Widget build(BuildContext context) {
    final bolt = context.read<CounterBolt>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter - Bolt'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Current count:'),
            BlocBuilder<CounterBolt, int>(
              builder: (context, state) {
                return Text(
                  '${state}',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () => bolt.add(const CounterDecrement()),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () => bolt.add(const CounterIncrement()),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
