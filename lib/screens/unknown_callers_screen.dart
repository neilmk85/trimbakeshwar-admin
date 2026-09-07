import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/guruji_auth_service.dart';
import '../l10n/tr.dart';

/// Shared secret for the admin-app-secret gated call-logs endpoints. This app
/// is already gated to a single authorized phone number (see
/// home_screen.dart), so embedding the key here mirrors the same trust
/// boundary used for the call-detection device key.
const String _adminAppSecret = '3f6a79339cd7df9f126aca22dcb34aa073997169fc9bda47';
const String _apiBase = 'https://app.trimbakeshwarpoojavidhi.in/api';

class UnknownCallersScreen extends StatefulWidget {
  const UnknownCallersScreen({super.key});

  @override
  State<UnknownCallersScreen> createState() => _UnknownCallersScreenState();
}

class _UnknownCallersScreenState extends State<UnknownCallersScreen> {
  bool _loading = true;
  String? _error;
  List<UnknownCaller> _callers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final phone = GurujiAuthService.loggedInPhone ?? '';
    try {
      final res = await http
          .get(Uri.parse('$_apiBase/call-logs/unknown-callers?gurujiPhone=$phone'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['data'] as List<dynamic>? ?? [])
            .map((e) => UnknownCaller.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) setState(() => _callers = list);
      } else if (mounted) {
        setState(() => _error = tr('Failed to load unknown callers', 'अज्ञात कॉलर लोड करने में विफल', 'अज्ञात कॉलर लोड करण्यात अयशस्वी'));
      }
    } catch (_) {
      if (mounted) setState(() => _error = tr('Could not reach server', 'सर्वर तक नहीं पहुंच सके', 'सर्व्हरपर्यंत पोहोचता आले नाही'));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      _showSnack(tr('Could not open dialer', 'डायलर नहीं खुल सका', 'डायलर उघडता आला नाही'));
    }
  }

  Future<void> _saveAsCustomer(UnknownCaller caller) async {
    final controller = TextEditingController(text: caller.callerName);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('Save as Customer', 'ग्राहक के रूप में सेव करें', 'ग्राहक म्हणून जतन करा')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(caller.callerPhone, style: TextStyle(color: AdminColors.grey600)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(labelText: tr('Name', 'नाम', 'नाव'), border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(tr('Cancel', 'रद्द करें', 'रद्द करा'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(tr('Save', 'सेव करें', 'जतन करा')),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    try {
      final res = await http
          .post(
            Uri.parse('$_apiBase/call-logs/unknown-callers/convert'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'secret': _adminAppSecret,
              'callerPhone': caller.callerPhone,
              'fullName': name,
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (res.statusCode == 201) {
        setState(() => _callers.removeWhere((c) => c.callerPhone == caller.callerPhone));
        _showSnack(tr('$name saved as a customer', '$name को ग्राहक के रूप में सेव किया गया', '$name ला ग्राहक म्हणून जतन केले'));
      } else {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        _showSnack(body['message'] as String? ?? tr('Could not save customer', 'ग्राहक सेव नहीं हो सका', 'ग्राहक जतन करता आला नाही'));
      }
    } catch (_) {
      if (mounted) _showSnack(tr('Could not reach server', 'सर्वर तक नहीं पहुंच सके', 'सर्व्हरपर्यंत पोहोचता आले नाही'));
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
    if (_error != null) {
      return _emptyState(Icons.wifi_off_rounded, _error!);
    }
    if (_callers.isEmpty) {
      return _emptyState(
        Icons.phone_disabled_rounded,
        tr(
          'No unknown callers yet.\nCalls from numbers not in your customer list will show up here.',
          'अभी तक कोई अज्ञात कॉलर नहीं है।\nजो नंबर आपकी ग्राहक सूची में नहीं हैं, उनकी कॉल यहां दिखेंगी।',
          'अजून कोणताही अज्ञात कॉलर नाही.\nतुमच्या ग्राहक यादीत नसलेल्या नंबरवरील कॉल इथे दिसतील.',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AdminColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _callers.length,
        itemBuilder: (context, index) => _CallerCard(
          caller: _callers[index],
          onCall: () => _call(_callers[index].callerPhone),
          onSave: () => _saveAsCustomer(_callers[index]),
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AdminColors.grey400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AdminColors.grey500, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallerCard extends StatelessWidget {
  final UnknownCaller caller;
  final VoidCallback onCall;
  final VoidCallback onSave;

  const _CallerCard({required this.caller, required this.onCall, required this.onSave});

  (IconData, Color) get _callTypeStyle {
    switch (caller.lastCallType) {
      case 'missed':
        return (Icons.call_missed_rounded, const Color(0xFFD32F2F));
      case 'rejected':
        return (Icons.call_end_rounded, const Color(0xFFEF6C00));
      case 'received':
        return (Icons.call_received_rounded, const Color(0xFF2E7D32));
      default:
        return (Icons.call_rounded, AdminColors.grey600);
    }
  }

  String _relativeTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return tr('just now', 'अभी अभी', 'आत्ताच');
    if (diff.inMinutes < 60) return tr('${diff.inMinutes}m ago', '${diff.inMinutes} मिनट पहले', '${diff.inMinutes} मिनिटांपूर्वी');
    if (diff.inHours < 24) return tr('${diff.inHours}h ago', '${diff.inHours} घंटे पहले', '${diff.inHours} तासांपूर्वी');
    if (diff.inDays < 7) return tr('${diff.inDays}d ago', '${diff.inDays} दिन पहले', '${diff.inDays} दिवसांपूर्वी');
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _callTypeStyle;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      caller.callerName.isEmpty ? tr('Unknown caller', 'अज्ञात कॉलर', 'अज्ञात कॉलर') : caller.callerName,
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(caller.callerPhone, style: TextStyle(fontSize: 13.5, color: AdminColors.grey600)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call_rounded),
                color: const Color(0xFF2E7D32),
                onPressed: onCall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _badge(tr(
                '${caller.callCount} call${caller.callCount == 1 ? '' : 's'}',
                '${caller.callCount} कॉल',
                '${caller.callCount} कॉल',
              )),
              const SizedBox(width: 8),
              _badge(_relativeTime(caller.lastCallAt)),
              const Spacer(),
              TextButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: Text(tr('Save as Customer', 'ग्राहक के रूप में सेव करें', 'ग्राहक म्हणून जतन करा')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AdminColors.grey100, borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 11.5, color: AdminColors.grey600, fontWeight: FontWeight.w500)),
    );
  }
}
