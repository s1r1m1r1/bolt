# Benchmark Results

| Active Subscribers | Bolt (μs) | Cubit (μs) | Riverpod (μs) | Bloc (μs) | MobX (μs) | StateNotifier (μs) | FireBolt (μs) | Leader |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1 Subscriber** | 4.75 | 2.86 | 9.22 | 29.69 | 6.72 | 2.17 | 3.11 | **StateNotifier** |
| **5 Subscribers** | 6.84 | 7.47 | 7.38 | 28.19 | 9.78 | 3.62 | 5.25 | **StateNotifier** |
| **15 Subscribers** | 18.15 | 20.15 | 11.43 | 40.07 | 21.36 | 6.94 | 6.79 | **FireBolt** |
| **30 Subscribers** | 35.24 | 36.53 | 18.82 | 57.60 | 38.73 | 11.35 | 12.34 | **StateNotifier** |
