import 'package:flutter/material.dart';

class AdminUser {
  final String fullName;
  final String phone;
  final String email;
  final String city;
  final String pinCode;
  final String country;

  const AdminUser({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.city,
    required this.pinCode,
    required this.country,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        city: json['city'] as String? ?? '',
        pinCode: json['pinCode'] as String? ?? '',
        country: json['country'] as String? ?? 'India',
      );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (fullName.isNotEmpty) return fullName[0].toUpperCase();
    return 'U';
  }
}

class AdminOrder {
  final String orderId;
  final String poojaName;
  final DateTime poojaDate;
  final int numberOfPeople;
  final String gotra;
  final int totalAmount;
  final DateTime bookedOn;
  final Color poojaColor;
  final String userName;
  final String userPhone;
  final String bookedForName;
  final String bookedForPhone;
  final String bookedForEmail;
  final String bookedForCity;
  final String bookedForZipCode;
  final String bookedForCountry;
  final bool cancelled;

  const AdminOrder({
    required this.orderId,
    required this.poojaName,
    required this.poojaDate,
    required this.numberOfPeople,
    required this.gotra,
    required this.totalAmount,
    required this.bookedOn,
    required this.poojaColor,
    required this.userName,
    required this.userPhone,
    required this.bookedForName,
    required this.bookedForPhone,
    required this.bookedForEmail,
    required this.bookedForCity,
    required this.bookedForZipCode,
    required this.bookedForCountry,
    this.cancelled = false,
  });

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    final hex = (json['poojaColorHex'] as String? ?? '#1565C0')
        .replaceFirst('#', '');
    final color = Color(int.parse('FF$hex', radix: 16));
    return AdminOrder(
      orderId: json['orderId'] as String? ?? '',
      poojaName: json['poojaName'] as String? ?? '',
      poojaDate: DateTime.tryParse(json['poojaDate'] as String? ?? '') ?? DateTime.now(),
      numberOfPeople: (json['numberOfPeople'] as num?)?.toInt() ?? 1,
      gotra: json['gotra'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      bookedOn: DateTime.tryParse(json['bookedOn'] as String? ?? '') ??
          DateTime.now(),
      poojaColor: color,
      userName: json['userName'] as String? ?? '',
      userPhone: json['userPhone'] as String? ?? '',
      bookedForName: json['bookedForName'] as String? ?? '',
      bookedForPhone: json['bookedForPhone'] as String? ?? '',
      bookedForEmail: json['bookedForEmail'] as String? ?? '',
      bookedForCity: json['bookedForCity'] as String? ?? '',
      bookedForZipCode: json['bookedForZipCode'] as String? ?? '',
      bookedForCountry: json['bookedForCountry'] as String? ?? '',
      cancelled: json['cancelled'] as bool? ?? false,
    );
  }
}

class AdminPooja {
  final int id;
  final String name;
  final String description;
  final int pricePerPerson;
  final String colorHex;
  final bool enabled;
  final String iconName;
  final String duration;
  final int? displayOrder;
  final String info;
  final List<String> beforeInstructions;
  final List<String> afterInstructions;
  final List<String> thingsToBring;

  const AdminPooja({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerPerson,
    required this.colorHex,
    required this.enabled,
    this.iconName = '',
    this.duration = '',
    this.displayOrder,
    this.info = '',
    this.beforeInstructions = const [],
    this.afterInstructions = const [],
    this.thingsToBring = const [],
  });

  factory AdminPooja.fromJson(Map<String, dynamic> json) => AdminPooja(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        pricePerPerson: (json['pricePerPerson'] as num?)?.toInt() ?? 0,
        colorHex: json['colorHex'] as String? ?? '#1565C0',
        enabled: json['enabled'] as bool? ?? true,
        iconName: json['iconName'] as String? ?? '',
        duration: json['duration'] as String? ?? '',
        displayOrder: (json['displayOrder'] as num?)?.toInt(),
        info: json['info'] as String? ?? '',
        beforeInstructions: (json['beforeInstructions'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        afterInstructions: (json['afterInstructions'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        thingsToBring: (json['thingsToBring'] as List?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class AdminData {
  final List<AdminUser> users;
  final List<AdminOrder> orders;
  final List<AdminPooja> poojas;
  final DateTime? lastUpdated;

  const AdminData({
    required this.users,
    required this.orders,
    required this.poojas,
    this.lastUpdated,
  });

  static const empty = AdminData(users: [], orders: [], poojas: []);
}
