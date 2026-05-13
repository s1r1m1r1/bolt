# Benchmark Results

| Active Subscribers | Bolt (μs) | Cubit (μs) | Riverpod (μs) | Bloc (μs) | MobX (μs) | StateNotifier (μs) | BoltStateNotifier (μs) | Leader |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1 Subscriber** | 3.10 | 2.21 | 8.32 | 24.07 | 7.72 | 2.17 | 3.89 | **StateNotifier** |
| **5 Subscribers** | 6.37 | 7.37 | 7.92 | 26.80 | 9.10 | 3.32 | 4.46 | **StateNotifier** |
| **15 Subscribers** | 16.64 | 16.70 | 11.99 | 38.18 | 19.24 | 7.60 | 7.35 | **BoltStateNotifier** |
| **30 Subscribers** | 32.39 | 33.94 | 18.22 | 55.35 | 35.03 | 11.40 | 11.13 | **BoltStateNotifier** |
