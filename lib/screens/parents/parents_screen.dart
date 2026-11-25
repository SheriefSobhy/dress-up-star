import 'package:flutter/material.dart';

import '../../art/motion.dart';
import '../../l10n/app_strings.dart';
import '../../services/app_settings.dart';
import '../../services/frame_watcher.dart';
import '../../services/game_audio.dart';
import '../../services/game_settings.dart';

/// What the parents' screen asks the title screen to do when it closes.
enum ParentsResult { replayTutorial }

/// Settings for grown-ups (only opened through the parent gate): music,
/// sounds, language, lite mode, the tutorial, reset and the privacy policy.
class ParentsScreen extends StatelessWidget {
  const ParentsScreen({super.key, required this.audio, required this.settings});

  final GameAudio audio;
  final AppSettings settings;

  static const _ink = Color(0xFF4A3358);
  static const _accent = Color(0xFF8B5CC9);

  Future<void> _confirmReset(BuildContext context) async {
    final strings = AppStrings.of(context);
    final reset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('reset_dialog'),
        title: Text(strings.resetQuestion),
        content: Text(strings.resetWarning),
        actions: [
          TextButton(
            key: const Key('reset_cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            key: const Key('reset_confirm'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD9466F),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(strings.reset),
          ),
        ],
      ),
    );
    if (reset != true) return;
    await GameSettings.resetProgress();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('reset_done'),
        content: Text(strings.progressReset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      key: const Key('parents_screen'),
      backgroundColor: const Color(0xFFFFF4FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE3F1),
        foregroundColor: _ink,
        title: Text(strings.parentsTitle),
        leading: IconButton(
          key: const Key('parents_back'),
          tooltip: strings.back,
          icon: const BackButtonIcon(),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([audio, settings, GameMotion.lite]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: [
            _card([
              ListTile(
                leading: const Icon(Icons.verified_user_rounded),
                iconColor: const Color(0xFF3FAF6A),
                title: Text(
                  strings.noDataPromise,
                  style: const TextStyle(fontSize: 14, color: _ink),
                ),
              ),
            ]),
            _card([
              SwitchListTile(
                key: const Key('parents_music'),
                secondary: const Icon(Icons.music_note_rounded),
                title: Text(strings.music),
                value: audio.musicOn,
                activeThumbColor: _accent,
                onChanged: audio.setMusicOn,
              ),
              SwitchListTile(
                key: const Key('parents_sounds'),
                secondary: const Icon(Icons.volume_up_rounded),
                title: Text(strings.sounds),
                value: audio.soundsOn,
                activeThumbColor: _accent,
                onChanged: audio.setSoundsOn,
              ),
            ]),
            _card([
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: Text(
                  strings.language,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              _languageTile('language_system', strings.phoneLanguage, null),
              _languageTile('language_en', 'English', 'en'),
              _languageTile('language_ar', 'العربية', 'ar'),
            ]),
            _card([
              SwitchListTile(
                key: const Key('parents_lite'),
                secondary: const Icon(Icons.speed_rounded),
                title: Text(strings.fewerEffects),
                subtitle: Text(strings.fewerEffectsHint),
                isThreeLine: true,
                value: GameMotion.lite.value,
                activeThumbColor: _accent,
                onChanged: FrameWatcher.setLiteMode,
              ),
            ]),
            _card([
              ListTile(
                key: const Key('parents_replay_tutorial'),
                leading: const Icon(Icons.touch_app_rounded),
                title: Text(strings.replayTutorial),
                subtitle: Text(strings.replayTutorialHint),
                trailing: const Icon(Icons.play_arrow_rounded),
                onTap: () =>
                    Navigator.of(context).pop(ParentsResult.replayTutorial),
              ),
              ListTile(
                key: const Key('parents_privacy'),
                leading: const Icon(Icons.privacy_tip_rounded),
                title: Text(strings.privacyPolicy),
                subtitle: Text(strings.privacyPolicyHint),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
              ),
              ListTile(
                key: const Key('parents_reset'),
                leading: const Icon(Icons.restart_alt_rounded),
                iconColor: const Color(0xFFD9466F),
                title: Text(strings.resetProgress),
                subtitle: Text(strings.resetProgressHint),
                onTap: () => _confirmReset(context),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _languageTile(String key, String label, String? code) {
    final selected = settings.languageCode == code;
    return ListTile(
      key: Key(key),
      contentPadding: const EdgeInsetsDirectional.only(start: 56, end: 16),
      title: Text(label),
      selected: selected,
      selectedColor: _accent,
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? _accent : const Color(0xFFB8A9C6),
      ),
      onTap: () => settings.setLanguage(code),
    );
  }

  Widget _card(List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

/// The privacy policy, in the app's language. The same text is on the web
/// at [AppStrings.privacyPolicyUrl] (shown, not linked: no outside links).
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    const ink = Color(0xFF4A3358);
    return Scaffold(
      key: const Key('privacy_screen'),
      backgroundColor: const Color(0xFFFFF4FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE3F1),
        foregroundColor: ink,
        title: Text(strings.privacyPolicy),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          for (final (heading, text) in strings.privacyPolicyText) ...[
            Text(
              heading,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.45, color: ink),
            ),
            const SizedBox(height: 18),
          ],
          // Plain text: a selectable one would offer "search the web".
          const Text(
            AppStrings.privacyPolicyUrl,
            textDirection: TextDirection.ltr,
            style: TextStyle(fontSize: 13, color: Color(0xFF8B6F9C)),
          ),
        ],
      ),
    );
  }
}
