abstract class BoltObserver {
  /// empty , if not used will be tree shaken
  /// override if needed
  void onAction(BoltBase<dynamic, dynamic> boltBase, Object action) {}
}
