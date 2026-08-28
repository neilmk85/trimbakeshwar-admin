import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'admin_rooms_screen.dart';
import 'gurujis_screen.dart';
import 'poojas_screen.dart';
import 'reports_screen.dart';
import 'room_blocks_screen.dart';
import 'social_media_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Manage'),
        const SizedBox(height: 10),
        _SettingsCard(
          icon: Icons.auto_awesome_rounded,
          color: AdminColors.primary,
          title: 'Poojas',
          subtitle: 'Enable/disable poojas and edit pricing',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const _FullScreenPage(
                title: 'Poojas',
                child: PoojasScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: Icons.groups_rounded,
          color: const Color(0xFF6A1B9A),
          title: 'Gurujis',
          subtitle: 'Manage Gurujis and set per-Guruji pooja rates',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const _FullScreenPage(
                title: 'Gurujis',
                child: GurujisScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFF00838F),
          title: 'Reports',
          subtitle: 'Revenue summaries and booking statistics',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const _FullScreenPage(
                title: 'Reports',
                child: ReportsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: Icons.bed_rounded,
          color: const Color(0xFF00695C),
          title: 'Rooms',
          subtitle: 'Add, edit and manage available room listings',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const _FullScreenPage(
                title: 'Rooms',
                child: AdminRoomsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: Icons.meeting_room_rounded,
          color: const Color(0xFFEF6C00),
          title: 'Room Availability',
          subtitle: 'Block rooms for walk-in guests and view live occupancy',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const _FullScreenPage(
                title: 'Room Availability',
                child: RoomBlocksScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Customize'),
        const SizedBox(height: 10),
        _SettingsCard(
          icon: Icons.share_rounded,
          color: const Color(0xFF6366F1),
          title: 'Social Media',
          subtitle: 'Add Facebook, Instagram and YouTube links',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const _FullScreenPage(
                title: 'Social Media Links',
                child: SocialMediaSettingsScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AdminColors.grey600,
          letterSpacing: 0.8),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 13, color: AdminColors.grey600)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AdminColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}

class _FullScreenPage extends StatelessWidget {
  final String title;
  final Widget child;
  const _FullScreenPage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
            colors: AdminColors.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: child,
    );
  }
}

