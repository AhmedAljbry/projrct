import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/i18n/t.dart';
import '../../../../core/ui/tokens.dart';
import '../../application/image_pick_cubit.dart';

class HomePickPage extends StatelessWidget {
  const HomePickPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.read<T>();

    return Scaffold(
      appBar: AppBar(title: Text(t.of('pick_title'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocConsumer<ImagePickCubit, ImagePickState>(
          listener: (context, state) {
            if (state is ImagePickReady) {
              context.go('/editor');
            }
          },
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _heroCard(t),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(child: _actionBtn(
                      icon: Icons.photo_library_outlined,
                      label: t.of('pick_gallery'),
                      onTap: () => context.read<ImagePickCubit>().pickFromGallery(),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _actionBtn(
                      icon: Icons.photo_camera_outlined,
                      label: t.of('pick_camera'),
                      onTap: () => context.read<ImagePickCubit>().pickFromCamera(),
                    )),
                  ],
                ),

                const SizedBox(height: 14),

                if (state is ImagePickLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),

                if (state is ImagePickError)
                  Text(state.message, style: const TextStyle(color: AppTokens.danger)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _heroCard(T t) {
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
          Text(t.of('app_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(t.of('pick_hint'), style: const TextStyle(color: AppTokens.text2)),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.auto_fix_high, color: AppTokens.primary),
              SizedBox(width: 10),
              Expanded(child: Text('Pro Mask • Smooth Brush • Enterprise UX', style: TextStyle(color: Colors.white54))),
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
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}