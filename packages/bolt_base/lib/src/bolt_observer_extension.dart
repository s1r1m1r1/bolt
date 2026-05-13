import 'bolt_base.dart';

extension BoltExtension on BoltBase<dynamic, dynamic> {
  /// directly inline , this will be tree shaken when method empty
  ///
  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void finest(String message) => BoltBase.observer.finest(this, message);

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void finer(String message) => BoltBase.observer.finer(this, message);

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void fine(String message) => BoltBase.observer.fine(this, message);

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void info(String message) => BoltBase.observer.info(this, message);

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void warn(String message) => BoltBase.observer.warning(this, message);

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void severe(String message) => BoltBase.observer.severe(this, message);

  @pragma('dart2js:tryInline')
  @pragma('vm:prefer-inline')
  void onError(Object error, StackTrace stackTrace) =>
      BoltBase.observer.onError(this, error, stackTrace);
}
