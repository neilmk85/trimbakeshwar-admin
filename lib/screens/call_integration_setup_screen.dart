import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';
import '../l10n/tr.dart';
import '../services/guruji_auth_service.dart';

/// Shared secret for the device-key gated POST /api/call-logs endpoint.
/// This app is already gated to a single authorized phone number
/// (see home_screen.dart), so embedding the key here mirrors the same
/// trust boundary as the rest of the app.
const String _callLogDeviceKey = '913456524e3b29ed7be82a07b58ce3583bab22e8bc75e5d4';

class CallIntegrationSetupScreen extends StatefulWidget {
  const CallIntegrationSetupScreen({super.key});

  @override
  State<CallIntegrationSetupScreen> createState() => _CallIntegrationSetupScreenState();
}

class _CallIntegrationSetupScreenState extends State<CallIntegrationSetupScreen>
    with WidgetsBindingObserver {
  static const _channel = MethodChannel('trimbakeshwar/call_integration');

  bool _loading = true;
  bool _enabled = false;
  bool _smsMissed = false;
  bool _smsReceived = false;
  bool _smsRejected = false;
  bool _waMissed = false;
  bool _waReceived = false;
  bool _waRejected = false;
  int _sendDelaySeconds = 0; // 0 = immediately, else a whole number of minutes in seconds

  bool _permissionsGranted = false;
  bool _batteryOptimizationIgnored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionStatus();
    }
  }

  Future<void> _load() async {
    try {
      final settings = await _channel.invokeMapMethod<String, dynamic>('getSettings');
      if (settings != null && mounted) {
        setState(() {
          _enabled = settings['enabled'] as bool? ?? false;
          _smsMissed = settings['smsMissed'] as bool? ?? false;
          _smsReceived = settings['smsReceived'] as bool? ?? false;
          _smsRejected = settings['smsRejected'] as bool? ?? false;
          _waMissed = settings['waMissed'] as bool? ?? false;
          _waReceived = settings['waReceived'] as bool? ?? false;
          _waRejected = settings['waRejected'] as bool? ?? false;
          _sendDelaySeconds = (settings['sendDelaySeconds'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {
      // Native side unavailable (e.g. running on iOS) — leave defaults.
    }
    await _refreshPermissionStatus();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshPermissionStatus() async {
    bool granted = false;
    try {
      final statuses = await [Permission.phone, Permission.contacts, Permission.sms].request();
      granted = statuses.values.every((s) => s.isGranted);
    } catch (_) {
      // permission_handler has no implementation for these permissions
      // outside Android (e.g. when previewing on web) — nothing to do.
    }
    bool batteryOk = false;
    try {
      batteryOk = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _permissionsGranted = granted;
        _batteryOptimizationIgnored = batteryOk;
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      await [Permission.phone, Permission.contacts, Permission.sms].request();
    } catch (_) {}
    await _refreshPermissionStatus();
    if (!_permissionsGranted && mounted) {
      _showSnack(tr(
        'Some permissions were denied. Call detection needs Phone, Contacts and SMS permissions to work.',
        'कुछ अनुमतियां अस्वीकार कर दी गईं। कॉल डिटेक्शन के लिए फ़ोन, संपर्क और SMS अनुमतियां आवश्यक हैं।',
        'काही परवानग्या नाकारल्या गेल्या. कॉल डिटेक्शन काम करण्यासाठी फोन, कॉन्टॅक्ट्स आणि SMS परवानग्या आवश्यक आहेत.',
      ));
    }
  }

  Future<void> _openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (_) {
      _showSnack(tr('Could not open battery settings on this device', 'इस डिवाइस पर बैटरी सेटिंग्स नहीं खोली जा सकीं', 'या डिव्हाइसवर बॅटरी सेटिंग्ज उघडता आल्या नाहीत'));
    }
  }

  Future<void> _save() async {
    if (_enabled && !_permissionsGranted) {
      _showSnack(tr('Please grant Phone, Contacts and SMS permissions first', 'कृपया पहले फ़ोन, संपर्क और SMS अनुमतियां दें', 'कृपया आधी फोन, कॉन्टॅक्ट्स आणि SMS परवानगी द्या'));
      return;
    }
    try {
      await _channel.invokeMethod('updateSettings', {
        'enabled': _enabled,
        'gurujiPhone': GurujiAuthService.loggedInPhone ?? '',
        'deviceKey': _callLogDeviceKey,
        'smsMissed': _smsMissed,
        'smsReceived': _smsReceived,
        'smsRejected': _smsRejected,
        'waMissed': _waMissed,
        'waReceived': _waReceived,
        'waRejected': _waRejected,
        'sendDelaySeconds': _sendDelaySeconds,
      });
      if (mounted) _showSnack(tr('Call integration settings saved', 'कॉल इंटीग्रेशन सेटिंग्स सेव हो गईं', 'कॉल इंटिग्रेशन सेटिंग्ज जतन झाल्या'));
    } catch (_) {
      if (mounted) _showSnack(tr('Could not save settings on this device', 'इस डिवाइस पर सेटिंग्स सेव नहीं हो सकीं', 'या डिव्हाइसवर सेटिंग्ज जतन करता आल्या नाहीत'));
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AdminColors.primary));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr(
              'Send an automatic SMS or WhatsApp message when a call to your number ends, based on how it ended.',
              'आपके नंबर पर आने वाली कॉल खत्म होने पर, कॉल कैसे खत्म हुई उसके अनुसार अपने आप SMS या WhatsApp संदेश भेजें।',
              'तुमच्या नंबरवरील कॉल संपल्यावर, कॉल कसा संपला त्यानुसार आपोआप SMS किंवा WhatsApp मेसेज पाठवा.',
            ),
            style: TextStyle(fontSize: 14, color: AdminColors.grey600),
          ),
          const SizedBox(height: 20),
          _card(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tr('Enable call detection', 'कॉल डिटेक्शन चालू करें', 'कॉल डिटेक्शन सुरू करा'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              subtitle: Text(tr('Master switch for this feature', 'इस सुविधा के लिए मुख्य स्विच', 'या सुविधेसाठी मुख्य स्विच')),
              activeThumbColor: AdminColors.primary,
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Send delay', 'भेजने में देरी', 'पाठवण्यास विलंब'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(tr('When to send the SMS/WhatsApp after the call ends', 'कॉल खत्म होने के बाद SMS/WhatsApp कब भेजें', 'कॉल संपल्यानंतर SMS/WhatsApp कधी पाठवायचा'),
                    style: TextStyle(fontSize: 12, color: AdminColors.grey600)),
                const SizedBox(height: 12),
                _delayPicker(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_permissionsGranted || !_batteryOptimizationIgnored) _setupChecklist(),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Auto SMS', 'ऑटो SMS', 'ऑटो SMS'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(tr('Sent directly from this device', 'सीधे इस डिवाइस से भेजा जाता है', 'थेट या डिव्हाइसवरून पाठवला जातो'),
                    style: TextStyle(fontSize: 12, color: AdminColors.grey600)),
                _checkbox(tr('Missed calls', 'मिस्ड कॉल', 'मिस्ड कॉल'), _smsMissed, (v) => setState(() => _smsMissed = v)),
                _checkbox(tr('Received calls', 'रिसीव्ड कॉल', 'रिसीव्ह्ड कॉल'), _smsReceived, (v) => setState(() => _smsReceived = v)),
                _checkbox(tr('Rejected calls', 'रिजेक्टेड कॉल', 'नाकारलेले कॉल'), _smsRejected, (v) => setState(() => _smsRejected = v)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('Auto WhatsApp', 'ऑटो WhatsApp', 'ऑटो WhatsApp'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(tr('Sent via the Trimbakeshwar server', 'Trimbakeshwar सर्वर के ज़रिए भेजा जाता है', 'Trimbakeshwar सर्व्हरमार्फत पाठवला जातो'),
                    style: TextStyle(fontSize: 12, color: AdminColors.grey600)),
                _checkbox(tr('Missed calls', 'मिस्ड कॉल', 'मिस्ड कॉल'), _waMissed, (v) => setState(() => _waMissed = v)),
                _checkbox(tr('Received calls', 'रिसीव्ड कॉल', 'रिसीव्ह्ड कॉल'), _waReceived, (v) => setState(() => _waReceived = v)),
                _checkbox(tr('Rejected calls', 'रिजेक्टेड कॉल', 'नाकारलेले कॉल'), _waRejected, (v) => setState(() => _waRejected = v)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: Text(tr('Save Changes', 'बदलाव सेव करें', 'बदल जतन करा'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _setupChecklist() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('Setup needed', 'सेटअप आवश्यक', 'सेटअप आवश्यक'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (!_permissionsGranted)
            _setupRow(
              tr('Grant Phone, Contacts & SMS permissions', 'फ़ोन, संपर्क और SMS अनुमतियां दें', 'फोन, कॉन्टॅक्ट्स आणि SMS परवानगी द्या'),
              tr('Required to detect and respond to calls', 'कॉल का पता लगाने और जवाब देने के लिए आवश्यक', 'कॉल ओळखण्यासाठी आणि प्रतिसाद देण्यासाठी आवश्यक'),
              _requestPermissions,
            ),
          if (!_batteryOptimizationIgnored)
            _setupRow(
              tr('Disable battery optimization for this app', 'इस ऐप के लिए बैटरी ऑप्टिमाइज़ेशन बंद करें', 'या अ‍ॅपसाठी बॅटरी ऑप्टिमायझेशन बंद करा'),
              tr(
                'Prevents the device from stopping call detection in the background',
                'यह डिवाइस को बैकग्राउंड में कॉल डिटेक्शन रोकने से बचाता है',
                'यामुळे डिव्हाइस बॅकग्राउंडमध्ये कॉल डिटेक्शन थांबवत नाही',
              ),
              _openBatteryOptimizationSettings,
            ),
        ],
      ),
    );
  }

  Widget _setupRow(String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF6C00), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: AdminColors.grey600)),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: Text(tr('Fix', 'ठीक करें', 'ठीक करा'))),
        ],
      ),
    );
  }

  Widget _delayPicker() {
    final minutes = (_sendDelaySeconds ~/ 60).clamp(0, 60);

    void setMinutes(int m) => setState(() => _sendDelaySeconds = m.clamp(0, 60) * 60);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded),
              color: AdminColors.primary,
              onPressed: minutes > 0 ? () => setMinutes(minutes - 1) : null,
            ),
            Text(
              minutes == 0
                  ? tr('Immediately', 'तुरंत', 'लगेच')
                  : tr('$minutes minute${minutes == 1 ? '' : 's'}', '$minutes मिनट', '$minutes मिनिटे'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: AdminColors.primary,
              onPressed: minutes < 60 ? () => setMinutes(minutes + 1) : null,
            ),
          ],
        ),
        Slider(
          value: minutes.toDouble(),
          min: 0,
          max: 60,
          divisions: 60,
          activeColor: AdminColors.primary,
          label: minutes == 0 ? tr('Immediately', 'तुरंत', 'लगेच') : tr('$minutes min', '$minutes मिनट', '$minutes मिनिटे'),
          onChanged: (v) => setMinutes(v.round()),
        ),
      ],
    );
  }

  Widget _checkbox(String label, bool value, ValueChanged<bool> onChanged) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      activeColor: AdminColors.primary,
      onChanged: (v) => onChanged(v ?? false),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}
