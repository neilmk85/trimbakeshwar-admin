import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum _DatePreset { upcoming, today, yesterday, thisWeek, thisMonth, all, custom }

enum _SortBy { poojaDate, bookingDate }

// ── Screen ────────────────────────────────────────────────────────────────────

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String? _selectedPoojaName;
  _DatePreset _datePreset = _DatePreset.upcoming;
  DateTimeRange? _customRange;
  _SortBy _sortBy = _SortBy.poojaDate;
  final _searchCtrl = TextEditingController();

  static const _panelBg = Color(0xFFF0F4FF); // soft indigo tint
  static const _chipActive = AdminColors.primary;
  static const _chipActiveFg = Colors.white;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Date helpers ────────────────────────────────────────────────────────────

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _matchesDatePreset(AdminOrder o) {
    final today = DateTime.now();
    final d = DateTime(o.poojaDate.year, o.poojaDate.month, o.poojaDate.day);
    final todayDate = DateTime(today.year, today.month, today.day);

    switch (_datePreset) {
      case _DatePreset.all:
        return true;
      case _DatePreset.upcoming:
        return !d.isBefore(todayDate);
      case _DatePreset.today:
        return d == todayDate;
      case _DatePreset.yesterday:
        return d == todayDate.subtract(const Duration(days: 1));
      case _DatePreset.thisWeek:
        final from = todayDate.subtract(Duration(days: today.weekday - 1));
        return !d.isBefore(from) && !d.isAfter(todayDate);
      case _DatePreset.thisMonth:
        final from = DateTime(today.year, today.month, 1);
        return !d.isBefore(from) && !d.isAfter(todayDate);
      case _DatePreset.custom:
        if (_customRange == null) return true;
        final start = DateTime(_customRange!.start.year,
            _customRange!.start.month, _customRange!.start.day);
        final end = DateTime(_customRange!.end.year, _customRange!.end.month,
            _customRange!.end.day);
        return !d.isBefore(start) && !d.isAfter(end);
    }
  }

  List<AdminOrder> _applyFilters(List<AdminOrder> orders) {
    var result = orders.where((o) {
      if (_selectedPoojaName != null && o.poojaName != _selectedPoojaName) {
        return false;
      }
      if (!_matchesDatePreset(o)) return false;
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isNotEmpty &&
          !o.userName.toLowerCase().contains(q) &&
          !o.userPhone.contains(q)) {
        return false;
      }
      return true;
    }).toList();

    if (_sortBy == _SortBy.poojaDate) {
      result.sort((a, b) => a.poojaDate.compareTo(b.poojaDate));
    } else {
      result.sort((a, b) => b.bookedOn.compareTo(a.bookedOn));
    }
    return result;
  }

  bool get _hasFilter =>
      _selectedPoojaName != null ||
      _datePreset != _DatePreset.upcoming ||
      _searchCtrl.text.isNotEmpty;

  void _clearFilters() => setState(() {
        _selectedPoojaName = null;
        _datePreset = _DatePreset.upcoming;
        _customRange = null;
        _searchCtrl.clear();
      });

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminData>(
      valueListenable: AdminDataService.dataNotifier,
      builder: (_, data, __) {
        return ValueListenableBuilder<String?>(
          valueListenable: AdminDataService.errorNotifier,
          builder: (_, error, __) {
            final filtered = _applyFilters(data.orders);
            final poojaNames =
                data.orders.map((o) => o.poojaName).toSet().toList()..sort();
            return Column(
              children: [
                _FilterPanel(
                  poojaNames: poojaNames,
                  selectedPoojaName: _selectedPoojaName,
                  onPoojaChanged: (v) =>
                      setState(() => _selectedPoojaName = v),
                  datePreset: _datePreset,
                  customRange: _customRange,
                  onPresetChanged: (p) async {
                    if (p == _DatePreset.custom) {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDateRange: _customRange,
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.light(
                                primary: AdminColors.primary),
                          ),
                          child: child!,
                        ),
                      );
                      if (range != null) {
                        setState(() {
                          _datePreset = _DatePreset.custom;
                          _customRange = range;
                        });
                      }
                    } else {
                      setState(() {
                        _datePreset = p;
                        _customRange = null;
                      });
                    }
                  },
                  sortBy: _sortBy,
                  onSortChanged: (s) => setState(() => _sortBy = s),
                  searchCtrl: _searchCtrl,
                  onSearchChanged: () => setState(() {}),
                  hasFilter: _hasFilter,
                  onClear: _clearFilters,
                  panelBg: _panelBg,
                  chipActive: _chipActive,
                  chipActiveFg: _chipActiveFg,
                  resultCount: filtered.length,
                ),
                Expanded(
                  child: error != null && data.orders.isEmpty
                      ? _buildEmpty(error)
                      : filtered.isEmpty
                          ? _buildEmpty(data.orders.isEmpty
                              ? 'No bookings yet.'
                              : 'No bookings match the filters.')
                          : _buildList(filtered),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildList(List<AdminOrder> orders) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: orders.length,
        itemBuilder: (_, i) => _BookingCard(order: orders[i]),
      );

  Widget _buildEmpty(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined,
                  size: 72, color: AdminColors.grey400),
              const SizedBox(height: 16),
              Text(msg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AdminColors.grey500, fontSize: 14, height: 1.5)),
            ],
          ),
        ),
      );
}

