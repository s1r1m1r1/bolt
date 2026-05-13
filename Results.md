# Benchmark Results

| Active Subscribers | Bolt (μs) | Cubit (μs) | Riverpod (μs) | Bloc (μs) | MobX (μs) | StateNotifier (μs) | BoltStateNotifier (μs) | Leader |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1 Subscriber** | 4.63 | 3.98 | 8.11 | 28.83 | 8.19 | 1.08 | 4.16 | **StateNotifier** |
| **5 Subscribers** | 7.17 | 7.08 | 7.57 | 27.39 | 10.20 | 4.36 | 4.38 | **StateNotifier** |
| **15 Subscribers** | 18.84 | 20.05 | 11.60 | 38.95 | 22.10 | 6.26 | 6.81 | **StateNotifier** |
| **30 Subscribers** | 36.65 | 38.20 | 17.10 | 58.28 | 40.27 | 11.34 | 11.71 | **StateNotifier** |
