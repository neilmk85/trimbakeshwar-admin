import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';
import 'admin_booking_detail_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final AdminUser user;
  const CustomerDetailScreen({super.key, required this.user});

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: user.phone);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AdminColors.appBarGradient),
        ),
        title: Text(user.fullName.isEmpty ? 'Customer' : user.fullName),
        actions: [
          if (user.phone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call_rounded),
              tooltip: 'Call',
              onPressed: () => _call(context),
            ),
        ],
      ),
      body: ValueListenableBuilder<AdminData>(
        valueListenable: AdminDataService.dataNotifier,
        builder: (_, data, __) {
          final bookings = data.orders
              .where((o) => o.userPhone == user.phone)
              .toList();

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final upcoming = bookings
              .where((o) => !o.cancelled && !o.eventDate.isBefore(today))
              .toList()
            ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

          final history = bookings
              .where((o) => o.cancelled || o.eventDate.isBefore(today))
              .toList()
            ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

          final totalPaid = bookings
              .where((o) => !o.cancelled)
              .fold<int>(0, (sum, o) => sum + o.totalAmount);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _profileCard(),
              const SizedBox(height: 14),
              _statsRow(bookings.length, totalPaid, upcoming.length),
              const SizedBox(height: 22),
              _sectionHeader('Upcoming Poojas', Icons.upcoming_rounded),
              const SizedBox(height: 10),
              if (upcoming.isEmpty)
                _emptyNote('No upcoming poojas or bookings.')
              else
                ...upcoming.map((o) => _BookingRow(order: o)),
              const SizedBox(height: 22),
              _sectionHeader('Pooja History', Icons.history_rounded),
              const SizedBox(height: 10),
              if (history.isEmpty)
                _emptyNote('No past bookings yet.')
              else
                ...history.map((o) => _BookingRow(order: o)),
            ],
          );
        },
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  gradient: AdminColors.appBarGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName.isEmpty ? 'Unknown' : user.fullName,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E)),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.phone.isEmpty ? 'No phone number' : user.phone,
                      style: TextStyle(fontSize: 14, color: AdminColors.grey600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.email.isNotEmpty ||
              user.city.isNotEmpty ||
              user.country.isNotEmpty ||
              user.createdAt != null) ...[
            const Divider(height: 26),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.email.isNotEmpty)
                  _infoLine(Icons.email_outlined, user.email),
                if (user.city.isNotEmpty ||
                    user.pinCode.isNotEmpty ||
                    user.country.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoLine(
                    Icons.location_on_outlined,
                    [
                      if (user.city.isNotEmpty) user.city,
                      if (user.pinCode.isNotEmpty) user.pinCode,
                      if (user.country.isNotEmpty) user.country,
                    ].join(', '),
                  ),
                ],
                if (user.createdAt != null) ...[
                  const SizedBox(height: 8),
                  _infoLine(Icons.event_available_outlined,
                      'Registered on ${_formatDate(user.createdAt!)}'),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AdminColors.grey500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13.5, color: AdminColors.grey700, height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _statsRow(int totalBookings, int totalPaid, int upcomingCount) {
    return Row(
      children: [
        Expanded(child: _statCard(label: 'Bookings', value: '$totalBookings')),
        const SizedBox(width: 10),
        Expanded(child: _statCard(label: 'Total Paid', value: _formatAmount(totalPaid))),
        const SizedBox(width: 10),
        Expanded(child: _statCard(label: 'Upcoming', value: '$upcomingCount')),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            value,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AdminColors.grey500),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AdminColors.grey700),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
        ),
      ],
    );
  }

  Widget _emptyNote(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, color: AdminColors.grey500),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  static String _formatAmount(int amount) {
    final str = amount.toString();
    if (str.length <= 3) return '₹$str';
    if (str.length <= 5) {
      return '₹${str.substring(0, str.length - 3)},${str.substring(str.length - 3)}';
    }
    return '₹${str.substring(0, str.length - 5)},${str.substring(str.length - 5, str.length - 3)},${str.substring(str.length - 3)}';
  }
}

class _BookingRow extends StatelessWidget {
  final AdminOrder order;
  const _BookingRow({required this.order});

  String _formatDate(DateTime dt) {
    const m = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminBookingDetailScreen(order: order),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: order.cancelled
                        ? const Color(0xFFC62828).withValues(alpha: 0.1)
                        : order.poojaColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    order.isRoomOnly ? Icons.hotel_rounded : Icons.auto_awesome,
                    size: 18,
                    color: order.cancelled ? const Color(0xFFC62828) : order.poojaColor,
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
                            fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            _formatDate(order.eventDate),
                            style: TextStyle(fontSize: 12, color: AdminColors.grey600),
                          ),
                          if (order.cancelled) ...[
                            const SizedBox(width: 6),
                            _tag('Cancelled', const Color(0xFFC62828)),
                          ] else if (order.rescheduled) ...[
                            const SizedBox(width: 6),
                            _tag('Rescheduled', const Color(0xFF6A1B9A)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatAmount(order.totalAmount),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: order.cancelled ? const Color(0xFFC62828) : order.poojaColor,
                    decoration: order.cancelled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