// ── Filter panel ──────────────────────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  final List<String> poojaNames;
  final String? selectedPoojaName;
  final ValueChanged<String?> onPoojaChanged;
  final _DatePreset datePreset;
  final DateTimeRange? customRange;
  final ValueChanged<_DatePreset> onPresetChanged;
  final _SortBy sortBy;
  final ValueChanged<_SortBy> onSortChanged;
  final TextEditingController searchCtrl;
  final VoidCallback onSearchChanged;
  final bool hasFilter;
  final VoidCallback onClear;
  final Color panelBg;
  final Color chipActive;
  final Color chipActiveFg;
  final int resultCount;

  const _FilterPanel({
    required this.poojaNames,
    required this.selectedPoojaName,
    required this.onPoojaChanged,
    required this.datePreset,
    required this.customRange,
    required this.onPresetChanged,
    required this.sortBy,
    required this.onSortChanged,
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.hasFilter,
    required this.onClear,
    required this.panelBg,
    required this.chipActive,
    required this.chipActiveFg,
    required this.resultCount,
  });

  static const _dateLabels = {
    _DatePreset.upcoming: 'Upcoming',
    _DatePreset.today: 'Today',
    _DatePreset.yesterday: 'Yesterday',
    _DatePreset.thisWeek: 'This Week',
    _DatePreset.thisMonth: 'This Month',
    _DatePreset.all: 'All Dates',
    _DatePreset.custom: 'Custom',
  };

  String _customLabel() {
    if (customRange == null) return 'Custom';
    final s = customRange!.start;
    final e = customRange!.end;
    const m = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (s.year == e.year && s.month == e.month && s.day == e.day) {
      return '${s.day} ${m[s.month]}';
    }
    return '${s.day} ${m[s.month]} – ${e.day} ${m[e.month]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(
            bottom: BorderSide(color: AdminColors.primary.withValues(alpha: 0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Search + sort ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(child: _searchBar(context)),
                const SizedBox(width: 8),
                _sortButton(context),
                if (poojaNames.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _poojaButton(context),
                ],
              ],
            ),
          ),
          // ── Row 2: Date preset chips ──────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              children: _DatePreset.values.map((p) {
                final active = datePreset == p;
                final label =
                    p == _DatePreset.custom && datePreset == _DatePreset.custom
                        ? _customLabel()
                        : _dateLabels[p]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _DateChip(
                    label: label,
                    active: active,
                    chipActive: chipActive,
                    chipActiveFg: chipActiveFg,
                    onTap: () => onPresetChanged(p),
                  ),
                );
              }).toList(),
            ),
          ),
          // ── Row 3: Result count + clear ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 12, 8),
            child: Row(
              children: [
                Text(
                  '$resultCount booking${resultCount == 1 ? '' : 's'}',
                  style: TextStyle(
                      fontSize: 11,
                      color: AdminColors.primary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600),
                ),
                if (hasFilter) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: onClear,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_alt_off_rounded,
                            size: 12,
                            color: AdminColors.primary.withValues(alpha: 0.7)),
                        const SizedBox(width: 3),
                        Text('Clear',
                            style: TextStyle(
                                fontSize: 11,
                                color: AdminColors.primary
                                    .withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: AdminColors.primary.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: searchCtrl,
        onChanged: (_) => onSearchChanged(),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Name or mobile...',
          hintStyle: TextStyle(fontSize: 13, color: AdminColors.grey400),
          prefixIcon: Icon(Icons.search_rounded,
              size: 16,
              color: searchCtrl.text.isNotEmpty
                  ? AdminColors.primary
                  : AdminColors.grey400),
          suffixIcon: searchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    searchCtrl.clear();
                    onSearchChanged();
                  },
                  child: Icon(Icons.close_rounded,
                      size: 14, color: AdminColors.grey400),
                )
              : null,
          filled: false,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
        ),
      ),
    );
  }

  Widget _sortButton(BuildContext context) {
    final active = sortBy != _SortBy.poojaDate;
    return _IconChipButton(
      icon: Icons.sort_rounded,
      label: sortBy == _SortBy.poojaDate ? 'Pooja Date' : 'Booking Date',
      active: active,
      chipActive: chipActive,
      onTap: () {
        final next = sortBy == _SortBy.poojaDate
            ? _SortBy.bookingDate
            : _SortBy.poojaDate;
        onSortChanged(next);
      },
    );
  }

  Widget _poojaButton(BuildContext context) {
    final active = selectedPoojaName != null;
    return _IconChipButton(
      icon: Icons.auto_awesome_rounded,
      label: selectedPoojaName ?? 'Pooja',
      active: active,
      chipActive: chipActive,
      onTap: () => _showPoojaSheet(context),
    );
  }

  void _showPoojaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PoojaPickerSheet(
        poojaNames: poojaNames,
        selected: selectedPoojaName,
        onSelected: (v) {
          onPoojaChanged(v);
          Navigator.pop(context);
        },
        chipActive: chipActive,
      ),
    );
  }
}

