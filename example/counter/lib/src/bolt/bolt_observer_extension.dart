import 'package:counter/src/bolt/bolt.dart';
import 'package:counter/src/bolt/bolt_base.dart';

extension BoltExtension on BoltBase<dynamic, dynamic> {
  /// directly inline , this will be tree shaken when method empty
  ///
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void finest(String message) => Bolt.observer.finest(this, message);

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void finer(String message) => Bolt.observer.finer(this, message);

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void fine(String message) => Bolt.observer.fine(this, message);

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void info(String message) => Bolt.observer.info(this, message);

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void warn(String message) => Bolt.observer.warning(this, message);

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void severe(String message) => Bolt.observer.severe(this, message);

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void onError(Object error, StackTrace stackTrace) =>
      Bolt.observer.onError(this, error, stackTrace);
}
