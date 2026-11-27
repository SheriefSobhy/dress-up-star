import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Every word in the game, in English and Arabic.
///
/// The game itself has no reading: these are the parents' screens and the
/// spoken labels of the buttons (for screen readers). The game's name,
/// "Dress Up Star", stays the same in every language.
class AppStrings {
  const AppStrings._(this.languageCode, this._words);

  final String languageCode;
  final Map<String, String> _words;

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static const english = AppStrings._('en', _en);
  static const arabic = AppStrings._('ar', _ar);

  static AppStrings forLocale(Locale locale) =>
      locale.languageCode == 'ar' ? arabic : english;

  /// The strings for the language on screen (English outside the app).
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ?? english;

  static const LocalizationsDelegate<AppStrings> delegate = _Delegate();

  bool get isArabic => languageCode == 'ar';

  String _get(String key) => _words[key] ?? _en[key]!;

  // Game buttons (spoken by screen readers).
  String get appName => 'Dress Up Star';
  String get play => _get('play');
  String get close => _get('close');
  String get done => _get('done');
  String get back => _get('back');
  String get keep => _get('keep');
  String get delete => _get('delete');
  String get myLooks => _get('myLooks');
  String get surpriseMe => _get('surpriseMe');
  String get saveLook => _get('saveLook');
  String get soundOn => _get('soundOn');
  String get soundOff => _get('soundOff');
  String get dance => _get('dance');
  String get pose => _get('pose');
  String get editDoll => _get('editDoll');
  String get newDoll => _get('newDoll');
  String get doll => _get('doll');
  String get randomDoll => _get('randomDoll');
  String get activities => _get('activities');
  String get challenge => _get('challenge');
  String get starShop => _get('starShop');
  String get anotherCard => _get('anotherCard');
  String get start => _get('start');
  String get undoAll => _get('undoAll');
  String get bringItBack => _get('bringItBack');
  String get growBack => _get('growBack');
  String get skip => _get('skip');

  // Parent gate.
  String get parents => _get('parents');
  String get holdForParents => _get('holdForParents');
  String get grownUpsOnly => _get('grownUpsOnly');
  String mathQuestion(int a, int b) =>
      _get('mathQuestion').replaceAll('{a}', '$a').replaceAll('{b}', '$b');
  String get tryAgain => _get('tryAgain');
  String get cancel => _get('cancel');
  String get ok => _get('ok');
  String get clear => _get('clear');

  // Parents' screen.
  String get parentsTitle => _get('parentsTitle');
  String get music => _get('music');
  String get sounds => _get('sounds');
  String get language => _get('language');
  String get phoneLanguage => _get('phoneLanguage');
  String get fewerEffects => _get('fewerEffects');
  String get fewerEffectsHint => _get('fewerEffectsHint');
  String get replayTutorial => _get('replayTutorial');
  String get replayTutorialHint => _get('replayTutorialHint');
  String get resetProgress => _get('resetProgress');
  String get resetProgressHint => _get('resetProgressHint');
  String get resetQuestion => _get('resetQuestion');
  String get resetWarning => _get('resetWarning');
  String get reset => _get('reset');
  String get progressReset => _get('progressReset');
  String get privacyPolicy => _get('privacyPolicy');
  String get privacyPolicyHint => _get('privacyPolicyHint');
  String get noDataPromise => _get('noDataPromise');

  /// The privacy policy, as (heading, text) pairs.
  List<(String, String)> get privacyPolicyText =>
      isArabic ? _privacyAr : _privacyEn;

  /// Where the same policy is published on the web.
  static const privacyPolicyUrl =
      'https://sheriefsobhy.github.io/dress-up-star/privacy.html';