// ── Small reusable chip widgets ───────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color chipActive;
  final Color chipActiveFg;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.active,
    required this.chipActive,
    required this.chipActiveFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: active ? chipActive : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? chipActive
                : AdminColors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: chipActive.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active
                ? chipActiveFg
                : AdminColors.primary.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}

class _IconChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color chipActive;
  final VoidCallback onTap;

  const _IconChipButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.chipActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: active ? chipActive.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active
                  ? chipActive.withValues(alpha: 0.5)
                  : AdminColors.primary.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
                color: AdminColors.primary.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: active ? chipActive : AdminColors.primary.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: active
                      ? chipActive
                      : AdminColors.primary.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pooja picker bottom sheet ─────────────────────────────────────────────────

class _PoojaPickerSheet extends StatelessWidget {
  final List<String> poojaNames;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final Color chipActive;

  const _PoojaPickerSheet({
    required this.poojaNames,
    required this.selected,
    required this.onSelected,
    required this.chipActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Filter by Pooja',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('All Poojas', selected == null, () => onSelected(null)),
              ...poojaNames.map(
                  (n) => _chip(n, selected == n, () => onSelected(n))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? chipActive : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active
                  ? chipActive
                  : AdminColors.primary.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? Colors.white : AdminColors.grey800,
          ),
        ),
      ),
    );
  }
}

// ── Booking card ──────────────────────────────────────────────────────────────

class _BookingCard extends StatefulWidget {
  final AdminOrder order;
  const _BookingCard({required this.order});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _cancelling = false;

