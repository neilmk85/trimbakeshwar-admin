import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/app_colors.dart';
import '../services/guruji_auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: GurujiAuthService.loggedInName ?? '');
    _emailCtrl =
        TextEditingController(text: GurujiAuthService.loggedInEmail ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    if (name.isEmpty || email.isEmpty) {
      _showSnack('Name and email cannot be empty');
      return;
    }
    setState(() => _saving = true);
    final error = await _updateProfile(
      phone: GurujiAuthService.loggedInPhone ?? '',
      name: name,
      email: email,
      password: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
    );
    if (mounted) {
      setState(() => _saving = false);
      if (error != null) {
        _showSnack(error);
      } else {
        // Update local state
        GurujiAuthService.loggedInName = name;
        GurujiAuthService.loggedInEmail = email;
        setState(() => _editing = false);
        _passwordCtrl.clear();
        _showSnack('Profile updated successfully');
      }
    }
  }

  Future<String?> _updateProfile({
    required String phone,
    required String name,
    required String email,
    String? password,
  }) async {
    try {
      final body = <String, dynamic>{'name': name, 'email': email};
      if (password != null && password.isNotEmpty) body['password'] = password;

      final res = await http
          .put(
            Uri.parse('https://app.trimbakeshwarpoojavidhi.in/api/guruji/auth/profile/$phone'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      final respBody = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && respBody['success'] == true) return null;
      return respBody['message'] as String? ?? 'Update failed';
    } catch (_) {
      return 'Could not reach server';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 24),
          _buildForm(),
          const SizedBox(height: 16),
          if (_editing) ...[
            _actionButton(
              label: 'Save Changes',
              loading: _saving,
              onTap: _save,
              color: AdminColors.primary,
            ),
            const SizedBox(height: 10),
            _actionButton(
              label: 'Cancel',
              onTap: () {
                setState(() {
                  _editing = false;
                  _nameCtrl.text = GurujiAuthService.loggedInName ?? '';
                  _emailCtrl.text = GurujiAuthService.loggedInEmail ?? '';
                  _passwordCtrl.clear();
                });
              },
              color: AdminColors.grey500,
            ),
          ] else
            _actionButton(
              label: 'Edit Profile',
              onTap: () => setState(() => _editing = true),
              color: AdminColors.primary,
              outlined: true,
            ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          _logoutButton(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    final name = GurujiAuthService.loggedInName ?? '';
    final parts = name.trim().split(' ');
    String initials = 'G';
    if (parts.length >= 2) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      initials = name[0].toUpperCase();
    }

    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AdminColors.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          GurujiAuthService.loggedInName ?? '',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AdminColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Guruji',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdminColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Profile Information',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.grey800)),
          const SizedBox(height: 16),
          _field(
            controller: _nameCtrl,
            label: 'Full Name',
            icon: Icons.person_outline_rounded,
            enabled: _editing,
          ),
          const SizedBox(height: 14),
          _field(
            controller: _emailCtrl,
            label: 'Email',
            icon: Icons.email_outlined,
            enabled: _editing,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _field(
            controller: TextEditingController(
                text: GurujiAuthService.loggedInPhone ?? ''),
            label: 'Phone',
            icon: Icons.phone_outlined,
            enabled: false,
          ),
          if (_editing) ...[
            const SizedBox(height: 14),
            _field(
              controller: _passwordCtrl,
              label: 'New Password (optional)',
              icon: Icons.lock_outlined,
              enabled: true,
              obscureText: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: AdminColors.grey500,
                    size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AdminColors.primary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AdminColors.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AdminColors.grey300),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AdminColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AdminColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback onTap,
    required Color color,
    bool loading = false,
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
            )
          : ElevatedButton(
              onPressed: loading ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
    );
  }

  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: GurujiAuthService.logout,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Logout',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade600,
          side: BorderSide(color: Colors.red.shade300),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
