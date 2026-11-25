import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The language the parents picked (saved on the device). Without a choice
/// the game follows the phone's language.
class AppSettings extends ChangeNotifier {
  /// 'en' or 'ar'; missing means "the phone's language".
  static const languageKey = 'language';

  String? _languageCode;

  /// The chosen language, or null to follow the phone.
  String? get languageCode => _languageCode;

  /// The locale to show (null: the phone's language).
  Locale? get locale => _languageCode == null ? null : Locale(_languageCode!);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(languageKey);
    _languageCode = (saved == 'en' || saved == 'ar') ? saved : null;
    notifyListeners();
  }

  /// [code] is 'en', 'ar' or null (the phone's language).
  Future<void> setLanguage(String? code) async {
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(languageKey);
    } else {
      await prefs.setString(languageKey, code);
    }
  }

  /// Arabic phones get Arabic, every other phone gets English.
  static Locale resolve(Locale? phone) =>
      phone?.languageCode == 'ar' ? const Locale('ar') : const Locale('en');
}
