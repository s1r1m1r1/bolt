# Benchmark Results

| Active Subscribers | Bolt (μs) | Cubit (μs) | Riverpod (μs) | Bloc (μs) | MobX (μs) | StateNotifier (μs) | BoltStateNotifier (μs) | Leader |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1 Subscriber** | 2.97 | 2.87 | 8.05 | 22.65 | 8.01 | 2.09 | 4.25 | **StateNotifier** |
| **5 Subscribers** | 6.33 | 7.84 | 7.94 | 26.34 | 9.48 | 3.46 | 3.43 | **BoltStateNotifier** |
| **15 Subscribers** | 16.80 | 18.53 | 11.33 | 36.40 | 18.97 | 6.54 | 7.32 | **StateNotifier** |
| **30 Subscribers** | 32.92 | 34.70 | 19.15 | 53.09 | 35.36 | 11.33 | 12.70 | **StateNotifier** |
