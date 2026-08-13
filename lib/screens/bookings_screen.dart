import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';
import 'admin_booking_detail_screen.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum _DatePreset {
  upcoming,
  today,
  tomorrow,
  yesterday,
  thisWeek,
  thisMonth,
  all,
  custom,
}

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

  bool _matchesDatePreset(AdminOrder o) {
    final today = DateTime.now();
    final ref = o.eventDate;
    final d = DateTime(ref.year, ref.month, ref.day);
    final todayDate = DateTime(today.year, today.month, today.day);

    switch (_datePreset) {
      case _DatePreset.all:
        return true;
      case _DatePreset.upcoming:
        return !d.isBefore(todayDate);
      case _DatePreset.today:
        return d == todayDate;
      case _DatePreset.tomorrow:
        return d == todayDate.add(const Duration(days: 1));
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
        final start = DateTime(
          _customRange!.start.year,
          _customRange!.start.month,
          _customRange!.start.day,
        );
        final end = DateTime(
          _customRange!.end.year,
          _customRange!.end.month,
          _customRange!.end.day,
        );
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
      result.sort((a, b) => a.eventDate.compareTo(b.eventDate));
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
                  onPoojaChanged: (v) => setState(() => _selectedPoojaName = v),
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
                              primary: AdminColors.primary,
                            ),
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
                      ? _buildEmpty(
                          data.orders.isEmpty
                              ? 'No bookings yet.'
                              : 'No bookings match the filters.',
                        )
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
          Icon(
            Icons.receipt_long_outlined,
            size: 72,
            color: AdminColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AdminColors.grey500,
              fontSize: 14,
              height: 1.5,
            ),
          ),
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
    _DatePreset.tomorrow: 'Tomorrow',
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
          bottom: BorderSide(color: AdminColors.primary.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Search + sort + calendar ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                Expanded(child: _searchBar(context)),
                const SizedBox(width: 8),
                _calendarButton(context),
                const SizedBox(width: 6),
                _sortButton(context),
                if (poojaNames.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  _poojaButton(context),
                ],
              ],
            ),
          ),
          // ── Row 2: Result count + clear ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 2, 12, 8),
            child: Row(
              children: [
                Text(
                  '$resultCount booking${resultCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AdminColors.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasFilter) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: onClear,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_alt_off_rounded,
                          size: 12,
                          color: AdminColors.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Clear',
                          style: TextStyle(
                            fontSize: 11,
                            color: AdminColors.primary.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchCtrl,
        onChanged: (_) => onSearchChanged(),
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Name or mobile...',
          hintStyle: TextStyle(fontSize: 13, color: AdminColors.grey400),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 16,
            color: searchCtrl.text.isNotEmpty
                ? AdminColors.primary
                : AdminColors.grey400,
          ),
          suffixIcon: searchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    searchCtrl.clear();
                    onSearchChanged();
                  },
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AdminColors.grey400,
                  ),
                )
              : null,
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 4,
          ),
        ),
      ),
    );
  }

  Widget _calendarButton(BuildContext context) {
    final active = datePreset != _DatePreset.upcoming;
    return PopupMenuButton<_DatePreset>(
      onSelected: onPresetChanged,
      itemBuilder: (_) => _DatePreset.values.map((preset) {
        final label = preset == _DatePreset.custom && datePreset == _DatePreset.custom
            ? _customLabel()
            : _dateLabels[preset]!;
        return PopupMenuItem(
          value: preset,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (datePreset == preset)
                const Icon(Icons.check, size: 18, color: AdminColors.primary)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 10),
              Text(label),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: active ? chipActive.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? chipActive.withValues(alpha: 0.5)
                : AdminColors.primary.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: AdminColors.primary.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.calendar_today_rounded,
          size: 16,
          color: active
              ? chipActive
              : AdminColors.primary.withValues(alpha: 0.7),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                    offset: const Offset(0, 2),
                  ),
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
                : AdminColors.primary.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: AdminColors.primary.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active
                  ? chipActive
                  : AdminColors.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active
                    ? chipActive
                    : AdminColors.primary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color chipActive;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
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
        width: 36,
        decoration: BoxDecoration(
          color: active ? chipActive.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? chipActive.withValues(alpha: 0.5)
                : AdminColors.primary.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: AdminColors.primary.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 16,
          color: active
              ? chipActive
              : AdminColors.primary.withValues(alpha: 0.7),
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Filter by Pooja',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('All Poojas', selected == null, () => onSelected(null)),
              ...poojaNames.map(
                (n) => _chip(n, selected == n, () => onSelected(n)),
              ),
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
                : AdminColors.primary.withValues(alpha: 0.25),
          ),
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

class _BookingCard extends StatelessWidget {
  final AdminOrder order;
  const _BookingCard({required this.order});

  String _formatDate(DateTime dt) {
    const m = [
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
    return '${dt.day} ${m[dt.month]} ${dt.year}';
  }

  String _formatAmount(int amount) {
    final str = amount.toString();
    if (str.length <= 3) return '₹$str';
    if (str.length <= 5) {
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹${str.substring(0, str.length - 5)},${str.substring(str.length - 5, str.length - 3)},${str.substring(str.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdminBookingDetailScreen(order: order),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header strip ─────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: order.cancelled
                    ? const LinearGradient(
                        colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : AdminColors.appBarGradient,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      order.isRoomOnly
                          ? Icons.hotel_rounded
                          : Icons.auto_awesome,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.displayTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (order.userName.isNotEmpty)
                          Text(
                            order.userName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        if (order.isPrivatePooja) ...[
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_person_outlined,
                                    size: 10, color: Colors.white),
                                SizedBox(width: 3),
                                Text('Private Pooja',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _statusBadge(),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _detailRow(
                    order.isRoomOnly
                        ? Icons.hotel_rounded
                        : Icons.calendar_today_outlined,
                    order.isRoomOnly ? 'Check-in Date' : 'Pooja Date',
                    _formatDate(order.eventDate),
                    tag: order.rescheduled ? 'Rescheduled' : null,
                    tagColor: const Color(0xFF6A1B9A),
                    bold: true,
                  ),
                  if (!order.isRoomOnly) ...[
                    const SizedBox(height: 8),
                    _detailRow(Icons.people_outline, 'Persons',
                        '${order.numberOfPeople}'),
                    const SizedBox(height: 8),
                    _detailRow(Icons.family_restroom_outlined, 'Gotra',
                        order.gotra),
                  ],
                  if (order.numberOfRooms > 0) ...[
                    const SizedBox(height: 8),
                    _detailRow(
                      Icons.hotel_rounded,
                      'Stay',
                      '${order.numberOfRooms} room${order.numberOfRooms > 1 ? 's' : ''}'
                          ' × ${order.numberOfNights} night${order.numberOfNights > 1 ? 's' : ''}',
                    ),
                  ],
                  const Divider(height: 20, color: Color(0xFFE0E0E0)),
                  if (!order.isRoomOnly)
                    _costRow(
                      order.isPrivatePooja
                          ? 'Private Pooja Cost'
                          : 'Pooja Cost',
                      null,
                      _formatAmount(order.poojaAmount),
                    ),
                  if (order.numberOfRooms > 0) ...[
                    const SizedBox(height: 4),
                    _costRow(
                      'Stay',
                      '${order.numberOfRooms} rm'
                          ' × ${order.numberOfNights} nights'
                          ' × ${_formatAmount(order.stayRatePerRoom)}',
                      _formatAmount(order.stayAmount),
                    ),
                  ],
                  const Divider(height: 16, color: Color(0xFFE0E0E0)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.cancelled ? 'Amount' : 'Amount Paid',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                      Text(
                        _formatAmount(order.totalAmount),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: order.cancelled
                              ? const Color(0xFFC62828)
                              : order.poojaColor,
                          decoration: order.cancelled
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AdminColors.grey500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Booked on ${_formatDate(order.bookedOn)}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge() {
    if (order.cancelled) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined,
                size: 12, color: Color(0xFFC62828)),
            SizedBox(width: 4),
            Text('Cancelled',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC62828))),
          ],
        ),
      );
    }
    if (order.rescheduled) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_repeat_outlined,
              size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text('Rescheduled',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ],
      );
    }
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 12, color: Colors.white),
        SizedBox(width: 4),
        Text('Confirmed',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ],
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    String? tag,
    Color? tagColor,
    bool bold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AdminColors.grey500),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: AdminColors.grey700,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (tag != null) ...[
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: (tagColor ?? AdminColors.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                  color: (tagColor ?? AdminColors.primary)
                      .withValues(alpha: 0.35)),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: tagColor ?? AdminColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _costRow(String label, String? subtitle, String amount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF6B7280))),
              if (subtitle != null)
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
            ],
          ),
        ),
        Text(amount,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
