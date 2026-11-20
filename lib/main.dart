import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/dress_up_screen.dart';
import 'services/looks_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  runApp(DressUpStarApp(storage: LooksStorage()));
}

class DressUpStarApp extends StatelessWidget {
  const DressUpStarApp({super.key, required this.storage});

  final LooksStorage storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dress Up Star',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF8FC7)),
        useMaterial3: true,
      ),
      home: DressUpScreen(storage: storage),
    );
  }
}
