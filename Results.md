# Benchmark Results

| Active Subscribers | Bolt (μs) | Cubit (μs) | Riverpod (μs) | Bloc (μs) | MobX (μs) | StateNotifier (μs) | BoltStateNotifier (μs) | Leader |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1 Subscriber** | 3.08 | 3.28 | 10.38 | 23.10 | 7.00 | 1.06 | 3.85 | **StateNotifier** |
| **5 Subscribers** | 6.49 | 6.81 | 8.47 | 24.62 | 8.89 | 3.21 | 3.95 | **StateNotifier** |
| **10 Subscribers** | 11.33 | 13.22 | 9.67 | 31.10 | 14.45 | 4.07 | 6.17 | **StateNotifier** |
| **15 Subscribers** | 16.52 | 18.06 | 11.08 | 35.37 | 20.29 | 6.93 | 7.64 | **StateNotifier** |
