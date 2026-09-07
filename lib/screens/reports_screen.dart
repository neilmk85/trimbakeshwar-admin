import 'package:flutter/material.dart';
import '../models/admin_models.dart';
import '../utils/csv_download_stub.dart'
    if (dart.library.html) '../utils/csv_download_web.dart';
import '../services/admin_data_service.dart';
import '../l10n/tr.dart';

// ── Report tab enum ───────────────────────────────────────────────────────────

enum _ReportTab { poojawise, users, revenue, guruji }

const _tabMeta = {
  _ReportTab.poojawise: (
    icon: Icons.auto_awesome_rounded,
    gradient: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
  ),
  _ReportTab.users: (
    icon: Icons.people_rounded,
    gradient: [Color(0xFF00695C), Color(0xFF00897B)],
  ),
  _ReportTab.revenue: (
    icon: Icons.currency_rupee_rounded,
    gradient: [Color(0xFFE65100), Color(0xFFFF6D00)],
  ),
  _ReportTab.guruji: (
    icon: Icons.groups_rounded,
    gradient: [Color(0xFF4527A0), Color(0xFF7B1FA2)],
  ),
};

// Tab labels are resolved via tr() at display time (not stored in the const
// map above) so they react to the current language.
String _tabLabel(_ReportTab t) {
  switch (t) {
    case _ReportTab.poojawise:
      return tr('Pooja-wise', 'पूजा अनुसार', 'पूजानुसार');
    case _ReportTab.users:
      return tr('Users', 'ग्राहक', 'ग्राहक');
    case _ReportTab.revenue:
      return tr('Revenue', 'आय', 'उत्पन्न');
    case _ReportTab.guruji:
      return tr('Guruji Payouts', 'गुरुजी भुगतान', 'गुरुजी मानधन');
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  _ReportTab _tab = _ReportTab.poojawise;
  DateTime? _from;
  DateTime? _to;
  bool _includeCancelled = false;

  // ── Guruji payout report state ──────────────────────────────────────────────
  List<GurujiDirectoryEntry> _gurujis = [];
  int? _selectedGurujiId;
  int? _selectedPoojaId;
  List<GurujiPoojaEntry> _gurujiEntries = [];
  bool _gurujiEntriesLoading = true;
  String? _gurujiEntriesError;

  @override
  void initState() {
    super.initState();
    _loadGurujis();
    _loadGurujiEntries();
  }

  Future<void> _loadGurujis() async {
    final result = await AdminDataService.getGurujiDirectory();
    if (!mounted) return;
    setState(() => _gurujis = result.data);
  }

  Future<void> _loadGurujiEntries() async {
    setState(() {
      _gurujiEntriesLoading = true;
      _gurujiEntriesError = null;
    });
    final result = await AdminDataService.getAllGurujiPoojaEntries(
      gurujiId: _selectedGurujiId,
      poojaId: _selectedPoojaId,
      dateFrom: _from,
      dateTo: _to,
    );
    if (!mounted) return;
    setState(() {
      _gurujiEntries = result.data;
      _gurujiEntriesError = result.error;
      _gurujiEntriesLoading = false;
    });
  }

  // ── Filtered data ───────────────────────────────────────────────────────────

  List<AdminOrder> _filtered(List<AdminOrder> all) {
    return all.where((o) {
      if (!_includeCancelled && o.cancelled) return false;
      if (_from != null &&
          o.poojaDate.isBefore(DateTime(_from!.year, _from!.month, _from!.day))) {
        return false;
      }
      if (_to != null &&
          o.poojaDate.isAfter(
              DateTime(_to!.year, _to!.month, _to!.day, 23, 59, 59))) {
        return false;
      }
      return true;
    }).toList();
  }

  // ── Summary helpers ─────────────────────────────────────────────────────────

  int _totalRevenue(List<AdminOrder> orders) =>
      orders.where((o) => !o.cancelled).fold(0, (s, o) => s + o.totalAmount);

  int _activeBookings(List<AdminOrder> orders) =>
      orders.where((o) => !o.cancelled).length;

  // ── CSV download ────────────────────────────────────────────────────────────

  void _downloadCsv(String filename, List<List<String>> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      buffer.writeln(row.map((c) => '"${c.replaceAll('"', '""')}"').join(','));
    }
    downloadCsv(filename, buffer.toString());
  }

  void _downloadPoojaReport(List<AdminOrder> filtered) {
    final grouped = _groupByPooja(filtered);
    final rows = <List<String>>[
      ['Pooja Name', 'Total Bookings', 'Active', 'Cancelled', 'Revenue (₹)', 'Avg Value (₹)'],
      ...grouped.entries.map((e) {
        final active = e.value.where((o) => !o.cancelled).length;
        final rev = e.value.where((o) => !o.cancelled).fold(0, (s, o) => s + o.totalAmount);
        return [
          e.key,
          '${e.value.length}',
          '$active',
          '${e.value.length - active}',
          '$rev',
          active > 0 ? '${(rev / active).round()}' : '0',
        ];
      }),
    ];
    _downloadCsv('pooja_report.csv', rows);
  }

  void _downloadUsersReport(List<AdminUser> users, List<AdminOrder> filtered) {
    final rows = <List<String>>[
      ['Name', 'Phone', 'Email', 'City', 'Country', 'Bookings', 'Total Spent (₹)'],
      ...users.map((u) {
        final userOrders = filtered.where(
            (o) => o.userPhone == u.phone && !o.cancelled).toList();
        final spent = userOrders.fold(0, (s, o) => s + o.totalAmount);
        return [
          u.fullName, u.phone, u.email, u.city, u.country,
          '${userOrders.length}', '$spent',
        ];
      }),
    ];
    _downloadCsv('users_report.csv', rows);
  }

  void _downloadRevenueReport(List<AdminOrder> filtered) {
    final byMonth = <String, int>{};
    for (final o in filtered.where((o) => !o.cancelled)) {
      final key =
          '${o.poojaDate.year}-${o.poojaDate.month.toString().padLeft(2, '0')}';
      byMonth[key] = (byMonth[key] ?? 0) + o.totalAmount;
    }
    final sorted = byMonth.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final rows = <List<String>>[
      ['Month', 'Revenue (₹)', 'Bookings'],
      ...sorted.map((e) {
        final count = filtered
            .where((o) =>
                !o.cancelled &&
                '${o.poojaDate.year}-${o.poojaDate.month.toString().padLeft(2, '0')}' ==
                    e.key)
            .length;
        return [e.key, '${e.value}', '$count'];
      }),
    ];
    _downloadCsv('revenue_report.csv', rows);
  }

  // ── Group helpers ───────────────────────────────────────────────────────────

  Map<String, List<AdminOrder>> _groupByPooja(List<AdminOrder> orders) {
    final map = <String, List<AdminOrder>>{};
    for (final o in orders) {
      (map[o.poojaName] ??= []).add(o);
    }
    final sorted = Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.value.length.compareTo(a.value.length)));
    return sorted;
  }

  // ── Date filter picker ──────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_from ?? DateTime.now()) : (_to ?? DateTime.now()),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF6A1B9A)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
          if (_to != null && _to!.isBefore(_from!)) _to = null;
        } else {
          _to = picked;
          if (_from != null && _from!.isAfter(_to!)) _from = null;
        }
      });
      _loadGurujiEntries();
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_monthAbbr(d.month - 1)} ${d.year}';

  static const _kMonths = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  static const _kMonthsHi = [
    'जन', 'फ़र', 'मार्च', 'अप्रै', 'मई', 'जून',
    'जुल', 'अग', 'सित', 'अक्टू', 'नव', 'दिस',
  ];

  static const _kMonthsMr = [
    'जाने', 'फेब्रु', 'मार्च', 'एप्रि', 'मे', 'जून',
    'जुलै', 'ऑग', 'सप्टें', 'ऑक्टो', 'नोव्हें', 'डिसें',
  ];

  static String _monthAbbr(int i) => tr(_kMonths[i], _kMonthsHi[i], _kMonthsMr[i]);

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminData>(
      valueListenable: AdminDataService.dataNotifier,
      builder: (_, data, __) {
        final filtered = _filtered(data.orders);
        final meta = _tabMeta[_tab]!;

        return Container(
          color: const Color(0xFFF0F2F8),
          child: Column(
            children: [
              // ── Tab bar + summary cards ──────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: meta.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Tab selector
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Row(
                          children: _ReportTab.values.map((t) {
                            final m = _tabMeta[t]!;
                            final selected = _tab == t;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _tab = t),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 9, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: selected
                                        ? Border.all(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            width: 1.5)
                                        : null,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(m.icon,
                                          size: 18,
                                          color: Colors.white
                                              .withValues(alpha: selected ? 1 : 0.65)),
                                      const SizedBox(height: 4),
                                      Text(_tabLabel(t),
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: selected
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              color: Colors.white.withValues(
                                                  alpha: selected ? 1 : 0.65))),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Summary stat cards
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Row(
                          children: _tab == _ReportTab.guruji
                              ? [
                                  _statCard(tr('Total Poojas', 'कुल पूजाएं', 'एकूण पूजा'),
                                      '${_gurujiEntries.fold<int>(0, (s, e) => s + e.count)}',
                                      Icons.auto_awesome_rounded),
                                  const SizedBox(width: 10),
                                  _statCard(tr('Total Payable', 'कुल देय राशि', 'एकूण देय रक्कम'),
                                      '₹${_fmt(_gurujiEntries.fold<int>(0, (s, e) => s + e.totalAmount))}',
                                      Icons.currency_rupee_rounded),
                                  const SizedBox(width: 10),
                                  _statCard(tr('Gurujis', 'गुरुजी', 'गुरुजी'),
                                      '${_gurujiEntries.map((e) => e.gurujiId).toSet().length}',
                                      Icons.groups_rounded),
                                ]
                              : [
                                  _statCard(tr('Total Bookings', 'कुल बुकिंग', 'एकूण बुकिंग'),
                                      '${filtered.length}',
                                      Icons.receipt_long_rounded),
                                  const SizedBox(width: 10),
                                  _statCard(tr('Active', 'सक्रिय', 'सक्रिय'),
                                      '${_activeBookings(filtered)}',
                                      Icons.check_circle_outline_rounded),
                                  const SizedBox(width: 10),
                                  _statCard(tr('Revenue', 'आय', 'उत्पन्न'),
                                      '₹${_fmt(_totalRevenue(filtered))}',
                                      Icons.currency_rupee_rounded),
                                  const SizedBox(width: 10),
                                  _statCard(tr('Users', 'ग्राहक', 'ग्राहक'),
                                      '${data.users.length}',
                                      Icons.people_outline_rounded),
                                ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Filters bar ──────────────────────────────────────────────
              _tab == _ReportTab.guruji
                  ? _buildGurujiFiltersBar(data)
                  : _buildFiltersBar(filtered, data),

              // ── Report body ──────────────────────────────────────────────
              Expanded(
                child: _tab == _ReportTab.poojawise
                    ? _buildPoojaReport(filtered)
                    : _tab == _ReportTab.users
                        ? _buildUsersReport(data.users, filtered)
                        : _tab == _ReportTab.revenue
                            ? _buildRevenueReport(filtered)
                            : _buildGurujiPayoutReport(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 15, color: Colors.white70),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: Colors.white70)),
            ],
          ),
        ),
      );

  Widget _buildFiltersBar(List<AdminOrder> filtered, AdminData data) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // From date
          _dateChip(
            label: _from == null ? tr('From', 'से', 'पासून') : _fmtDate(_from!),
            set: _from != null,
            onTap: () => _pickDate(isFrom: true),
            onClear: _from == null ? null : () => setState(() => _from = null),
          ),
          const SizedBox(width: 8),
          // To date
          _dateChip(
            label: _to == null ? tr('To', 'तक', 'पर्यंत') : _fmtDate(_to!),
            set: _to != null,
            onTap: () => _pickDate(isFrom: false),
            onClear: _to == null ? null : () => setState(() => _to = null),
          ),
          const SizedBox(width: 8),
          // Cancelled toggle
          GestureDetector(
            onTap: () => setState(() => _includeCancelled = !_includeCancelled),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _includeCancelled
                    ? Colors.red.shade50
                    : const Color(0xFFF0F2F8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _includeCancelled
                        ? Colors.red.shade300
                        : Colors.grey.shade300),
              ),
              child: Text(
                tr('Incl. Cancelled', 'रद्द सहित', 'रद्द केलेल्यांसह'),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _includeCancelled
                        ? Colors.red.shade700
                        : Colors.grey.shade600),
              ),
            ),
          ),
          const Spacer(),
          // Download button
          ElevatedButton.icon(
            onPressed: () {
              if (_tab == _ReportTab.poojawise) {
                _downloadPoojaReport(filtered);
              } else if (_tab == _ReportTab.users) {
                _downloadUsersReport(data.users, filtered);
              } else {
                _downloadRevenueReport(filtered);
              }
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text(tr('CSV', 'CSV', 'CSV'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateChip({
    required String label,
    required bool set,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: set
                ? const Color(0xFF6A1B9A).withValues(alpha: 0.08)
                : const Color(0xFFF0F2F8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: set
                    ? const Color(0xFF6A1B9A).withValues(alpha: 0.4)
                    : Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 12,
                  color: set
                      ? const Color(0xFF6A1B9A)
                      : Colors.grey.shade500),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: set
                          ? const Color(0xFF6A1B9A)
                          : Colors.grey.shade600)),
              if (onClear != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close_rounded,
                      size: 13, color: const Color(0xFF6A1B9A)),
                ),
              ]
            ],
          ),
        ),
      );

  // ── Guruji payout report ─────────────────────────────────────────────────────

  Widget _buildGurujiFiltersBar(AdminData data) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _dateChip(
                label: _from == null ? tr('From', 'से', 'पासून') : _fmtDate(_from!),
                set: _from != null,
                onTap: () => _pickDate(isFrom: true),
                onClear: _from == null
                    ? null
                    : () {
                        setState(() => _from = null);
                        _loadGurujiEntries();
                      },
              ),
              const SizedBox(width: 8),
              _dateChip(
                label: _to == null ? tr('To', 'तक', 'पर्यंत') : _fmtDate(_to!),
                set: _to != null,
                onTap: () => _pickDate(isFrom: false),
                onClear: _to == null
                    ? null
                    : () {
                        setState(() => _to = null);
                        _loadGurujiEntries();
                      },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _gurujiEntries.isEmpty ? null : _downloadGurujiPayoutReport,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: Text(tr('CSV', 'CSV', 'CSV'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4527A0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _selectedGurujiId,
                  isExpanded: true,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: tr('Guruji', 'गुरुजी', 'गुरुजी'),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(tr('All Gurujis', 'सभी गुरुजी', 'सर्व गुरुजी'))),
                    ..._gurujis.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedGurujiId = v);
                    _loadGurujiEntries();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _selectedPoojaId,
                  isExpanded: true,
                  isDense: true,
                  decoration: InputDecoration(
                    labelText: tr('Pooja', 'पूजा', 'पूजा'),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: [
                    DropdownMenuItem(value: null, child: Text(tr('All Poojas', 'सभी पूजाएं', 'सर्व पूजा'))),
                    ...data.poojas.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedPoojaId = v);
                    _loadGurujiEntries();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGurujiPayoutReport() {
    if (_gurujiEntriesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_gurujiEntriesError != null && _gurujiEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(_gurujiEntriesError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadGurujiEntries, child: Text(tr('Retry', 'फिर कोशिश करें', 'पुन्हा प्रयत्न करा'))),
            ],
          ),
        ),
      );
    }
    if (_gurujiEntries.isEmpty) {
      return Center(
        child: Text(tr('No pooja assignments match these filters.', 'इन फ़िल्टर के लिए कोई पूजा नहीं मिली।', 'या फिल्टरसाठी कोणतीही पूजा सापडली नाही.'), style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    // Group entries by guruji, preserving the backend's guruji-name ordering.
    final grouped = <int, List<GurujiPoojaEntry>>{};
    final namesById = <int, String>{};
    for (final e in _gurujiEntries) {
      (grouped[e.gurujiId] ??= []).add(e);
      namesById[e.gurujiId] = e.gurujiName;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final gurujiId in grouped.keys) ...[
          _gurujiGroupCard(namesById[gurujiId] ?? tr('Unknown', 'अज्ञात', 'अज्ञात'), grouped[gurujiId]!),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _gurujiGroupCard(String gurujiName, List<GurujiPoojaEntry> entries) {
    final totalPoojas = entries.fold<int>(0, (s, e) => s + e.count);
    final totalAmount = entries.fold<int>(0, (s, e) => s + e.totalAmount);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF4527A0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(gurujiName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(
                    tr('$totalPoojas pooja${totalPoojas == 1 ? '' : 's'}',
                        '$totalPoojas पूजा',
                        '$totalPoojas पूजा'),
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(width: 10),
                Text('₹$totalAmount', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (final e in entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(e.poojaName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(_fmtDate(e.entryDate), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('${e.count} × ₹${e.rateUsed}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.right),
                        ),
                        SizedBox(
                          width: 64,
                          child: Text('₹${e.totalAmount}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
                              textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  void _downloadGurujiPayoutReport() {
    final rows = <List<String>>[
      ['Guruji', 'Pooja', 'Date', 'Count', 'Rate', 'Amount'],
      ..._gurujiEntries.map((e) => [
            e.gurujiName,
            e.poojaName,
            _fmtDate(e.entryDate),
            '${e.count}',
            '${e.rateUsed}',
            '${e.totalAmount}',
          ]),
    ];
    _downloadCsv('guruji_payout_report.csv', rows);
  }

  // ── Pooja-wise report ───────────────────────────────────────────────────────

  Widget _buildPoojaReport(List<AdminOrder> filtered) {
    final grouped = _groupByPooja(filtered);
    if (grouped.isEmpty) return _empty(tr('No booking data', 'कोई बुकिंग डेटा नहीं', 'बुकिंग डेटा नाही'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel(
            tr('POOJA-WISE BREAKDOWN', 'पूजा अनुसार विवरण', 'पूजानुसार विवरण'),
            tr('${grouped.length} poojas  ·  ${filtered.length} bookings',
                '${grouped.length} पूजाएं  ·  ${filtered.length} बुकिंग',
                '${grouped.length} पूजा  ·  ${filtered.length} बुकिंग')),
        const SizedBox(height: 10),
        ...grouped.entries.map((e) {
          final all = e.value;
          final active = all.where((o) => !o.cancelled).toList();
          final cancelled = all.where((o) => o.cancelled).toList();
          final rev = active.fold(0, (s, o) => s + o.totalAmount);
          final avg = active.isNotEmpty ? (rev / active.length).round() : 0;

          // progress of this pooja vs max revenue
          final maxRev = grouped.values
              .map((v) => v.where((o) => !o.cancelled).fold(0, (s, o) => s + o.totalAmount))
              .fold(0, (a, b) => a > b ? a : b);
          final progress = maxRev > 0 ? rev / maxRev : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('ॐ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w300)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(e.key,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('₹${_fmt(rev)}',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6A1B9A))),
                      ),
                    ],
                  ),
                ),
                // Revenue bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFEDE7F6),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF6A1B9A)),
                    ),
                  ),
                ),
                // Stats row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Row(
                    children: [
                      _miniStat(tr('Total', 'कुल', 'एकूण'), '${all.length}', Colors.grey.shade700),
                      _divider(),
                      _miniStat(tr('Active', 'सक्रिय', 'सक्रिय'), '${active.length}', Colors.green.shade700),
                      _divider(),
                      _miniStat(tr('Cancelled', 'रद्द', 'रद्द'), '${cancelled.length}', Colors.red.shade400),
                      _divider(),
                      _miniStat(tr('Avg', 'औसत', 'सरासरी'), '₹${_fmt(avg)}', const Color(0xFF1565C0)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ── Users report ────────────────────────────────────────────────────────────

  Widget _buildUsersReport(List<AdminUser> users, List<AdminOrder> filtered) {
    if (users.isEmpty) return _empty(tr('No registered users', 'कोई पंजीकृत ग्राहक नहीं', 'नोंदणीकृत ग्राहक नाहीत'));

    final sorted = users.toList()
      ..sort((a, b) {
        final aSpent = filtered
            .where((o) => o.userPhone == a.phone && !o.cancelled)
            .fold(0, (s, o) => s + o.totalAmount);
        final bSpent = filtered
            .where((o) => o.userPhone == b.phone && !o.cancelled)
            .fold(0, (s, o) => s + o.totalAmount);
        return bSpent.compareTo(aSpent);
      });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel(tr('REGISTERED USERS', 'पंजीकृत ग्राहक', 'नोंदणीकृत ग्राहक'),
            tr('${users.length} total', '${users.length} कुल', '${users.length} एकूण')),
        const SizedBox(height: 10),
        ...sorted.asMap().entries.map((entry) {
          final u = entry.value;
          final rank = entry.key;
          final userOrders =
              filtered.where((o) => o.userPhone == u.phone).toList();
          final activeOrders =
              userOrders.where((o) => !o.cancelled).toList();
          final spent =
              activeOrders.fold(0, (s, o) => s + o.totalAmount);

          final colors = [
            const Color(0xFFFFC107),
            const Color(0xFF9E9E9E),
            const Color(0xFF8D6E63),
          ];
          final rankColor = rank < 3 ? colors[rank] : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF00695C), Color(0xFF00897B)]),
                      shape: BoxShape.circle,
                      border: rankColor != null
                          ? Border.all(color: rankColor, width: 2.5)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        u.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                u.fullName.isNotEmpty ? u.fullName : u.phone,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A2E)),
                              ),
                            ),
                            if (rankColor != null)
                              Icon(Icons.emoji_events_rounded,
                                  size: 16, color: rankColor),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${u.phone}${u.city.isNotEmpty ? '  ·  ${u.city}' : ''}',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _miniStat(tr('Bookings', 'बुकिंग', 'बुकिंग'), '${userOrders.length}',
                                Colors.grey.shade700),
                            _divider(),
                            _miniStat(tr('Active', 'सक्रिय', 'सक्रिय'), '${activeOrders.length}',
                                Colors.green.shade700),
                            _divider(),
                            _miniStat(
                                tr('Spent', 'खर्च', 'खर्च'), '₹${_fmt(spent)}', const Color(0xFF1565C0)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Revenue report ──────────────────────────────────────────────────────────

  Widget _buildRevenueReport(List<AdminOrder> filtered) {
    final activeOrders = filtered.where((o) => !o.cancelled).toList();
    if (filtered.isEmpty) return _empty(tr('No booking data', 'कोई बुकिंग डेटा नहीं', 'बुकिंग डेटा नाही'));

    // Group by month
    final byMonth = <String, List<AdminOrder>>{};
    for (final o in activeOrders) {
      final key =
          '${_monthFull(o.poojaDate.month - 1)} ${o.poojaDate.year}';
      (byMonth[key] ??= []).add(o);
    }
    final sortedMonths = byMonth.entries.toList()
      ..sort((a, b) {
        final ad = a.value.first.poojaDate;
        final bd = b.value.first.poojaDate;
        return DateTime(ad.year, ad.month)
            .compareTo(DateTime(bd.year, bd.month));
      });

    final totalRev = activeOrders.fold(0, (s, o) => s + o.totalAmount);
    final maxMonthRev = sortedMonths.isEmpty
        ? 1
        : sortedMonths
            .map((e) => e.value.fold(0, (s, o) => s + o.totalAmount))
            .fold(0, (a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top summary cards
        Row(
          children: [
            _revSummaryCard(tr('Total Revenue', 'कुल आय', 'एकूण उत्पन्न'), '₹${_fmt(totalRev)}',
                Icons.account_balance_wallet_rounded,
                const [Color(0xFFE65100), Color(0xFFFF6D00)]),
            const SizedBox(width: 10),
            _revSummaryCard(tr('Avg per Booking', 'प्रति बुकिंग औसत', 'प्रति बुकिंग सरासरी'),
                activeOrders.isEmpty
                    ? '₹0'
                    : '₹${_fmt((totalRev / activeOrders.length).round())}',
                Icons.trending_up_rounded,
                const [Color(0xFF1565C0), Color(0xFF1E88E5)]),
          ],
        ),
        const SizedBox(height: 16),
        _sectionLabel(tr('MONTHLY BREAKDOWN', 'माह अनुसार विवरण', 'महिन्यानुसार विवरण'),
            tr('${sortedMonths.length} months', '${sortedMonths.length} महीने', '${sortedMonths.length} महिने')),
        const SizedBox(height: 10),
        ...sortedMonths.map((e) {
          final monthRev = e.value.fold(0, (s, o) => s + o.totalAmount);
          final progress = maxMonthRev > 0 ? monthRev / maxMonthRev : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(e.key,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E))),
                    ),
                    Text('₹${_fmt(monthRev)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFE65100))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFFBE9E7),
                    valueColor:
                        const AlwaysStoppedAnimation(Color(0xFFFF6D00)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _miniStat(tr('Bookings', 'बुकिंग', 'बुकिंग'), '${e.value.length}', Colors.grey.shade700),
                    _divider(),
                    _miniStat(
                        tr('Share', 'हिस्सा', 'वाटा'),
                        '${totalRev > 0 ? (monthRev * 100 ~/ totalRev) : 0}%',
                        const Color(0xFFE65100)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _revSummaryCard(String label, String value, IconData icon,
          List<Color> colors) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(height: 8),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
      );

  // ── Shared widgets ──────────────────────────────────────────────────────────

  Widget _sectionLabel(String title, String sub) => Row(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF9E9E9E))),
          const SizedBox(width: 8),
          Text(sub,
              style: const TextStyle(fontSize: 11, color: Color(0xFFBDBDBD))),
        ],
      );

  Widget _miniStat(String label, String value, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E))),
        ],
      );

  Widget _divider() => Container(
        width: 1,
        height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: const Color(0xFFEEEEEE),
      );

  Widget _empty(String msg) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(msg,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );

  static String _fmt(int v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  static const _kMonthsFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const _kMonthsFullHi = [
    'जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
    'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर',
  ];

  static const _kMonthsFullMr = [
    'जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून',
    'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर',
  ];

  static String _monthFull(int i) => tr(_kMonthsFull[i], _kMonthsFullHi[i], _kMonthsFullMr[i]);
}
