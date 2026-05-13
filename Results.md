# Benchmark Results

| Active Subscribers | Bolt (μs) | Cubit (μs) | Riverpod (μs) | Bloc (μs) | MobX (μs) | StateNotifier (μs) | Leader |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1 Subscriber** | 6.04 | 2.65 | 8.45 | 28.06 | 7.73 | 1.80 | **StateNotifier** |
| **5 Subscribers** | 9.96 | 8.75 | 6.25 | 26.83 | 10.57 | 2.95 | **StateNotifier** |
| **15 Subscribers** | 20.22 | 20.10 | 11.36 | 40.50 | 21.56 | 7.18 | **StateNotifier** |
| **30 Subscribers** | 37.57 | 37.04 | 18.61 | 57.87 | 38.31 | 11.70 | **StateNotifier** |
