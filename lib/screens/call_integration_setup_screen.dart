import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_colors.dart';
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
      _showSnack('Some permissions were denied. Call detection needs Phone, Contacts and SMS permissions to work.');
    }
  }

  Future<void> _openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (_) {
      _showSnack('Could not open battery settings on this device');
    }
  }

  Future<void> _save() async {
    if (_enabled && !_permissionsGranted) {
      _showSnack('Please grant Phone, Contacts and SMS permissions first');
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
      });
      if (mounted) _showSnack('Call integration settings saved');
    } catch (_) {
      if (mounted) _showSnack('Could not save settings on this device');
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
            'Send an automatic SMS or WhatsApp message when a call to your number ends, based on how it ended.',
            style: TextStyle(fontSize: 14, color: AdminColors.grey600),
          ),
          const SizedBox(height: 20),
          _card(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable call detection',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              subtitle: const Text('Master switch for this feature'),
              activeThumbColor: AdminColors.primary,
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
          ),
          const SizedBox(height: 16),
          if (!_permissionsGranted || !_batteryOptimizationIgnored) _setupChecklist(),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Auto SMS',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Sent directly from this device',
                    style: TextStyle(fontSize: 12, color: AdminColors.grey600)),
                _checkbox('Missed calls', _smsMissed, (v) => setState(() => _smsMissed = v)),
                _checkbox('Received calls', _smsReceived, (v) => setState(() => _smsReceived = v)),
                _checkbox('Rejected calls', _smsRejected, (v) => setState(() => _smsRejected = v)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Auto WhatsApp',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Sent via the Trimbakeshwar server',
                    style: TextStyle(fontSize: 12, color: AdminColors.grey600)),
                _checkbox('Missed calls', _waMissed, (v) => setState(() => _waMissed = v)),
                _checkbox('Received calls', _waReceived, (v) => setState(() => _waReceived = v)),
                _checkbox('Rejected calls', _waRejected, (v) => setState(() => _waRejected = v)),
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
              child: const Text('Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
          const Text('Setup needed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          if (!_permissionsGranted)
            _setupRow(
              'Grant Phone, Contacts & SMS permissions',
              'Required to detect and respond to calls',
              _requestPermissions,
            ),
          if (!_batteryOptimizationIgnored)
            _setupRow(
              'Disable battery optimization for this app',
              'Prevents the device from stopping call detection in the background',
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
          TextButton(onPressed: onTap, child: const Text('Fix')),
        ],
      ),
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
