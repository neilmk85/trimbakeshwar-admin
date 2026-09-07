import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../l10n/tr.dart';
import '../services/locale_service.dart';
import 'admin_rooms_screen.dart';
import 'call_integration_setup_screen.dart';
import 'gurujis_screen.dart';
import 'poojas_screen.dart';
import 'reports_screen.dart';
import 'room_blocks_screen.dart';
import 'social_media_settings_screen.dart';
import 'unknown_callers_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(tr('Manage', 'प्रबंधन')),
        const SizedBox(height: 10),
        _SettingsCard(
          icon: Icons.auto_awesome_rounded,
          color: AdminColors.primary,
          title: tr('Poojas', 'पूजाएं'),
          subtitle: tr('Enable/disable poojas and edit pricing', 'पूजाएं चालू/बंद करें और कीमत बदलें'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _FullScreenPage(
                title: tr('Poojas', 'पूजाएं'),
                child: const PoojasScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: Icons.groups_rounded,
          color: const Color(0xFF6A1B9A),
          title: tr('Gurujis', 'गुरुजी'),
          subtitle: tr('Manage Gurujis and set per-Guruji pooja rates', 'गुरुजी जोड़ें और उनकी पूजा दरें तय करें'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _FullScreenPage(
                title: tr('Gurujis', 'गुरुजी'),
                child: const GurujisScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: Icons.bar_chart_rounded,
          color: const Color(0xFF00838F),
          title: tr('Reports', 'रिपोर्ट'),
          subtitle: tr('Revenue summaries and booking statistics', 'आय का सार और बुकिंग आंकड़े'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _FullScreenPage(
                title: tr('Reports', 'रिपोर्ट'),
                child: const ReportsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: Icons.bed_rounded,
          color: const Color(0xFF00695C),
          title: tr('Rooms', 'कमरे'),
          subtitle: tr('Add, edit and manage available room listings', 'उपलब्ध कमरों को जोड़ें, बदलें और प्रबंधित करें'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _FullScreenPage(
                title: tr('Rooms', 'कमरे'),
                child: const AdminRoomsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: Icons.meeting_room_rounded,
          color: const Color(0xFFEF6C00),
          title: tr('Room Availability', 'कमरों की उपलब्धता'),
          subtitle: tr('Block rooms for walk-in guests and view live occupancy', 'सीधे आए मेहमानों के लिए कमरे रोकें और मौजूदा स्थिति देखें'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _FullScreenPage(
                title: tr('Room Availability', 'कमरों की उपलब्धता'),
                child: const RoomBlocksScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: Icons.call_rounded,
          color: const Color(0xFF2E7D32),
          title: tr('Call Auto-Reply', 'कॉल ऑटो-रिप्लाई'),
          subtitle: tr('Auto SMS and WhatsApp for missed, received and rejected calls',
              'मिस्ड, रिसीव्ड और रिजेक्टेड कॉल के लिए ऑटो SMS और WhatsApp'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _FullScreenPage(
                title: tr('Call Auto-Reply', 'कॉल ऑटो-रिप्लाई'),
                child: const CallIntegrationSetupScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: Icons.person_search_rounded,
          color: const Color(0xFF6A1B9A),
          title: tr('Unknown Callers', 'अज्ञात कॉलर'),
          subtitle: tr('Callers not in your customer list — save them as customers',
              'ऐसे कॉलर जो आपकी ग्राहक सूची में नहीं हैं — उन्हें ग्राहक के रूप में सेव करें'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _FullScreenPage(
                title: tr('Unknown Callers', 'अज्ञात कॉलर'),
                child: const UnknownCallersScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle(tr('Customize', 'कस्टमाइज़ करें')),
        const SizedBox(height: 10),
        _SettingsCard(
          icon: Icons.language_rounded,
          color: const Color(0xFF00838F),
          title: tr('Language', 'भाषा'),
          subtitle: LocaleService.isHindi
              ? 'हिंदी (Hindi)'
              : LocaleService.isMarathi
                  ? 'मराठी (Marathi)'
                  : 'English',
          onTap: () => _showLanguagePicker(context),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: Icons.share_rounded,
          color: const Color(0xFF6366F1),
          title: tr('Social Media', 'सोशल मीडिया'),
          subtitle: tr('Add Facebook, Instagram and YouTube links', 'Facebook, Instagram और YouTube लिंक जोड़ें'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _FullScreenPage(
                title: tr('Social Media Links', 'सोशल मीडिया लिंक'),
                child: const SocialMediaSettingsScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(tr('App Language', 'ऐप की भाषा'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            ...[
              ('en', 'English'),
              ('hi', 'हिंदी (Hindi)'),
              ('mr', 'मराठी (Marathi)'),
            ].map(
              (lang) => ListTile(
                title: Text(lang.$2),
                trailing: LocaleService.languageCode == lang.$1
                    ? const Icon(Icons.check_rounded, color: AdminColors.primary)
                    : null,
                onTap: () {
                  LocaleService.setLanguage(lang.$1);
                  Navigator.pop(sheetContext);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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

