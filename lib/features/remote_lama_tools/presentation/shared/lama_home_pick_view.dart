import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/ui/tokens.dart';

class LamaHomePickView extends StatelessWidget {
  final String title;
  final String hint;
  final String features;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  const LamaHomePickView({
    super.key,
    required this.title,
    required this.hint,
    required this.features,
    required this.onPickGallery,
    required this.onPickCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _heroCard(),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _actionBtn(
                icon: Icons.photo_library_outlined,
                label: 'Pick Gallery',
                onTap: onPickGallery,
              )),
              const SizedBox(width: 12),
              Expanded(child: _actionBtn(
                icon: Icons.photo_camera_outlined,
                label: 'Pick Camera',
                onTap: onPickCamera,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTokens.card,
        borderRadius: BorderRadius.circular(AppTokens.r20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text(hint, style: const TextStyle(color: AppTokens.text2)),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.auto_fix_high, color: AppTokens.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(features, style: const TextStyle(color: Colors.white54))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.r16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTokens.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
