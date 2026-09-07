import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../services/guruji_auth_service.dart';
import '../l10n/tr.dart';

class GurujiRegisterScreen extends StatefulWidget {
  const GurujiRegisterScreen({super.key});

  @override
  State<GurujiRegisterScreen> createState() => _GurujiRegisterScreenState();
}

class _GurujiRegisterScreenState extends State<GurujiRegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty || phone.length < 10 || email.isEmpty || password.isEmpty) {
      _showSnack(tr('Please fill in all fields correctly', 'कृपया सभी जानकारी सही तरीके से भरें', 'कृपया सर्व माहिती व्यवस्थित भरा'));
      return;
    }

    setState(() => _loading = true);
    final error = await GurujiAuthService.register(
      name: name,
      phone: phone,
      email: email,
      password: password,
    );
    if (mounted) setState(() => _loading = false);
    if (error != null && mounted) {
      _showSnack(error);
    } else if (mounted) {
      await _showSuccessOverlay(name);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _showSuccessOverlay(String name) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (_, anim, __, child) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 52),
                ),
                const SizedBox(height: 24),
                Text(
                  tr('Registration\nSuccessful!', 'रजिस्ट्रेशन\nसफल हुआ!', 'नोंदणी\nयशस्वी झाली!'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr('$name has been registered\nas a Guruji successfully.',
                      '$name को गुरुजी के रूप में\nसफलतापूर्वक रजिस्टर कर दिया गया है।',
                      '$name यांची गुरुजी म्हणून\nयशस्वीरित्या नोंदणी झाली आहे.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(tr('Continue', 'जारी रखें', 'सुरू ठेवा'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(tr('Register Guruji', 'गुरुजी रजिस्टर करें', 'गुरुजी नोंदणी करा'),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AdminColors.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _sectionIcon(),
            const SizedBox(height: 8),
            Text(
              tr('Create Guruji Account', 'गुरुजी खाता बनाएं', 'गुरुजी खाते तयार करा'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 4),
            Text(
              tr('Fill in the details below to register',
                  'रजिस्टर करने के लिए नीचे दी गई जानकारी भरें',
                  'नोंदणी करण्यासाठी खालील माहिती भरा'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AdminColors.grey600),
            ),
            const SizedBox(height: 28),
            _inputField(
              controller: _nameCtrl,
              label: tr('Full Name', 'पूरा नाम', 'पूर्ण नाव'),
              hint: tr('Enter full name', 'पूरा नाम दर्ज करें', 'पूर्ण नाव टाका'),
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
            _inputField(
              controller: _phoneCtrl,
              label: tr('Phone Number', 'फ़ोन नंबर', 'फोन नंबर'),
              hint: tr('10-digit mobile number', '10 अंकों का मोबाइल नंबर', '10 अंकी मोबाइल नंबर'),
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
            const SizedBox(height: 16),
            _inputField(
              controller: _emailCtrl,
              label: tr('Email', 'ईमेल', 'ईमेल'),
              hint: tr('Enter email address', 'ईमेल पता दर्ज करें', 'ईमेल पत्ता टाका'),
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _inputField(
              controller: _passwordCtrl,
              label: tr('Password', 'पासवर्ड', 'पासवर्ड'),
              hint: tr('Create a password', 'पासवर्ड बनाएं', 'पासवर्ड तयार करा'),
              icon: Icons.lock_outlined,
              obscureText: _obscure,
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: AdminColors.grey500,
                    size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 28),
            _primaryButton(
              label: tr('Register', 'रजिस्टर करें', 'नोंदणी करा'),
              loading: _loading,
              onTap: _register,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(tr('Already registered?', 'पहले से रजिस्टर्ड हैं?', 'आधीच नोंदणीकृत आहात?'),
                    style:
                        TextStyle(color: AdminColors.grey700, fontSize: 14)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(tr('Login', 'लॉगिन', 'लॉगिन'),
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AdminColors.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionIcon() {
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AdminColors.primaryMedium.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text('ॐ',
              style: TextStyle(
                  fontSize: 32,
                  color: AdminColors.primary,
                  fontWeight: FontWeight.w300)),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AdminColors.primary, size: 20),
        suffixIcon: suffixIcon,
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
          borderSide:
              const BorderSide(color: AdminColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
