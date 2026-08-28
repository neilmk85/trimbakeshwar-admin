import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';

class GurujiPoojaRatesScreen extends StatefulWidget {
  final GurujiDirectoryEntry guruji;
  const GurujiPoojaRatesScreen({super.key, required this.guruji});

  @override
  State<GurujiPoojaRatesScreen> createState() => _GurujiPoojaRatesScreenState();
}

class _GurujiPoojaRatesScreenState extends State<GurujiPoojaRatesScreen> {
  bool _loading = true;
  String? _error;
  List<GurujiPoojaRate> _rates = [];

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
    final result = await AdminDataService.getGurujiPoojaRates(widget.guruji.id);
    if (!mounted) return;
    setState(() {
      _rates = result.data;
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

  Future<void> _saveRate(GurujiPoojaRate rate, int newRate) async {
    final err = await AdminDataService.setGurujiPoojaRate(widget.guruji.id, rate.poojaId, newRate);
    if (!mounted) return;
    if (err == null) {
      _showSnack('Rate updated for ${rate.poojaName}.');
      await _load();
    } else {
      _showSnack(err, isError: true);
    }
  }

  Future<void> _resetToDefault(GurujiPoojaRate rate) async {
    final err = await AdminDataService.clearGurujiPoojaRate(widget.guruji.id, rate.poojaId);
    if (!mounted) return;
    if (err == null) {
      _showSnack('Reset to default rate.');
      await _load();
    } else {
      _showSnack(err, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AdminColors.appBarGradient)),
        title: Text(widget.guruji.name),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && _rates.isEmpty
                ? _buildError(_error!)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AdminColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18, color: AdminColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'These are internal payout rates for ${widget.guruji.name} — they don\'t affect customer prices.',
                                style: TextStyle(fontSize: 12.5, color: AdminColors.grey700, height: 1.4),
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
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

class _RateRow extends StatefulWidget {
  final GurujiPoojaRate rate;
  final ValueChanged<int> onSave;
  final VoidCallback onResetToDefault;

  const _RateRow({required this.rate, required this.onSave, required this.onResetToDefault});

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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.rate.poojaName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                if (widget.rate.isOverridden)
                  GestureDetector(
                    onTap: widget.onResetToDefault,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF6C00).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Custom',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFEF6C00))),
                        ),
                        const SizedBox(width: 6),
                        Text('Reset to default', style: TextStyle(fontSize: 10.5, color: AdminColors.grey500)),
                      ],
                    ),
                  )
                else
                  Text('Default rate', style: TextStyle(fontSize: 10.5, color: AdminColors.grey500)),
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
