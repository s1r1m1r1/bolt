import 'bolt_base.dart';
import 'observer.dart';

final class DevBoltObserver extends BoltObserver {
  const DevBoltObserver();

  /// empty , if not used will be tree shaken
  /// override if needed
  void onAction(BoltBase<dynamic, dynamic> boltBase, Object action) {
    print('Action: ${boltBase.runtimeType} - $action');
  }

  /// empty , if not used will be tree shaken
  /// override if needed
  void fine(BoltBase<dynamic, dynamic> boltBase, String message) {
    print('Fine: ${boltBase.runtimeType} - $message');
  }

  /// empty , if not used will be tree shaken
  /// override if needed
  void info(BoltBase<dynamic, dynamic> boltBase, String message) {
    print('Info: ${boltBase.runtimeType} - $message');
  }
}
