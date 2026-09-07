import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../l10n/tr.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';

class GurujiPoojaRatesScreen extends StatefulWidget {
  final GurujiDirectoryEntry guruji;
  const GurujiPoojaRatesScreen({super.key, required this.guruji});

  @override
  State<GurujiPoojaRatesScreen> createState() => _GurujiPoojaRatesScreenState();
}

class _GurujiPoojaRatesScreenState extends State<GurujiPoojaRatesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _ratesLoading = true;
  String? _ratesError;
  List<GurujiPoojaRate> _rates = [];

  bool _entriesLoading = true;
  String? _entriesError;
  List<GurujiPoojaEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRates();
    _loadEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    setState(() {
      _ratesLoading = true;
      _ratesError = null;
    });
    final result = await AdminDataService.getGurujiPoojaRates(widget.guruji.id);
    if (!mounted) return;
    setState(() {
      _rates = result.data;
      _ratesError = result.error;
      _ratesLoading = false;
    });
  }

  Future<void> _loadEntries() async {
    setState(() {
      _entriesLoading = true;
      _entriesError = null;
    });
    final result = await AdminDataService.getGurujiPoojaEntries(
      widget.guruji.id,
    );
    if (!mounted) return;
    setState(() {
      _entries = result.data;
      _entriesError = result.error;
      _entriesLoading = false;
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

  Future<void> _saveRate(GurujiPoojaRate rate, int newRate) async {
    final err = await AdminDataService.setGurujiPoojaRate(
      widget.guruji.id,
      rate.poojaId,
      newRate,
    );
    if (!mounted) return;
    if (err == null) {
      _showSnack(
        tr(
          'Rate updated for ${rate.poojaName}.',
          '${rate.poojaName} के लिए दर अपडेट की गई।',
        ),
      );
      await _loadRates();
    } else {
      _showSnack(err, isError: true);
    }
  }

  Future<void> _resetToDefault(GurujiPoojaRate rate) async {
    final err = await AdminDataService.clearGurujiPoojaRate(
      widget.guruji.id,
      rate.poojaId,
    );
    if (!mounted) return;
    if (err == null) {
      _showSnack(
        tr('Reset to default rate.', 'डिफ़ॉल्ट दर पर रीसेट किया गया।'),
      );
      await _loadRates();
    } else {
      _showSnack(err, isError: true);
    }
  }

  Future<void> _openRecordSheet() async {
    if (_rates.isEmpty) {
      _showSnack(
        tr('No poojas available yet.', 'अभी तक कोई पूजा उपलब्ध नहीं है।'),
        isError: true,
      );
      return;
    }
    final result = await showModalBottomSheet<_EntryForm>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecordEntrySheet(guruji: widget.guruji, rates: _rates),
    );
    if (result == null) return;

    final res = await AdminDataService.createGurujiPoojaEntry(
      widget.guruji.id,
      poojaId: result.poojaId,
      entryDate: result.date,
      count: result.count,
    );
    if (!mounted) return;
    if (res.error == null && res.data != null) {
      _showSnack(
        tr(
          '${res.data!.poojaName} × ${res.data!.count} = ₹${res.data!.totalAmount} recorded.',
          '${res.data!.poojaName} × ${res.data!.count} = ₹${res.data!.totalAmount} दर्ज किया गया।',
        ),
      );
      await _loadEntries();
      _tabController.animateTo(1);
    } else {
      _showSnack(
        res.error ?? tr('Failed to record entry', 'एंट्री दर्ज करने में विफल'),
        isError: true,
      );
    }
  }

  Future<void> _deleteEntry(GurujiPoojaEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('Delete this entry?', 'यह एंट्री हटाएं?')),
        content: Text(
          '${entry.poojaName} × ${entry.count} = ₹${entry.totalAmount}\n${_formatDate(entry.entryDate)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel', 'रद्द करें')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Delete', 'हटाएं')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final err = await AdminDataService.deleteGurujiPoojaEntry(
      widget.guruji.id,
      entry.id,
    );
    if (!mounted) return;
    if (err == null) {
      _showSnack(tr('Entry deleted.', 'एंट्री हटाई गई।'));
      await _loadEntries();
    } else {
      _showSnack(err, isError: true);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AdminColors.appBarGradient),
        ),
        title: Text(widget.guruji.name),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: tr('Rates', 'दरें')),
            Tab(text: tr('Payout History', 'भुगतान इतिहास')),
          ],
        ),
      ),
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
          onPressed: _openRecordSheet,
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          tooltip: tr('Record Pooja Assignment', 'पूजा असाइनमेंट दर्ज करें'),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildRatesTab(), _buildHistoryTab()],
      ),
    );
  }

  Widget _buildRatesTab() {
    return RefreshIndicator(
      onRefresh: _loadRates,
      child: _ratesLoading
          ? const Center(child: CircularProgressIndicator())
          : _ratesError != null && _rates.isEmpty
          ? _buildError(_ratesError!, _loadRates)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AdminColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tr(
                            'These are internal payout rates for ${widget.guruji.name} — they don\'t affect customer prices.',
                            'ये ${widget.guruji.name} के लिए आंतरिक भुगतान दरें हैं — इनसे ग्राहकों की कीमतों पर कोई असर नहीं पड़ता।',
                          ),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AdminColors.grey700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (final rate in _rates)
                  _RateRow(
                    rate: rate,
                    onSave: (v) => _saveRate(rate, v),
                    onResetToDefault: () => _resetToDefault(rate),
                  ),
              ],
            ),
    );
  }

  Widget _buildHistoryTab() {
    final total = _entries.fold<int>(0, (sum, e) => sum + e.totalAmount);
    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: _entriesLoading
          ? const Center(child: CircularProgressIndicator())
          : _entriesError != null && _entries.isEmpty
          ? _buildError(_entriesError!, _loadEntries)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 18,
                  ),
                  decoration: BoxDecoration(
                    gradient: AdminColors.appBarGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('Total Payout', 'कुल भुगतान'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹$total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        tr(
                          'No entries yet. Tap + to record one.',
                          'अभी तक कोई एंट्री नहीं। एक दर्ज करने के लिए + दबाएं।',
                        ),
                        style: TextStyle(color: AdminColors.grey500),
                      ),
                    ),
                  )
                else
                  for (final entry in _entries)
                    _EntryRow(
                      entry: entry,
                      onDelete: () => _deleteEntry(entry),
                    ),
              ],
            ),
    );
  }

  Widget _buildError(String message, Future<void> Function() onRetry) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 56,
            color: AdminColors.grey400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AdminColors.grey600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(tr('Retry', 'फिर से कोशिश करें')),
          ),
        ],
      ),
    ),
  );
}