  static const _en = {
    'play': 'Play',
    'close': 'Close',
    'done': 'Done',
    'back': 'Back',
    'keep': 'Keep',
    'delete': 'Delete',
    'myLooks': 'My looks',
    'surpriseMe': 'Surprise me',
    'saveLook': 'Save look',
    'editDoll': 'Change my doll',
    'newDoll': 'New doll',
    'doll': 'Doll',
    'randomDoll': 'Random',
    'soundOn': 'Sound on',
    'soundOff': 'Sound off',
    'dance': 'Dance',
    'pose': 'Pose',
    'activities': 'Activities',
    'challenge': 'Challenge',
    'starShop': 'Star Shop',
    'anotherCard': 'Another card',
    'start': 'Start',
    'undoAll': 'Undo all',
    'bringItBack': 'Bring it back',
    'growBack': 'Grow back',
    'skip': 'Skip',
    'parents': 'Parents',
    'holdForParents': 'Parents: hold for 3 seconds',
    'grownUpsOnly': 'For grown-ups',
    'mathQuestion': 'What is {a} × {b}?',
    'tryAgain': 'Not quite. Try this one.',
    'cancel': 'Cancel',
    'ok': 'OK',
    'clear': 'Clear',
    'parentsTitle': 'Parents',
    'music': 'Music',
    'sounds': 'Sound effects',
    'language': 'Language',
    'phoneLanguage': 'Phone language',
    'fewerEffects': 'Fewer effects',
    'fewerEffectsHint':
        'Turns off moving clouds, sparkles and other heavy effects so the '
        'game stays smooth on older phones. Turns on by itself when needed.',
    'replayTutorial': 'Show the how-to-play again',
    'replayTutorialHint': 'The pointing finger shows how to play.',
    'resetProgress': 'Reset progress',
    'resetProgressHint': 'Stars, unlocked items, saved looks and dolls.',
    'resetQuestion': 'Reset all progress?',
    'resetWarning':
        'This removes all stars, Star Shop items and saved looks on this '
        'device. It cannot be undone.',
    'reset': 'Reset',
    'progressReset': 'Progress was reset.',
    'privacyPolicy': 'Privacy policy',
    'privacyPolicyHint': 'This game collects no data.',
    'noDataPromise':
        'No ads. No in-app purchases. No data collected. No internet needed.',
  };

  static const _ar = {
    'play': 'العب',
    'close': 'إغلاق',
    'done': 'تم',
    'back': 'رجوع',
    'keep': 'احتفظ',
    'delete': 'حذف',
    'myLooks': 'إطلالاتي',
    'surpriseMe': 'فاجئني',
    'saveLook': 'احفظ الإطلالة',
    'editDoll': 'غيّري دميتي',
    'newDoll': 'دمية جديدة',
    'doll': 'دمية',
    'randomDoll': 'عشوائي',
    'soundOn': 'الصوت يعمل',
    'soundOff': 'الصوت مغلق',
    'dance': 'رقص',
    'pose': 'وضعية',
    'activities': 'أنشطة',
    'challenge': 'تحدٍّ',
    'starShop': 'متجر النجوم',
    'anotherCard': 'بطاقة أخرى',
    'start': 'ابدأ',
    'undoAll': 'امسح الكل',
    'bringItBack': 'أرجعه',
    'growBack': 'طوّل الشعر',
    'skip': 'تخطَّ',
    'parents': 'الوالدان',
    'holdForParents': 'للوالدين: اضغط مطولًا 3 ثوانٍ',
    'grownUpsOnly': 'للكبار فقط',
    'mathQuestion': 'كم يساوي {a} × {b}؟',
    'tryAgain': 'ليست صحيحة. جرّب هذه.',
    'cancel': 'إلغاء',
    'ok': 'موافق',
    'clear': 'مسح',
    'parentsTitle': 'إعدادات الوالدين',
    'music': 'الموسيقى',
    'sounds': 'المؤثرات الصوتية',
    'language': 'اللغة',
    'phoneLanguage': 'لغة الهاتف',
    'fewerEffects': 'مؤثرات أقل',
    'fewerEffectsHint':
        'يوقف حركة السحب واللمعان والمؤثرات الثقيلة الأخرى لتبقى اللعبة '
        'سلسة على الهواتف القديمة. يعمل تلقائيًا عند الحاجة.',
    'replayTutorial': 'اعرض طريقة اللعب مرة أخرى',
    'replayTutorialHint': 'إصبع يشير ويوضح طريقة اللعب.',
    'resetProgress': 'إعادة ضبط التقدم',
    'resetProgressHint': 'النجوم والعناصر المفتوحة والإطلالات المحفوظة والدمى.',
    'resetQuestion': 'إعادة ضبط كل التقدم؟',
    'resetWarning':
        'سيؤدي هذا إلى حذف كل النجوم وعناصر متجر النجوم والإطلالات المحفوظة '
        'على هذا الجهاز. لا يمكن التراجع عن ذلك.',
    'reset': 'إعادة ضبط',
    'progressReset': 'تمت إعادة ضبط التقدم.',
    'privacyPolicy': 'سياسة الخصوصية',
    'privacyPolicyHint': 'هذه اللعبة لا تجمع أي بيانات.',
    'noDataPromise':
        'بلا إعلانات. بلا مشتريات داخل التطبيق. لا نجمع أي بيانات. لا تحتاج إلى إنترنت.',
  };

