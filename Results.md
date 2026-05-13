# Benchmark Results

| Active Subscribers | Bolt (μs) | Cubit (μs) | Riverpod (μs) | Bloc (μs) | MobX (μs) | StateNotifier (μs) | BoltStateNotifier (μs) | Leader |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1 Subscriber** | 3.01 | 2.76 | 9.14 | 23.67 | 5.99 | 1.39 | 5.34 | **StateNotifier** |
| **5 Subscribers** | 6.45 | 6.58 | 8.07 | 26.35 | 9.69 | 4.19 | 4.55 | **StateNotifier** |
| **10 Subscribers** | 11.71 | 15.12 | 9.61 | 31.93 | 14.25 | 5.15 | 4.29 | **BoltStateNotifier** |
| **15 Subscribers** | 16.85 | 18.43 | 11.04 | 36.46 | 19.16 | 5.28 | 6.57 | **StateNotifier** |
