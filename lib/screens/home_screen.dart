import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/admin_models.dart';
import '../services/admin_data_service.dart';
import '../services/guruji_auth_service.dart';
import '../utils/customer_export.dart';
import '../l10n/tr.dart';
import 'bookings_screen.dart';
import 'users_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Bookings is default
  int _unreadBookings = 0;

  List<String> get _titles => [
        tr('Bookings', 'बुकिंग', 'बुकिंग'),
        tr('Customers', 'ग्राहक', 'ग्राहक'),
        tr('Settings', 'सेटिंग्स', 'सेटिंग्ज'),
        tr('Profile', 'प्रोफ़ाइल', 'प्रोफाइल'),
      ];

  static const _pages = [
    BookingsScreen(),
    UsersScreen(),
    SettingsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
    AdminDataService.newBookingsNotifier.addListener(_onNewBookings);
  }

  void _checkAuthorization() {
    // Only 9022366497 is authorized to access this app
    if (GurujiAuthService.loggedInPhone != '9022366497') {
      GurujiAuthService.logout();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('Your account is not authorized to access this app',
                'आपका खाता इस ऐप को उपयोग करने के लिए अधिकृत नहीं है',
                'तुमचे खाते हे अ‍ॅप वापरण्यासाठी अधिकृत नाही')),
            duration: const Duration(seconds: 5),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    AdminDataService.newBookingsNotifier.removeListener(_onNewBookings);
    AdminDataService.dispose();
    super.dispose();
  }

  void _onNewBookings() {
    final incoming = AdminDataService.newBookingsNotifier.value;
    if (incoming.isEmpty) return;

    // Reset the notifier so the same batch isn't shown twice.
    AdminDataService.newBookingsNotifier.value = [];

    if (!mounted) return;

    // Update badge if user isn't on the Bookings tab.
    if (_currentIndex != 0) {
      setState(() => _unreadBookings += incoming.length);
    }

    // Show a notification banner for each new booking (cap at 3).
    for (final order in incoming.take(3)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1B5E20),
          duration: const Duration(hours: 1),
          dismissDirection: DismissDirection.horizontal,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tr('New Booking!', 'नई बुकिंग!', 'नवीन बुकिंग!'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text(
                      '${order.poojaName}  ·  ${order.userName.isNotEmpty ? order.userName : order.userPhone}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: tr('View', 'देखें', 'पहा'),
            textColor: const Color(0xFF69F0AE),
            onPressed: () {
              setState(() {
                _currentIndex = 0;
                _unreadBookings = 0;
              });
            },
          ),
        ),
      );
    }
  }

  Future<void> _exportCustomers() async {
    final users = AdminDataService.dataNotifier.value.users;
    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('No customers to export yet', 'निर्यात करने के लिए अभी कोई ग्राहक नहीं है', 'एक्सपोर्ट करण्यासाठी अजून कोणताही ग्राहक नाही'))),
      );
      return;
    }
    try {
      await exportCustomersToExcel(users);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('Could not export customer list', 'ग्राहक सूची निर्यात नहीं हो सकी', 'ग्राहक यादी एक्सपोर्ट करता आली नाही'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration:
              const BoxDecoration(gradient: AdminColors.appBarGradient),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('ॐ',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w300)),
              ),
            ),
            const SizedBox(width: 10),
            Text(_titles[_currentIndex]),
          ],
        ),
        actions: [
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              tooltip: tr('Download customer list', 'ग्राहक सूची डाउनलोड करें', 'ग्राहक यादी डाउनलोड करा'),
              onPressed: _exportCustomers,
            ),
          ValueListenableBuilder<bool>(
            valueListenable: AdminDataService.loadingNotifier,
            builder: (_, loading, __) => loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Colors.white),
                    tooltip: tr('Refresh', 'रीफ़्रेश करें', 'रिफ्रेश करा'),
                    onPressed: AdminDataService.refresh,
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() {
          _currentIndex = i;
          if (i == 0) _unreadBookings = 0;
        }),
        backgroundColor: Colors.white,
        indicatorColor: AdminColors.primary.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _unreadBookings > 0,
              label: Text('$_unreadBookings'),
              child: const Icon(Icons.receipt_long_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: _unreadBookings > 0,
              label: Text('$_unreadBookings'),
              child: const Icon(Icons.receipt_long_rounded,
                  color: AdminColors.primary),
            ),
            label: tr('Bookings', 'बुकिंग', 'बुकिंग'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon:
                const Icon(Icons.people_rounded, color: AdminColors.primary),
            label: tr('Customers', 'ग्राहक', 'ग्राहक'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon:
                const Icon(Icons.settings_rounded, color: AdminColors.primary),
            label: tr('Settings', 'सेटिंग्स', 'सेटिंग्ज'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon:
                const Icon(Icons.person_rounded, color: AdminColors.primary),
            label: tr('Profile', 'प्रोफ़ाइल', 'प्रोफाइल'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return ValueListenableBuilder<AdminData>(
      valueListenable: AdminDataService.dataNotifier,
      builder: (_, data, __) {
        final lastUpdated = data.lastUpdated;
        final timeStr = lastUpdated == null
            ? tr('Never', 'कभी नहीं', 'कधीच नाही')
            : '${lastUpdated.hour.toString().padLeft(2, '0')}:${lastUpdated.minute.toString().padLeft(2, '0')}:${lastUpdated.second.toString().padLeft(2, '0')}';
        return Container(
          color: AdminColors.navyDeep,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF69F0AE),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tr(
                    'Live  ·  ${data.users.length} Users  ·  ${data.orders.length} Bookings  ·  Last updated: $timeStr',
                    'लाइव  ·  ${data.users.length} ग्राहक  ·  ${data.orders.length} बुकिंग  ·  अंतिम अपडेट: $timeStr',
                    'लाइव्ह  ·  ${data.users.length} ग्राहक  ·  ${data.orders.length} बुकिंग  ·  शेवटचे अपडेट: $timeStr'),
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }
}