class _RateRow extends StatefulWidget {
  final GurujiPoojaRate rate;
  final ValueChanged<int> onSave;
  final VoidCallback onResetToDefault;

  const _RateRow({
    required this.rate,
    required this.onSave,
    required this.onResetToDefault,
  });

  @override
  State<_RateRow> createState() => _RateRowState();
}

class _RateRowState extends State<_RateRow> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.rate.rate}');
  }

  @override
  void didUpdateWidget(covariant _RateRow old) {
    super.didUpdateWidget(old);
    if (old.rate.rate != widget.rate.rate) {
      _ctrl.text = '${widget.rate.rate}';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final v = int.tryParse(_ctrl.text.trim()) ?? 0;
    if (v == widget.rate.rate) return;
    widget.onSave(v);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.rate.poojaName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                if (widget.rate.isOverridden)
                  GestureDetector(
                    onTap: widget.onResetToDefault,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFEF6C00,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tr('Custom', 'कस्टम'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF6C00),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tr('Reset to default', 'डिफ़ॉल्ट पर रीसेट करें'),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AdminColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    tr('Default rate', 'डिफ़ॉल्ट दर'),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AdminColors.grey500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 96,
            child: TextField(
              controller: _ctrl,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmitted: (_) => _submit(),
              onTapOutside: (_) => _submit(),
              decoration: InputDecoration(
                prefixText: '₹',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final GurujiPoojaEntry entry;
  final VoidCallback onDelete;

  const _EntryRow({required this.entry, required this.onDelete});

  String _formatDate(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.poojaName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatDate(entry.entryDate)} · ${entry.count} × ₹${entry.rateUsed}',
                  style: TextStyle(fontSize: 12, color: AdminColors.grey600),
                ),
              ],
            ),
          ),
          Text(
            '₹${entry.totalAmount}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red.shade400,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EntryForm {
  final int poojaId;
  final DateTime date;
  final int count;
  const _EntryForm({
    required this.poojaId,
    required this.date,
    required this.count,
  });
}

class _RecordEntrySheet extends StatefulWidget {
  final GurujiDirectoryEntry guruji;
  final List<GurujiPoojaRate> rates;

  const _RecordEntrySheet({required this.guruji, required this.rates});

  @override
  State<_RecordEntrySheet> createState() => _RecordEntrySheetState();
}

class _RecordEntrySheetState extends State<_RecordEntrySheet> {
  late int _selectedPoojaId;
  DateTime _date = DateTime.now();
  late final TextEditingController _countCtrl;

  @override
  void initState() {
    super.initState();
    _selectedPoojaId = widget.rates.first.poojaId;
    _countCtrl = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _countCtrl.dispose();
    super.dispose();
  }

  GurujiPoojaRate get _selectedRate =>
      widget.rates.firstWhere((r) => r.poojaId == _selectedPoojaId);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  void _submit() {
    final count = int.tryParse(_countCtrl.text.trim()) ?? 0;
    if (count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr('Enter a valid number of poojas', 'पूजाओं की सही संख्या डालें'),
          ),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      _EntryForm(poojaId: _selectedPoojaId, date: _date, count: count),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = int.tryParse(_countCtrl.text.trim()) ?? 0;
    final total = _selectedRate.rate * count;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AdminColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr('Record Pooja Assignment', 'पूजा असाइनमेंट दर्ज करें'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('For ${widget.guruji.name}', '${widget.guruji.name} के लिए'),
              style: TextStyle(fontSize: 12.5, color: AdminColors.grey600),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<int>(
              initialValue: _selectedPoojaId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: tr('Pooja', 'पूजा'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: widget.rates
                  .map(
                    (r) => DropdownMenuItem(
                      value: r.poojaId,
                      child: Text(r.poojaName, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedPoojaId = v ?? _selectedPoojaId),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: tr('Date', 'तारीख'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_formatDate(_date)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _countCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: tr('Number of Poojas', 'पूजाओं की संख्या'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AdminColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tr(
                      'Rate: ₹${_selectedRate.rate} × $count',
                      'दर: ₹${_selectedRate.rate} × $count',
                    ),
                    style: TextStyle(fontSize: 13, color: AdminColors.grey700),
                  ),
                  Text(
                    '₹$total',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submit,
                child: Text(
                  tr('Record Assignment', 'असाइनमेंट दर्ज करें'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
