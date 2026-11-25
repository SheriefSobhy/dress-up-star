import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/services/frame_watcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => GameMotion.lite.value = false);

  const fast = Duration(milliseconds: 8);
  const slow = Duration(milliseconds: 40);

  void feed(FrameWatcher w, int frames, {required int slowEvery}) {
    for (var i = 0; i < frames; i++) {
      final isSlow = slowEvery > 0 && i % slowEvery == 0;
      w.record(fast, isSlow ? slow : fast);
    }
  }

  test('smooth frames keep the full effects', () async {
    final w = FrameWatcher();
    await w.start();
    feed(w, 2000, slowEvery: 10); // 10% slow: fine.
    expect(GameMotion.lite.value, isFalse);
    w.stop();
  });

  test('dropping frames turns lite mode on and remembers it', () async {
    final w = FrameWatcher();
    await w.start();
    feed(w, FrameWatcher.warmUpFrames, slowEvery: 1);
    expect(GameMotion.lite.value, isFalse, reason: 'warming up is ignored');
    feed(w, FrameWatcher.windowFrames, slowEvery: 2);
    expect(GameMotion.lite.value, isFalse, reason: 'one bad moment');
    feed(w, FrameWatcher.windowFrames, slowEvery: 2);
    expect(GameMotion.lite.value, isTrue);
    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(FrameWatcher.liteModeKey), isTrue);
  });

  test('a busy moment between smooth ones does not count', () async {
    final w = FrameWatcher();
    await w.start();
    feed(w, FrameWatcher.warmUpFrames, slowEvery: 0);
    for (var i = 0; i < 5; i++) {
      feed(w, FrameWatcher.windowFrames, slowEvery: 2);
      feed(w, FrameWatcher.windowFrames, slowEvery: 0);
    }
    expect(GameMotion.lite.value, isFalse);
    w.stop();
  });

  test('a saved choice is used and the watcher stays out of it', () async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({FrameWatcher.liteModeKey: false});
    final w = FrameWatcher();
    await w.start();
    feed(w, 2000, slowEvery: 1);
    expect(GameMotion.lite.value, isFalse);

    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({FrameWatcher.liteModeKey: true});
    await FrameWatcher().start();
    expect(GameMotion.lite.value, isTrue);
  });
}
