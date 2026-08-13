import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_colors.dart';

class SocialMediaSettingsScreen extends StatefulWidget {
  const SocialMediaSettingsScreen({super.key});

  @override
  State<SocialMediaSettingsScreen> createState() =>
      _SocialMediaSettingsScreenState();
}

class _SocialMediaSettingsScreenState extends State<SocialMediaSettingsScreen> {
  final _websiteCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSocialMediaLinks();
  }

  @override
  void dispose() {
    _websiteCtrl.dispose();
    _facebookCtrl.dispose();
    _instagramCtrl.dispose();
    _youtubeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSocialMediaLinks() async {
    try {
      final res = await http
          .get(
            Uri.parse(
                'https://app.trimbakeshwarpoojavidhi.in/api/settings/social-media'),
          )
          .timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() => _loading = false);
      }
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? {};
        if (mounted) {
          setState(() {
            _websiteCtrl.text = data['website'] ?? '';
            _facebookCtrl.text = data['facebook'] ?? '';
            _instagramCtrl.text = data['instagram'] ?? '';
            _youtubeCtrl.text = data['youtube'] ?? '';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnack('Failed to load social media links');
      }
    }
  }

  Future<void> _saveSocialMediaLinks() async {
    setState(() => _saving = true);
    try {
      final res = await http
          .put(
            Uri.parse(
                'https://app.trimbakeshwarpoojavidhi.in/api/settings/social-media'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'website': _websiteCtrl.text.trim(),
              'facebook': _facebookCtrl.text.trim(),
              'instagram': _instagramCtrl.text.trim(),
              'youtube': _youtubeCtrl.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() => _saving = false);
      }
      if (res.statusCode == 200) {
        if (mounted) {
          _showSnack('Links updated successfully');
        }
      } else {
        if (mounted) {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          _showSnack(body['message'] ?? 'Failed to update links');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnack('Error saving social media links');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AdminColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Social Media Links',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your social media profile links to help users connect with you',
                    style: TextStyle(
                      fontSize: 14,
                      color: AdminColors.grey600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSocialField(
                    controller: _websiteCtrl,
                    label: 'Website',
                    icon: Icons.language_rounded,
                    hint: 'https://yourwebsite.com',
                    color: const Color(0xFF4285F4),
                  ),
                  const SizedBox(height: 20),
                  _buildSocialField(
                    controller: _facebookCtrl,
                    label: 'Facebook',
                    icon: Icons.facebook_rounded,
                    hint: 'https://facebook.com/yourpage',
                    color: const Color(0xFF1877F2),
                  ),
                  const SizedBox(height: 20),
                  _buildSocialField(
                    controller: _instagramCtrl,
                    label: 'Instagram',
                    icon: Icons.camera_alt_rounded,
                    hint: 'https://instagram.com/yourprofile',
                    color: const Color(0xFFE1306C),
                  ),
                  const SizedBox(height: 20),
                  _buildSocialField(
                    controller: _youtubeCtrl,
                    label: 'YouTube',
                    icon: Icons.play_circle_rounded,
                    hint: 'https://youtube.com/@yourchannel',
                    color: const Color(0xFFFF0000),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveSocialMediaLinks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSocialField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}
