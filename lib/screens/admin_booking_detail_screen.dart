import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';
import '../l10n/tr.dart';

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
    if (_order.cancelled) return tr('Cancelled', 'रद्द', 'रद्द केलेले');
    if (_order.rescheduled) {
      return tr('Rescheduled', 'पुनर्निर्धारित', 'पुनर्नियोजित');
    }
    return tr('Confirmed', 'पक्की', 'कन्फर्म्ड');
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
        title: Text(tr('Cancel Booking', 'बुकिंग रद्द करें', 'बुकिंग रद्द करा')),
        content: Text(
          tr('Cancel booking for "${_order.poojaName}"?\nOrder: ${_order.orderId}',
              '"${_order.poojaName}" की बुकिंग रद्द करें?\nऑर्डर: ${_order.orderId}',
              '"${_order.poojaName}" ची बुकिंग रद्द करायची का?\nऑर्डर: ${_order.orderId}'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('No', 'नहीं', 'नाही')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('Yes, Cancel', 'हाँ, रद्द करें', 'होय, रद्द करा')),
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
      helpText:
          tr('Select new Pooja date', 'नई पूजा तारीख चुनें', 'नवीन पूजा तारीख निवडा'),
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
        title: Text(
            tr('Reschedule Booking', 'बुकिंग पुनर्निर्धारित करें', 'बुकिंग पुनर्नियोजित करा')),
        content: Text(
          tr(
            'Change pooja date for "${_order.poojaName}" to '
                '${_formatDate(picked)}?\n\n'
                'An email will be sent to the user and all guruji.',
            '"${_order.poojaName}" की पूजा तारीख बदलकर '
                '${_formatDate(picked)} करें?\n\n'
                'भक्त और सभी गुरुजी को ईमेल भेजा जाएगा।',
            '"${_order.poojaName}" ची पूजा तारीख बदलून '
                '${_formatDate(picked)} करायची का?\n\n'
                'भक्ताला आणि सर्व गुरुजींना ईमेल पाठवला जाईल.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Cancel', 'रद्द करें', 'रद्द करा')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade700),
            child: Text(
                tr('Reschedule', 'पुनर्निर्धारित करें', 'पुनर्नियोजित करा')),
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
        SnackBar(
          content: Text(tr('Booking rescheduled. Email sent.',
              'बुकिंग पुनर्निर्धारित हो गई। ईमेल भेज दिया गया।',
              'बुकिंग पुनर्नियोजित झाली. ईमेल पाठवला गेला.')),
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
        title: Text(tr('Booking Details', 'बुकिंग विवरण', 'बुकिंग तपशील')),
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
                        _Chip(
                          label: tr('Private', 'निजी', 'खाजगी'),
                          icon: Icons.lock_person_outlined,
                          color: const Color(0xFF6A1B9A),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Booking Reference ────────────────────────────────────────────
            _Section(
                title: tr('Booking Reference', 'बुकिंग संदर्भ', 'बुकिंग संदर्भ'),
                children: [
                  _DetailRow(
                      label: tr('Order ID', 'ऑर्डर आईडी', 'ऑर्डर आयडी'),
                      value: _order.orderId,
                      copyable: true),
                  _DetailRow(
                      label: tr('Booked On', 'बुक की गई', 'बुक केलेली'),
                      value: _formatDateTime(_order.bookedOn)),
                ]),

            // ── Pooja Details ────────────────────────────────────────────────
            if (!_order.isRoomOnly)
              _Section(
                  title: tr('Pooja Details', 'पूजा विवरण', 'पूजा तपशील'),
                  children: [
                    _DetailRow(
                        label: tr('Pooja Name', 'पूजा का नाम', 'पूजेचे नाव'),
                        value: _order.poojaName),
                    _DetailRow(
                      label: tr('Pooja Date', 'पूजा तारीख', 'पूजा तारीख'),
                      value: _formatDate(_order.poojaDate),
                    ),
                    _DetailRow(
                      label: tr('Type', 'प्रकार', 'प्रकार'),
                      value: _order.isPrivatePooja
                          ? tr('Private Pooja', 'निजी पूजा', 'खाजगी पूजा')
                          : tr('Public Pooja', 'सार्वजनिक पूजा', 'सार्वजनिक पूजा'),
                    ),
                    if (_order.gotra.isNotEmpty)
                      _DetailRow(
                          label: tr('Gotra', 'गोत्र', 'गोत्र'),
                          value: _order.gotra),
                    if (_order.rescheduled)
                      _DetailRow(
                        label: tr('Status', 'स्थिति', 'स्थिती'),
                        value: tr(
                            'Rescheduled', 'पुनर्निर्धारित', 'पुनर्नियोजित'),
                        highlight: true,
                      ),
                  ]),

            // ── Stay Details (room-only bookings) ────────────────────────────
            if (_order.isRoomOnly)
              _Section(
                  title: tr('Stay Details', 'ठहरने का विवरण', 'मुक्कामाचा तपशील'),
                  children: [
                    if (_order.roomName?.isNotEmpty == true)
                      _DetailRow(
                          label: tr('Room', 'कमरा', 'खोली'),
                          value: _order.roomName!),
                    if (_order.checkInDate != null)
                      _DetailRow(
                          label: tr(
                              'Check-in Date', 'चेक-इन तारीख', 'चेक-इन तारीख'),
                          value: _formatDate(_order.checkInDate!)),
                    _DetailRow(
                        label: tr('Rooms', 'कमरे', 'खोल्या'),
                        value: '${_order.numberOfRooms}'),
                    _DetailRow(
                        label: tr('Nights', 'रातें', 'रात्री'),
                        value: '${_order.numberOfNights}'),
                  ]),

            // ── People ───────────────────────────────────────────────────────
            _Section(title: tr('People', 'लोग', 'लोक'), children: [
              _DetailRow(
                  label: tr('Number of People', 'व्यक्तियों की संख्या',
                      'व्यक्तींची संख्या'),
                  value: '${_order.numberOfPeople}'),
            ]),

            // ── Accommodation add-on (pooja + stay) ──────────────────────────
            if (!_order.isRoomOnly && _order.numberOfRooms > 0)
              _Section(
                  title: tr('Accommodation', 'आवास', 'आवास'),
                  children: [
                    if (_order.roomName?.isNotEmpty == true)
                      _DetailRow(
                          label: tr('Room', 'कमरा', 'खोली'),
                          value: _order.roomName!),
                    _DetailRow(
                        label: tr('Rooms', 'कमरे', 'खोल्या'),
                        value: '${_order.numberOfRooms}'),
                    _DetailRow(
                        label: tr('Nights', 'रातें', 'रात्री'),
                        value: '${_order.numberOfNights}'),
                    if (_order.stayRatePerRoom > 0)
                      _DetailRow(
                          label: tr('Rate / Room / Night', 'दर / कमरा / रात',
                              'दर / खोली / रात्र'),
                          value: _formatAmount(_order.stayRatePerRoom)),
                  ]),

            // ── Cost Breakdown ───────────────────────────────────────────────
            _Section(
                title: tr('Cost Breakdown', 'कुल खर्च विवरण', 'खर्चाचा तपशील'),
                children: [
                  if (!_order.isRoomOnly && _order.poojaAmount > 0)
                    _DetailRow(
                      label: _order.isPrivatePooja
                          ? tr('Private Pooja Cost', 'निजी पूजा शुल्क',
                              'खाजगी पूजा शुल्क')
                          : tr('Pooja Cost', 'पूजा शुल्क', 'पूजा शुल्क'),
                      value: _order.numberOfPeople > 1
                          ? '${_formatAmount(_order.poojaAmount ~/ _order.numberOfPeople)} × ${_order.numberOfPeople} = ${_formatAmount(_order.poojaAmount)}'
                          : _formatAmount(_order.poojaAmount),
                    ),
                  if (_order.numberOfRooms > 0 && _order.stayRatePerRoom > 0)
                    _DetailRow(
                      label: tr('Stay Cost', 'ठहरने का शुल्क', 'मुक्कामाचे शुल्क'),
                      value: tr(
                        '${_formatAmount(_order.stayRatePerRoom)} × ${_order.numberOfRooms} rm × ${_order.numberOfNights} night${_order.numberOfNights > 1 ? 's' : ''} = ${_formatAmount(_order.stayAmount)}',
                        '${_formatAmount(_order.stayRatePerRoom)} × ${_order.numberOfRooms} कमरे × ${_order.numberOfNights} रात = ${_formatAmount(_order.stayAmount)}',
                        '${_formatAmount(_order.stayRatePerRoom)} × ${_order.numberOfRooms} खोल्या × ${_order.numberOfNights} रात्री = ${_formatAmount(_order.stayAmount)}',
                      ),
                    ),
                  _AmountRow(
                    label: _order.cancelled
                        ? tr('Total Amount', 'कुल राशि', 'एकूण रक्कम')
                        : tr('Total Paid', 'कुल भुगतान', 'एकूण भरणा'),
                    value: _formatAmount(_order.totalAmount),
                    cancelled: _order.cancelled,
                    color: _accentColor,
                  ),
                ]),

            // ── Booked By ────────────────────────────────────────────────────
            if (_order.userName.isNotEmpty || _order.userPhone.isNotEmpty)
              _Section(
                  title: tr('Booked By', 'बुक करने वाला', 'बुक करणारे'),
                  children: [
                    if (_order.userName.isNotEmpty)
                      _DetailRow(
                          label: tr('Name', 'नाम', 'नाव'),
                          value: _order.userName),
                    if (_order.userPhone.isNotEmpty)
                      _DetailRow(
                          label: tr('Phone', 'फ़ोन नंबर', 'फोन नंबर'),
                          value: _order.userPhone),
                  ]),

            // ── Pooja For / Booked For ───────────────────────────────────────
            if (_order.bookedForName.isNotEmpty ||
                _order.bookedForPhone.isNotEmpty)
              _Section(
                  title:
                      tr('Booked For', 'जिनके लिए बुक की', 'ज्यांच्यासाठी बुक केली'),
                  children: [
                    if (_order.bookedForName.isNotEmpty)
                      _DetailRow(
                          label: tr('Name', 'नाम', 'नाव'),
                          value: _order.bookedForName),
                    if (_order.bookedForPhone.isNotEmpty)
                      _DetailRow(
                          label: tr('Phone', 'फ़ोन नंबर', 'फोन नंबर'),
                          value: _order.bookedForPhone),
                    if (_order.bookedForEmail.isNotEmpty)
                      _DetailRow(
                          label: tr('Email', 'ईमेल', 'ईमेल'),
                          value: _order.bookedForEmail),
                    if (_order.bookedForCity.isNotEmpty)
                      _DetailRow(
                          label: tr('City', 'शहर', 'शहर'),
                          value: _order.bookedForCity),
                    if (_order.bookedForZipCode.isNotEmpty)
                      _DetailRow(
                          label: tr('ZIP / PIN', 'पिन कोड', 'पिन कोड'),
                          value: _order.bookedForZipCode),
                    if (_order.bookedForCountry.isNotEmpty)
                      _DetailRow(
                          label: tr('Country', 'देश', 'देश'),
                          value: _order.bookedForCountry),
                  ]),

            if (_order.bookedForName.isEmpty &&
                _order.bookedForPhone.isEmpty &&
                (_order.userName.isNotEmpty || _order.userPhone.isNotEmpty))
              _Section(
                  title: tr('Pooja For', 'पूजा जिनके लिए', 'ज्यांच्यासाठी पूजा'),
                  children: [
                    if (_order.userName.isNotEmpty)
                      _DetailRow(
                          label: tr('Name', 'नाम', 'नाव'),
                          value: _order.userName),
                    if (_order.userPhone.isNotEmpty)
                      _DetailRow(
                          label: tr('Phone', 'फ़ोन नंबर', 'फोन नंबर'),
                          value: _order.userPhone),
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
                              label: Text(tr('Reschedule', 'पुनर्निर्धारित करें',
                                  'पुनर्नियोजित करा')),
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
                            label: Text(
                                tr('Cancel Booking', 'बुकिंग रद्द करें',
                                    'बुकिंग रद्द करा'),
                                style: const TextStyle(color: Colors.white)),
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
                    content: Text(
                        tr('$label copied', '$label कॉपी हो गया', '$label कॉपी झाले')),
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
