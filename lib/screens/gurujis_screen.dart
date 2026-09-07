import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';
import '../l10n/tr.dart';
import 'guruji_pooja_rates_screen.dart';

class GurujisScreen extends StatefulWidget {
  const GurujisScreen({super.key});

  @override
  State<GurujisScreen> createState() => _GurujisScreenState();
}

class _GurujisScreenState extends State<GurujisScreen> {
  bool _loading = true;
  String? _error;
  List<GurujiDirectoryEntry> _gurujis = [];

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
    final result = await AdminDataService.getGurujiDirectory();
    if (!mounted) return;
    setState(() {
      _gurujis = result.data;
      _error = result.error;
      _loading = false;
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showAddOrEditSheet({GurujiDirectoryEntry? existing}) async {
    final result = await showModalBottomSheet<_GurujiForm>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GurujiFormSheet(existing: existing),
    );
    if (result == null) return;

    final err = existing == null
        ? await AdminDataService.createGurujiDirectoryEntry(
            name: result.name, phone: result.phone, email: result.email)
        : await AdminDataService.updateGurujiDirectoryEntry(
            existing.id, name: result.name, phone: result.phone, email: result.email);

    if (!mounted) return;
    if (err == null) {
      _showSnack(existing == null
          ? tr('Guruji added.', 'गुरुजी जोड़े गए।')
          : tr('Guruji updated.', 'गुरुजी अपडेट किए गए।'));
      await _load();
    } else {
      _showSnack(err, isError: true);
    }
  }

  Future<void> _confirmDelete(GurujiDirectoryEntry g) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('Remove this Guruji?', 'इस गुरुजी को हटाएं?')),
        content: Text(tr(
            '${g.name} · ${g.phone}\n\nThis only removes them from your roster — it does not affect app login.',
            '${g.name} · ${g.phone}\n\nयह उन्हें केवल आपकी सूची से हटाता है — इससे ऐप लॉगिन पर कोई असर नहीं पड़ता।')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Cancel', 'रद्द करें'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Remove', 'हटाएं')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await AdminDataService.deleteGurujiDirectoryEntry(g.id);
    if (!mounted) return;
    if (err == null) {
      _showSnack(tr('Guruji removed.', 'गुरुजी हटाए गए।'));
      await _load();
    } else {
      _showSnack(err, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AdminColors.appBarGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AdminColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddOrEditSheet(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _gurujis.isEmpty
                ? _buildError(_error!)
                : _gurujis.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                        itemCount: _gurujis.length,
                        itemBuilder: (_, i) => _GurujiCard(
                          guruji: _gurujis[i],
                          onEdit: () => _showAddOrEditSheet(existing: _gurujis[i]),
                          onDelete: () => _confirmDelete(_gurujis[i]),
                        ),
                      ),
      ),
    );
  }

  Widget _buildError(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: AdminColors.grey400),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: AdminColors.grey600)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: Text(tr('Retry', 'फिर से कोशिश करें'))),
            ],
          ),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.groups_outlined, size: 56, color: AdminColors.grey400),
              const SizedBox(height: 12),
              Text(tr('No Gurujis added yet.', 'अभी तक कोई गुरुजी नहीं जोड़े गए हैं।'), style: TextStyle(color: AdminColors.grey600)),
              const SizedBox(height: 4),
              Text(tr('Tap + to add one.', 'जोड़ने के लिए + पर टैप करें।'), style: TextStyle(color: AdminColors.grey500, fontSize: 12)),
            ],
          ),
        ),
      );
}

class _GurujiCard extends StatelessWidget {
  final GurujiDirectoryEntry guruji;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GurujiCard({required this.guruji, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GurujiPoojaRatesScreen(guruji: guruji)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(gradient: AdminColors.appBarGradient, shape: BoxShape.circle),
                  child: Center(
                    child: Text(guruji.initials,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guruji.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(guruji.phone, style: TextStyle(fontSize: 13.5, color: AdminColors.grey600)),
                      if (guruji.email.isNotEmpty)
                        Text(guruji.email, style: TextStyle(fontSize: 12.5, color: AdminColors.grey500)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: AdminColors.grey500),
                  onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(tr('Edit', 'संपादित करें'))),
                    PopupMenuItem(value: 'delete', child: Text(tr('Remove', 'हटाएं'))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GurujiForm {
  final String name;
  final String phone;
  final String email;
  const _GurujiForm({required this.name, required this.phone, required this.email});
}

class _GurujiFormSheet extends StatefulWidget {
  final GurujiDirectoryEntry? existing;
  const _GurujiFormSheet({this.existing});

  @override
  State<_GurujiFormSheet> createState() => _GurujiFormSheetState();
}

class _GurujiFormSheetState extends State<_GurujiFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
    _emailCtrl = TextEditingController(text: widget.existing?.email ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Name and phone are required', 'नाम और फ़ोन नंबर आवश्यक हैं'))),
      );
      return;
    }
    Navigator.pop(context, _GurujiForm(name: name, phone: phone, email: _emailCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AdminColors.grey300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(isEdit ? tr('Edit Guruji', 'गुरुजी संपादित करें') : tr('Add Guruji', 'गुरुजी जोड़ें'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 18),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: tr('Name', 'नाम'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: tr('Phone Number', 'फ़ोन नंबर'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: tr('Email (optional)', 'ईमेल (वैकल्पिक)'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submit,
                child: Text(isEdit ? tr('Save Changes', 'बदलाव सेव करें') : tr('Add Guruji', 'गुरुजी जोड़ें'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