  AdminOrder get order => widget.order;

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
            'Cancel booking for "${order.poojaName}"?\nOrder: ${order.orderId}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Yes, Cancel')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    final err = await AdminDataService.cancelBooking(order.orderId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          Container(
            decoration: BoxDecoration(
              color: order.poojaColor.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: order.poojaColor, shape: BoxShape.circle),
                  child: const Center(
                    child: Text('ॐ',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w300)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.poojaName,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: order.poojaColor)),
                      if (order.userName.isNotEmpty)
                        Text(order.userName,
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    order.poojaColor.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
                order.cancelled ? _cancelledBadge() : _confirmedBadge(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Pooja details ──────────────────────────────────────────
                _row(Icons.calendar_today_rounded, 'Pooja Date',
                    _date(order.poojaDate)),
                const SizedBox(height: 8),
                _row(Icons.people_rounded, 'People',
                    order.numberOfPeople.toString()),
                const SizedBox(height: 8),
                _row(Icons.family_restroom_rounded, 'Gotra', order.gotra),
                const SizedBox(height: 8),
                _row(Icons.currency_rupee_rounded, 'Amount Paid',
                    '₹${_fmt(order.totalAmount)}',
                    valueColor: Colors.green.shade700, bold: true),

                // ── Booked by ──────────────────────────────────────────────
                if (order.userName.isNotEmpty || order.userPhone.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _sectionLabel('Booked By'),
                  const SizedBox(height: 8),
                  if (order.userName.isNotEmpty)
                    _row(Icons.person_rounded, 'Name', order.userName),
                  if (order.userPhone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _row(Icons.phone_rounded, 'Phone', order.userPhone),
                  ],
                ],

                // ── Booked For ─────────────────────────────────────────────
                if (order.bookedForName.isNotEmpty ||
                    order.bookedForPhone.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1),
                  ),
                  _sectionLabel('Pooja For'),
                  const SizedBox(height: 8),
                  if (order.bookedForName.isNotEmpty)
                    _row(Icons.person_outline_rounded, 'Name',
                        order.bookedForName),
                  if (order.bookedForPhone.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _row(Icons.phone_outlined, 'Phone', order.bookedForPhone),
                  ],
                  if (order.bookedForEmail.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _row(Icons.email_outlined, 'Email', order.bookedForEmail),
                  ],
                  if (order.bookedForCity.isNotEmpty ||
                      order.bookedForZipCode.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _row(
                      Icons.location_on_outlined,
                      'Location',
                      [
                        order.bookedForCity,
                        order.bookedForZipCode,
                        order.bookedForCountry,
                      ].where((s) => s.isNotEmpty).join(', '),
                    ),
                  ],
                ],

                // ── Footer ─────────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order ID: ${order.orderId}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AdminColors.grey500,
                                  fontFamily: 'monospace')),
                          const SizedBox(height: 2),
                          Text('Booked ${_date(order.bookedOn)}',
                              style: TextStyle(
                                  fontSize: 11, color: AdminColors.grey500)),
                        ],
                      ),
                    ),
                    if (!order.cancelled)
                      _cancelling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : TextButton.icon(
                              onPressed: _confirmCancel,
                              icon: const Icon(Icons.cancel_outlined, size: 14),
                              label: const Text('Cancel'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                textStyle: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cancelledBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: Colors.red.shade600, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('Cancelled',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700)),
        ]),
      );

  Widget _confirmedBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: Color(0xFF43A047), shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('Confirmed',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700)),
        ]),
      );

  Widget _sectionLabel(String label) => Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AdminColors.grey500,
            letterSpacing: 0.6),
      );

  Widget _row(IconData icon, String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AdminColors.grey500),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(label,
              style: TextStyle(fontSize: 13, color: AdminColors.grey600)),
        ),
        Expanded(
          child: Text(value.isEmpty ? '—' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
                color: valueColor ?? const Color(0xFF1A1A2E),
              )),
        ),
      ],
    );
  }

  String _fmt(int amount) {
    final s = amount.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
      buf.write(rest[i]);
    }
    return '${buf.toString()},$last3';
  }

  String _date(DateTime dt) {
    const m = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${m[dt.month]} ${dt.year}';
  }
}
