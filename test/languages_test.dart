import 'package:dress_up_star/art/motion.dart';
import 'package:dress_up_star/l10n/app_strings.dart';
import 'package:dress_up_star/main.dart';
import 'package:dress_up_star/services/app_settings.dart';
import 'package:dress_up_star/services/game_settings.dart';
import 'package:dress_up_star/services/looks_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'parents_test.dart' show openParents;

Future<void> pumpTitle(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  Locale? phone,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (phone != null) {
    tester.platformDispatcher.localesTestValue = [phone];
    tester.platformDispatcher.localeTestValue = phone;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
  }
  await tester.pumpWidget(DressUpStarApp(storage: LooksStorage()));
  await tester.pumpAndSettle();
}

TextDirection directionOf(WidgetTester tester, Finder finder) =>
    Directionality.of(tester.element(finder));

void main() {
  GameMotion.idleAnimations = false;
  setUp(
    () => SharedPreferences.setMockInitialValues({
      GameSettings.scrollHintSeenKey: true,
      GameSettings.tutorialSeenKey: true,
    }),
  );

  test('every word exists in English and Arabic', () {
    final en = AppStrings.wordsOf('en');
    final ar = AppStrings.wordsOf('ar');
    expect(ar.keys.toSet(), en.keys.toSet());
    for (final key in en.keys) {
      expect(ar[key]!.trim(), isNotEmpty, reason: key);
      expect(ar[key], isNot(en[key]), reason: '$key is not translated');
    }
    expect(
      AppStrings.arabic.privacyPolicyText.length,
      AppStrings.english.privacyPolicyText.length,
    );
    // The game's name stays the same.
    expect(AppStrings.arabic.appName, 'Dress Up Star');
    expect(AppStrings.arabic.mathQuestion(6, 7), contains('6 × 7'));
  });

  test('Arabic phones get Arabic, all others English', () {
    expect(AppSettings.resolve(const Locale('ar', 'EG')), const Locale('ar'));
    expect(AppSettings.resolve(const Locale('ar')), const Locale('ar'));
    expect(AppSettings.resolve(const Locale('en', 'US')), const Locale('en'));
    expect(AppSettings.resolve(const Locale('fr')), const Locale('en'));
    expect(AppSettings.resolve(null), const Locale('en'));
  });

  testWidgets('an English phone shows English, left to right', (tester) async {
    await pumpTitle(tester, phone: const Locale('en', 'US'));
    final play = find.byKey(const Key('play_button'));
    expect(directionOf(tester, play), TextDirection.ltr);
    expect(find.bySemanticsLabel('Play'), findsOneWidget);
  });

  testWidgets('an Arabic phone shows Arabic, right to left', (tester) async {
    await pumpTitle(tester, phone: const Locale('ar', 'SA'));
    final play = find.byKey(const Key('play_button'));
    expect(directionOf(tester, play), TextDirection.rtl);
    expect(find.bySemanticsLabel('العب'), findsOneWidget);
    // The name stays "Dress Up Star".
    expect(find.bySemanticsLabel(RegExp('^Dress Up Star')), findsOneWidget);
  });

  testWidgets('a French phone falls back to English', (tester) async {
    await pumpTitle(tester, phone: const Locale('fr', 'FR'));
    expect(
      directionOf(tester, find.byKey(const Key('play_button'))),
      TextDirection.ltr,
    );
    expect(find.bySemanticsLabel('Play'), findsOneWidget);
  });

  testWidgets('the parents choice wins over the phone', (tester) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      GameSettings.tutorialSeenKey: true,
      AppSettings.languageKey: 'en',
    });
    await pumpTitle(tester, phone: const Locale('ar'));
    expect(find.bySemanticsLabel('Play'), findsOneWidget);
  });

  testWidgets('switching language in the parents screen', (tester) async {
    await pumpTitle(tester, phone: const Locale('en', 'US'));
    await openParents(tester);
    expect(find.text('Parents'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language_ar')));
    await tester.pumpAndSettle();
    expect(find.text('إعدادات الوالدين'), findsOneWidget);
    expect(find.text('الموسيقى'), findsOneWidget);
    expect(
      directionOf(tester, find.byKey(const Key('parents_music'))),
      TextDirection.rtl,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(AppSettings.languageKey), 'ar');

    // Back to the phone's language (English here).
    await tester.tap(find.byKey(const Key('language_system')));
    await tester.pumpAndSettle();
    expect(find.text('Parents'), findsOneWidget);
    expect(prefs.getString(AppSettings.languageKey), isNull);
  });

  for (final size in const [Size(390, 844), Size(320, 640)]) {
    testWidgets('Arabic game screens fit ${size.width.round()} wide', (
      tester,
    ) async {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({
        GameSettings.scrollHintSeenKey: true,
        GameSettings.tutorialSeenKey: true,
        AppSettings.languageKey: 'ar',
      });
      await pumpTitle(tester, size: size);
      await tester.tap(find.byKey(const Key('play_button')));
      await tester.pumpAndSettle();
      expect(
        directionOf(tester, find.byKey(const Key('doll'))),
        TextDirection.rtl,
      );
      expect(find.bySemanticsLabel('فاجئني'), findsOneWidget);
      expect(find.bySemanticsLabel('وضعية'), findsOneWidget);

      await tester.tap(find.byKey(const Key('activities_button')));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('إغلاق'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('إغلاق'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shop_button')));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('رجوع'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
