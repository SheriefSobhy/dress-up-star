import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/game_audio.dart';
import 'big_round_button.dart';

/// Asks "delete this?" with pictures only: a big check to delete, a big X
/// to keep. [picture] shows what would be deleted.
Future<bool> confirmDelete(
  BuildContext context,
  GameAudio audio, {
  Widget? picture,
}) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (picture != null) ...[picture, const SizedBox(height: 12)],
            const Icon(
              Icons.delete_rounded,
              size: 64,
              color: Color(0xFFB79CFF),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                BigRoundButton(
                  key: const Key('delete_no'),
                  icon: Icons.close_rounded,
                  color: const Color(0xFF8EE08A),
                  semanticLabel: AppStrings.of(context).keep,
                  onTap: () {
                    audio.play(Sfx.tap);
                    Navigator.pop(context, false);
                  },
                ),
                BigRoundButton(
                  key: const Key('delete_yes'),
                  icon: Icons.check_rounded,
                  color: const Color(0xFFFF6B8B),
                  semanticLabel: AppStrings.of(context).delete,
                  onTap: () => Navigator.pop(context, true),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return yes ?? false;
}
