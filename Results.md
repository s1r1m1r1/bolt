# Benchmark Results

| Active Subscribers | Bolt (μs) | Cubit (μs) | Riverpod (μs) | Bloc (μs) | MobX (μs) | StateNotifier (μs) | BoltStateNotifier (μs) | Leader |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1 Subscriber** | 4.73 | 3.54 | 9.25 | 28.99 | 7.15 | 1.88 | 3.12 | **StateNotifier** |
| **5 Subscribers** | 7.12 | 8.60 | 9.08 | 27.51 | 10.47 | 2.64 | 5.31 | **StateNotifier** |
| **15 Subscribers** | 18.37 | 20.33 | 11.45 | 40.38 | 22.13 | 5.61 | 8.41 | **StateNotifier** |
| **30 Subscribers** | 35.60 | 37.33 | 18.99 | 58.39 | 37.46 | 12.13 | 12.56 | **StateNotifier** |
