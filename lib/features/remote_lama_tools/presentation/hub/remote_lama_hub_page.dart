import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/hub/remote_lama_hub_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';

class RemoteLamaHubPage extends StatefulWidget {
  const RemoteLamaHubPage({super.key});

  @override
  State<RemoteLamaHubPage> createState() => _RemoteLamaHubPageState();
}

class _RemoteLamaHubPageState extends State<RemoteLamaHubPage> {
  @override
  void initState() {
    super.initState();
    context.read<RemoteLamaHubCubit>().loadServerStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LamaTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
        title: const Text(
          'Remote LaMa Studio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: LamaTheme.toolbarBg,
        elevation: 0,
      ),
      body: BlocBuilder<RemoteLamaHubCubit, LamaHubState>(
        builder: (context, state) => _buildHubContent(context, state),
      ),
    );
  }

  Widget _buildHubContent(BuildContext context, LamaHubState state) {
    final supportedModes = (state is LamaHubLoaded)
        ? state.capabilities.supportedModes
        : <String>[
            'heal_region',
            'repair_damage',
            'expand_canvas',
            'clean_edges'
          ];
    final canRepairDamage = supportedModes.contains('repair_damage');
    final canCleanEdges = supportedModes.contains('clean_edges');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildServerStatusCard(state),
          const SizedBox(height: 28),
          const Text(
            'New Tools',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Production flows added on top of the existing backend modes already supported by the app.',
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            title: 'Descratch Restore',
            description:
                'Remote scratch and damage restoration mapped to repair_damage for old photos and damaged surfaces.',
            icon: Icons.auto_fix_high_rounded,
            route: '/lama/descratch',
            isSupported: canRepairDamage,
            badge: 'Uses repair_damage',
          ),
          _buildToolCard(
            context,
            title: 'Background Cleanup',
            description:
                'Boundary cleanup and background-prep workflow mapped to clean_edges for compositing-ready results.',
            icon: Icons.layers_clear_rounded,
            route: '/lama/background',
            isSupported: canCleanEdges,
            badge: 'Uses clean_edges',
          ),
          const SizedBox(height: 28),
          const Text(
            'Existing Tools',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            title: 'Heal Region',
            description:
                'Small repair flow using image + optional mask + heal radius.',
            icon: Icons.healing,
            route: '/lama/heal',
            isSupported: supportedModes.contains('heal_region'),
          ),
          _buildToolCard(
            context,
            title: 'Repair Damage',
            description:
                'Repair damaged or missing region based on required mask.',
            icon: Icons.build_circle,
            route: '/lama/repair',
            isSupported: canRepairDamage,
          ),
          _buildToolCard(
            context,
            title: 'Expand Canvas',
            description: 'Outpainting by extending the canvas from the edges.',
            icon: Icons.crop_free,
            route: '/lama/expand',
            isSupported: supportedModes.contains('expand_canvas'),
          ),
          _buildToolCard(
            context,
            title: 'Clean Edges',
            description: 'Second-pass edge cleanup around mask boundaries.',
            icon: Icons.blur_on,
            route: '/lama/clean',
            isSupported: canCleanEdges,
          ),
        ],
      ),
    );
  }

  Widget _buildServerStatusCard(LamaHubState state) {
    var status = 'Unknown';
    var detail = 'Checking connection...';
    var statusColor = Colors.white54;
    var icon = Icons.cloud_sync;
    final isError = state is LamaHubError;

    if (state is LamaHubLoading) {
      status = 'Connecting...';
    } else if (state is LamaHubLoaded) {
      status = state.health.ok ? 'Connected & Healthy' : 'Degraded';
      detail =
          'Workers: ${state.health.workers} | Device: ${state.health.device}';
      statusColor = state.health.ok ? LamaTheme.accent : Colors.redAccent;
      icon = state.health.ok ? Icons.cloud_done : Icons.cloud_off;
    } else if (state is LamaHubError) {
      status = 'Offline / Unreachable';
      detail = 'Server might be closed or IP is wrong.';
      statusColor = Colors.redAccent;
      icon = Icons.cloud_off;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LamaTheme.toolbarBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Backend Status',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  status,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(detail,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                if (isError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () =>
                          context.read<RemoteLamaHubCubit>().loadServerStatus(),
                      child: const Text(
                        'Try Reconnect',
                        style: TextStyle(
                          color: LamaTheme.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (state is LamaHubLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: LamaTheme.accent),
            ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required String route,
    required bool isSupported,
    String? badge,
  }) {
    return Opacity(
      opacity: isSupported ? 1 : 0.5,
      child: Card(
        color: LamaTheme.toolbarBg,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isSupported ? () => context.go(route) : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LamaTheme.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: LamaTheme.accent, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                    color: LamaTheme.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(description,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.4)),
                      if (!isSupported)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Not supported by current backend',
                            style:
                                TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: isSupported ? Colors.white54 : Colors.transparent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
