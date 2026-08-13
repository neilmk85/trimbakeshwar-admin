import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';

class AdminBookingDetailScreen extends StatefulWidget {
  final AdminOrder order;
  const AdminBookingDetailScreen({super.key, required this.order});

  @override
  State<AdminBookingDetailScreen> createState() =>
      _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends State<AdminBookingDetailScreen> {
  late AdminOrder _order;
  bool _cancelling = false;
  bool _rescheduling = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    // Keep in sync with live data
    AdminDataService.dataNotifier.addListener(_syncOrder);
  }

  @override
  void dispose() {
    AdminDataService.dataNotifier.removeListener(_syncOrder);
    super.dispose();
  }

  void _syncOrder() {
    final updated = AdminDataService.dataNotifier.value.orders
        .where((o) => o.orderId == _order.orderId)
        .firstOrNull;
    if (updated != null && mounted) setState(() => _order = updated);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

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

  String _formatDateTime(DateTime dt) {
    final date = _formatDate(dt);
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$date, $h:$m $ampm';
  }

  String _formatAmount(int amount) {
    final str = amount.toString();
    if (str.length <= 3) return '₹$str';
    if (str.length <= 5) {
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹${str.substring(0, str.length - 5)},${str.substring(str.length - 5, str.length - 3)},${str.substring(str.length - 3)}';
  }

  // ── Status helpers ───────────────────────────────────────────────────────────

  String get _statusLabel {
    if (_order.cancelled) return 'Cancelled';
    if (_order.rescheduled) return 'Rescheduled';
    return 'Confirmed';
  }

  IconData get _statusIcon {
    if (_order.cancelled) return Icons.cancel_outlined;
    if (_order.rescheduled) return Icons.event_repeat_outlined;
    return Icons.check_circle_outline;
  }

  Color get _statusColor {
    if (_order.cancelled) return const Color(0xFFC62828);
    if (_order.rescheduled) return const Color(0xFF6A1B9A);
    return const Color(0xFF1565C0);
  }

  Color get _accentColor =>
      _order.cancelled ? const Color(0xFFC62828) : _order.poojaColor;

  // ── Actions ──────────────────────────────────────────────────────────────────

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Cancel booking for "${_order.poojaName}"?\nOrder: ${_order.orderId}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    final err = await AdminDataService.cancelBooking(_order.orderId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reschedule() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _order.poojaDate.isAfter(DateTime.now())
          ? _order.poojaDate
          : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      helpText: 'Select new Pooja date',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AdminColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reschedule Booking'),
        content: Text(
          'Change pooja date for "${_order.poojaName}" to '
          '${_formatDate(picked)}?\n\n'
          'An email will be sent to the user and all guruji.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700),
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _rescheduling = true);
    final err =
        await AdminDataService.rescheduleBooking(_order.orderId, picked);
    if (!mounted) return;
    setState(() => _rescheduling = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking rescheduled. Email sent.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final showActions = !_order.cancelled;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Booking Details'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AdminColors.appBarGradient),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, showActions ? 100 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Identity card ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: _accentColor, width: 4),
                ),
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
                          _order.displayTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _order.orderId,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _Chip(
                        label: _statusLabel,
                        icon: _statusIcon,
                        color: _statusColor,
                      ),
                      if (_order.isPrivatePooja) ...[
                        const SizedBox(height: 4),
                        const _Chip(
                          label: 'Private',
                          icon: Icons.lock_person_outlined,
                          color: Color(0xFF6A1B9A),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Booking Reference ────────────────────────────────────────────
            _Section(title: 'Booking Reference', children: [
              _DetailRow(
                  label: 'Order ID', value: _order.orderId, copyable: true),
              _DetailRow(
                  label: 'Booked On',
                  value: _formatDateTime(_order.bookedOn)),
            ]),

            // ── Pooja Details ────────────────────────────────────────────────
            if (!_order.isRoomOnly)
              _Section(title: 'Pooja Details', children: [
                _DetailRow(label: 'Pooja Name', value: _order.poojaName),
                _DetailRow(
                  label: 'Pooja Date',
                  value: _formatDate(_order.poojaDate),
                ),
                _DetailRow(
                  label: 'Type',
                  value: _order.isPrivatePooja
                      ? 'Private Pooja'
                      : 'Public Pooja',
                ),
                if (_order.gotra.isNotEmpty)
                  _DetailRow(label: 'Gotra', value: _order.gotra),
                if (_order.rescheduled)
                  const _DetailRow(
                    label: 'Status',
                    value: 'Rescheduled',
                    highlight: true,
                  ),
              ]),

            // ── Stay Details (room-only bookings) ────────────────────────────
            if (_order.isRoomOnly)
              _Section(title: 'Stay Details', children: [
                if (_order.roomName?.isNotEmpty == true)
                  _DetailRow(label: 'Room', value: _order.roomName!),
                if (_order.checkInDate != null)
                  _DetailRow(
                      label: 'Check-in Date',
                      value: _formatDate(_order.checkInDate!)),
                _DetailRow(
                    label: 'Rooms', value: '${_order.numberOfRooms}'),
                _DetailRow(
                    label: 'Nights', value: '${_order.numberOfNights}'),
              ]),

            // ── People ───────────────────────────────────────────────────────
            _Section(title: 'People', children: [
              _DetailRow(
                  label: 'Number of People',
                  value: '${_order.numberOfPeople}'),
            ]),

            // ── Accommodation add-on (pooja + stay) ──────────────────────────
            if (!_order.isRoomOnly && _order.numberOfRooms > 0)
              _Section(title: 'Accommodation', children: [
                if (_order.roomName?.isNotEmpty == true)
                  _DetailRow(label: 'Room', value: _order.roomName!),
                _DetailRow(
                    label: 'Rooms', value: '${_order.numberOfRooms}'),
                _DetailRow(
                    label: 'Nights', value: '${_order.numberOfNights}'),
                if (_order.stayRatePerRoom > 0)
                  _DetailRow(
                      label: 'Rate / Room / Night',
                      value: _formatAmount(_order.stayRatePerRoom)),
              ]),

            // ── Cost Breakdown ───────────────────────────────────────────────
            _Section(title: 'Cost Breakdown', children: [
              if (!_order.isRoomOnly && _order.poojaAmount > 0)
                _DetailRow(
                  label: _order.isPrivatePooja
                      ? 'Private Pooja Cost'
                      : 'Pooja Cost',
                  value: _order.numberOfPeople > 1
                      ? '${_formatAmount(_order.poojaAmount ~/ _order.numberOfPeople)} × ${_order.numberOfPeople} = ${_formatAmount(_order.poojaAmount)}'
                      : _formatAmount(_order.poojaAmount),
                ),
              if (_order.numberOfRooms > 0 && _order.stayRatePerRoom > 0)
                _DetailRow(
                  label: 'Stay Cost',
                  value:
                      '${_formatAmount(_order.stayRatePerRoom)} × ${_order.numberOfRooms} rm × ${_order.numberOfNights} night${_order.numberOfNights > 1 ? 's' : ''} = ${_formatAmount(_order.stayAmount)}',
                ),
              _AmountRow(
                label: _order.cancelled ? 'Total Amount' : 'Total Paid',
                value: _formatAmount(_order.totalAmount),
                cancelled: _order.cancelled,
                color: _accentColor,
              ),
            ]),

            // ── Booked By ────────────────────────────────────────────────────
            if (_order.userName.isNotEmpty || _order.userPhone.isNotEmpty)
              _Section(title: 'Booked By', children: [
                if (_order.userName.isNotEmpty)
                  _DetailRow(label: 'Name', value: _order.userName),
                if (_order.userPhone.isNotEmpty)
                  _DetailRow(label: 'Phone', value: _order.userPhone),
              ]),

            // ── Pooja For / Booked For ───────────────────────────────────────
            if (_order.bookedForName.isNotEmpty ||
                _order.bookedForPhone.isNotEmpty)
              _Section(title: 'Booked For', children: [
                if (_order.bookedForName.isNotEmpty)
                  _DetailRow(label: 'Name', value: _order.bookedForName),
                if (_order.bookedForPhone.isNotEmpty)
                  _DetailRow(label: 'Phone', value: _order.bookedForPhone),
                if (_order.bookedForEmail.isNotEmpty)
                  _DetailRow(label: 'Email', value: _order.bookedForEmail),
                if (_order.bookedForCity.isNotEmpty)
                  _DetailRow(label: 'City', value: _order.bookedForCity),
                if (_order.bookedForZipCode.isNotEmpty)
                  _DetailRow(
                      label: 'ZIP / PIN', value: _order.bookedForZipCode),
                if (_order.bookedForCountry.isNotEmpty)
                  _DetailRow(
                      label: 'Country', value: _order.bookedForCountry),
              ]),

            if (_order.bookedForName.isEmpty &&
                _order.bookedForPhone.isEmpty &&
                (_order.userName.isNotEmpty || _order.userPhone.isNotEmpty))
              _Section(title: 'Pooja For', children: [
                if (_order.userName.isNotEmpty)
                  _DetailRow(label: 'Name', value: _order.userName),
                if (_order.userPhone.isNotEmpty)
                  _DetailRow(label: 'Phone', value: _order.userPhone),
              ]),
          ],
        ),
      ),

      // ── Admin action bar ─────────────────────────────────────────────────────
      bottomNavigationBar: showActions
          ? Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: _cancelling || _rescheduling
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Row(
                      children: [
                        if (!_order.isRoomOnly)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _reschedule,
                              icon: const Icon(
                                  Icons.edit_calendar_rounded,
                                  size: 16),
                              label: const Text('Reschedule'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue.shade700,
                                side: BorderSide(
                                    color: Colors.blue.shade300),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        if (!_order.isRoomOnly) const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _confirmCancel,
                            icon: const Icon(Icons.cancel_outlined,
                                size: 16, color: Colors.white),
                            label: const Text('Cancel Booking',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
            )
          : null,
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Chip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

// ── Section ───────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AdminColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  final bool highlight;

  const _DetailRow({
    required this.label,
    required this.value,
    this.copyable = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: highlight
                    ? const Color(0xFF6A1B9A)
                    : const Color(0xFF111827),
              ),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.copy_rounded,
                    size: 15, color: Color(0xFF9CA3AF)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Amount row ────────────────────────────────────────────────────────────────

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool cancelled;
  final Color color;

  const _AmountRow({
    required this.label,
    required this.value,
    required this.cancelled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: color,
              decoration: cancelled ? TextDecoration.lineThrough : null,
              decorationColor: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
