import 'package:flutter/material.dart';

import '../models/outfit.dart';
import '../painting/doll_painter.dart';
import '../services/looks_storage.dart';
import '../widgets/big_round_button.dart';

/// "My Looks": every saved outfit. Tap one to wear it again.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, required this.storage});

  final LooksStorage storage;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Outfit>? _looks;

  @override
  void initState() {
    super.initState();
    widget.storage.load().then((looks) {
      if (mounted) setState(() => _looks = looks);
    });
  }

  Future<void> _delete(int index) async {
    // Ask with pictures only: a big check to delete, a big X to keep.
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    semanticLabel: 'Keep',
                    onTap: () => Navigator.pop(context, false),
                  ),
                  BigRoundButton(
                    key: const Key('delete_yes'),
                    icon: Icons.check_rounded,
                    color: const Color(0xFFFF6B8B),
                    semanticLabel: 'Delete',
                    onTap: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (yes != true) return;
    final looks = await widget.storage.removeAt(index);
    if (mounted) setState(() => _looks = looks);
  }

  @override
  Widget build(BuildContext context) {
    final looks = _looks;
    return Scaffold(
      backgroundColor: const Color(0xFFFFEAF5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  BigRoundButton(
                    key: const Key('back_button'),
                    icon: Icons.arrow_back_rounded,
                    color: const Color(0xFFB79CFF),
                    semanticLabel: 'Back',
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.photo_library_rounded,
                    size: 44,
                    color: Color(0xFFFF8FC7),
                  ),
                  const Spacer(),
                  const SizedBox(width: 64),
                ],
              ),
            ),
            Expanded(
              child: looks == null
                  ? const SizedBox.shrink()
                  : looks.isEmpty
                  ? const Center(
                      key: Key('gallery_empty'),
                      child: Icon(
                        Icons.photo_camera_rounded,
                        size: 120,
                        color: Color(0xFFFFC2DF),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 190,
                            childAspectRatio: 0.62,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemCount: looks.length,
                      itemBuilder: (context, i) => _lookCard(looks[i], i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lookCard(Outfit look, int index) {
    return GestureDetector(
      key: Key('look_$index'),
      onTap: () => Navigator.pop(context, look),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: CustomPaint(painter: DollPainter(outfit: look)),
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 6,
            child: GestureDetector(
              key: Key('delete_$index'),
              onTap: () => _delete(index),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFFB0A0C0),
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