  static const _privacyEn = [
    (
      'Summary',
      'Dress Up Star does not collect, store on a server, or share any '
          'personal information or any other data. It has no ads, no '
          'analytics, no in-app purchases, no accounts and no links to '
          'websites or other apps.',
    ),
    (
      'What stays on the device',
      'The game remembers its own progress on the phone or tablet only: '
          'stars, unlocked Star Shop items, saved looks and settings such as '
          'music, sounds and language. This never leaves the device. '
          'Deleting the app, or "Reset progress" in the parents\' screen, '
          'removes it.',
    ),
    (
      'Permissions',
      'The Android app asks for no permissions. It does not use the '
          'internet, camera, microphone, location, contacts or photos.',
    ),
    (
      'Children',
      'The game is made for young children and follows the Google Play '
          'Families policy. Because no data is collected, no data from '
          'children is collected.',
    ),
    (
      'Changes and contact',
      'If this policy ever changes, the new version will be published at '
          'the same web address. Questions: please open an issue at '
          'github.com/SheriefSobhy/dress-up-star.',
    ),
  ];

  static const _privacyAr = [
    (
      'ملخص',
      'لعبة Dress Up Star لا تجمع أي معلومات شخصية أو أي بيانات أخرى، ولا '
          'تحفظها على أي خادم، ولا تشاركها مع أحد. لا توجد فيها إعلانات ولا '
          'أدوات تحليل ولا مشتريات داخل التطبيق ولا حسابات ولا روابط لمواقع '
          'أو تطبيقات أخرى.',
    ),
    (
      'ما يبقى على الجهاز',
      'تحفظ اللعبة تقدمها على الهاتف أو الجهاز اللوحي فقط: النجوم، وعناصر '
          'متجر النجوم المفتوحة، والإطلالات المحفوظة، والإعدادات مثل '
          'الموسيقى والأصوات واللغة. لا يغادر أي من ذلك الجهاز أبدًا. حذف '
          'اللعبة، أو "إعادة ضبط التقدم" في إعدادات الوالدين، يزيله.',
    ),
    (
      'الأذونات',
      'تطبيق أندرويد لا يطلب أي أذونات. لا يستخدم الإنترنت ولا الكاميرا ولا '
          'الميكروفون ولا الموقع ولا جهات الاتصال ولا الصور.',
    ),
    (
      'الأطفال',
      'اللعبة مصممة للأطفال الصغار وتتبع سياسة العائلات في \u2066Google Play\u2069. '
          'وبما أنه لا يتم جمع أي بيانات، فلا يتم جمع أي بيانات من الأطفال.',
    ),
    (
      'التغييرات والتواصل',
      'إذا تغيرت هذه السياسة، فسيُنشر الإصدار الجديد على العنوان نفسه. '
          'للأسئلة: يرجى فتح مشكلة (issue) على '
          // Kept in one left-to-right piece inside the Arabic sentence.
          '\u2066github.com/SheriefSobhy/dress-up-star\u2069.',
    ),
  ];

  /// Every key, so tests can check both languages are complete.
  @visibleForTesting
  static Map<String, String> wordsOf(String languageCode) =>
      languageCode == 'ar' ? _ar : _en;
}

class _Delegate extends LocalizationsDelegate<AppStrings> {
  const _Delegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings.forLocale(locale));

  @override
  bool shouldReload(_Delegate old) => false;
}
