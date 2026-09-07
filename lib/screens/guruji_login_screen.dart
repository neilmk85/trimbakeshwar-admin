import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../l10n/tr.dart';
import '../services/guruji_auth_service.dart';
import 'guruji_register_screen.dart';

class GurujiLoginScreen extends StatefulWidget {
  const GurujiLoginScreen({super.key});

  @override
  State<GurujiLoginScreen> createState() => _GurujiLoginScreenState();
}

class _GurujiLoginScreenState extends State<GurujiLoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // OTP tab
  final _otpPhoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _otpLoading = false;

  // Email tab
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _pwdObscure = true;
  bool _emailLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _otpPhoneCtrl.dispose();
    _otpCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _otpPhoneCtrl.text.trim();
    if (phone.length < 10) {
      _showSnack(
        tr(
          'Please enter a valid 10-digit phone number',
          'कृपया सही 10 अंकों का फ़ोन नंबर डालें',
          'कृपया योग्य 10 अंकी फोन नंबर टाका',
        ),
      );
      return;
    }
    setState(() => _otpLoading = true);
    final error = await GurujiAuthService.sendOtp(phone);
    if (mounted) {
      setState(() {
        _otpSent = error == null; // null means success
        _otpLoading = false;
      });
    }
    if (error == null) {
      _showSnack(
        tr(
          'OTP sent to WhatsApp!',
          'OTP WhatsApp पर भेजा गया!',
          'OTP WhatsApp वर पाठवला गेला!',
        ),
        duration: 4,
      );
    } else if (error.contains('not authorized')) {
      _showSnack(error, duration: 4);
    } else {
      _showNotRegisteredToast();
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _otpPhoneCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (otp.length != 4) {
      _showSnack(
        tr(
          'Please enter the 4-digit OTP',
          'कृपया 4 अंकों का OTP डालें',
          'कृपया 4 अंकी OTP टाका',
        ),
      );
      return;
    }
    setState(() => _otpLoading = true);
    final error = await GurujiAuthService.verifyOtp(phone, otp);
    if (mounted) setState(() => _otpLoading = false);
    if (error != null && mounted) _showSnack(error);
  }

  Future<void> _loginWithEmail() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _showSnack(
        tr(
          'Please enter email and password',
          'कृपया ईमेल और पासवर्ड डालें',
          'कृपया ईमेल आणि पासवर्ड टाका',
        ),
      );
      return;
    }
    setState(() => _emailLoading = true);
    final error = await GurujiAuthService.loginWithEmail(email, password);
    if (mounted) setState(() => _emailLoading = false);
    if (error != null && mounted) {
      if (error == 'User not registered') {
        _showNotRegisteredToast();
      } else {
        _showSnack(error);
      }
    }
  }

  void _showNotRegisteredToast() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF9800),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_off_rounded,
                    color: Color(0xFFFF9800),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  tr(
                    'User Not Registered',
                    'यूज़र रजिस्टर्ड नहीं है',
                    'वापरकर्ता नोंदणीकृत नाही',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr(
                    'No account found with these credentials.\nPlease register as a Guruji first.',
                    'इन जानकारियों से कोई खाता नहीं मिला।\nकृपया पहले गुरुजी के रूप में रजिस्टर करें।',
                    'या माहितीने कोणतेही खाते सापडले नाही.\nकृपया आधी गुरुजी म्हणून नोंदणी करा.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          tr('Close', 'बंद करें', 'बंद करा'),
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GurujiRegisterScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          tr('Register', 'रजिस्टर करें', 'नोंदणी करा'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: Duration(seconds: duration),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Center(
                child: Text(
                  'ॐ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              tr(
                'Trimbakeshwar Guruji',
                'Trimbakeshwar गुरुजी',
                'Trimbakeshwar गुरुजी',
              ),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: tr('OTP Login', 'OTP लॉगिन', 'OTP लॉगिन')),
            Tab(text: tr('Email Login', 'ईमेल लॉगिन', 'ईमेल लॉगिन')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOtpTab(), _buildEmailTab()],
      ),
    );
  }

  Widget _buildOtpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _sectionIcon(),
          const SizedBox(height: 24),
          _inputField(
            controller: _otpPhoneCtrl,
            label: tr('Phone Number', 'फ़ोन नंबर', 'फोन नंबर'),
            hint: tr(
              '10-digit mobile number',
              '10 अंकों का मोबाइल नंबर',
              '10 अंकी मोबाइल नंबर',
            ),
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            enabled: !_otpSent,
          ),
          const SizedBox(height: 16),
          if (!_otpSent)
            _primaryButton(
              label: tr('Get OTP', 'OTP प्राप्त करें', 'OTP मिळवा'),
              loading: _otpLoading,
              onTap: _sendOtp,
            )
          else ...[
            _inputField(
              controller: _otpCtrl,
              label: tr('Enter OTP', 'OTP डालें', 'OTP टाका'),
              hint: tr('4-digit OTP', '4 अंकों का OTP', '4 अंकी OTP'),
              icon: Icons.lock_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() {
                _otpSent = false;
                _otpCtrl.clear();
              }),
              child: Text(
                tr(
                  'Change Number / Resend OTP',
                  'नंबर बदलें / OTP फिर भेजें',
                  'नंबर बदला / OTP पुन्हा पाठवा',
                ),
                style: TextStyle(color: AdminColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            _primaryButton(
              label: tr(
                'Verify & Login',
                'सत्यापित करें और लॉगिन करें',
                'सत्यापित करा आणि लॉगिन करा',
              ),
              loading: _otpLoading,
              onTap: _verifyOtp,
            ),
          ],
          const SizedBox(height: 32),
          _registerLink(),
        ],
      ),
    );
  }

  Widget _buildEmailTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _sectionIcon(),
          const SizedBox(height: 24),
          _inputField(
            controller: _emailCtrl,
            label: tr('Email', 'ईमेल', 'ईमेल'),
            hint: tr(
              'Enter your email address',
              'अपना ईमेल पता डालें',
              'तुमचा ईमेल पत्ता टाका',
            ),
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _inputField(
            controller: _passwordCtrl,
            label: tr('Password', 'पासवर्ड', 'पासवर्ड'),
            hint: tr(
              'Enter your password',
              'अपना पासवर्ड डालें',
              'तुमचा पासवर्ड टाका',
            ),
            icon: Icons.lock_outlined,
            obscureText: _pwdObscure,
            suffixIcon: IconButton(
              icon: Icon(
                _pwdObscure ? Icons.visibility_off : Icons.visibility,
                color: AdminColors.grey500,
                size: 20,
              ),
              onPressed: () => setState(() => _pwdObscure = !_pwdObscure),
            ),
          ),
          const SizedBox(height: 24),
          _primaryButton(
            label: tr('Login', 'लॉगिन', 'लॉगिन'),
            loading: _emailLoading,
            onTap: _loginWithEmail,
          ),
          const SizedBox(height: 32),
          _registerLink(),
        ],
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
          child: Text(
            'ॐ',
            style: TextStyle(
              fontSize: 32,
              color: AdminColors.primary,
              fontWeight: FontWeight.w300,
            ),
          ),
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
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AdminColors.primary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _registerLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          tr('New Guruji?', 'नए गुरुजी हैं?', 'नवीन गुरुजी आहात?'),
          style: TextStyle(color: AdminColors.grey700, fontSize: 14),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GurujiRegisterScreen()),
          ),
          child: Text(
            tr('Register', 'रजिस्टर करें', 'नोंदणी करा'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AdminColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
