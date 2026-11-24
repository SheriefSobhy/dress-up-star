import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/title_screen.dart';
import 'services/game_audio.dart';
import 'services/looks_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  runApp(
    DressUpStarApp(storage: LooksStorage(), audio: AudioPlayersGameAudio()),
  );
}

class DressUpStarApp extends StatefulWidget {
  const DressUpStarApp({super.key, required this.storage, this.audio});

  final LooksStorage storage;

  /// Sounds and music. Without it the game is silent (used by tests).
  final GameAudio? audio;

  @override
  State<DressUpStarApp> createState() => _DressUpStarAppState();
}

class _DressUpStarAppState extends State<DressUpStarApp> {
  late final GameAudio _audio = widget.audio ?? SilentGameAudio();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Pause the music while the app is in the background (on every screen).
    _lifecycle = AppLifecycleListener(
      onHide: _audio.pauseMusic,
      onShow: _audio.resumeMusic,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dress Up Star',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF8FC7)),
        useMaterial3: true,
        fontFamily: 'Fredoka',
      ),
      // Browsers only allow music after the first touch, so every touch
      // gives the music a chance to start (it does nothing once playing).
      builder: (context, child) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerUp: (_) => _audio.startMusic(),
        child: child,
      ),
      home: TitleScreen(storage: widget.storage, audio: _audio),
    );
  }
}
