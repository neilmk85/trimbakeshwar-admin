import 'package:flutter/material.dart';

class AdminUser {
  final String fullName;
  final String phone;
  final String email;
  final String city;
  final String pinCode;
  final String country;
  final DateTime? createdAt;

  const AdminUser({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.city,
    required this.pinCode,
    required this.country,
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        fullName: json['fullName'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        city: json['city'] as String? ?? '',
        pinCode: json['pinCode'] as String? ?? '',
        country: json['country'] as String? ?? 'India',
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
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
  final DateTime? checkInDate;
  final String bookingType;
  final String? roomName;
  final int? roomId;
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
  final int numberOfRooms;
  final int numberOfNights;
  final int stayRatePerRoom;
  final bool cancelled;
  final bool rescheduled;
  final bool isPrivatePooja;

  const AdminOrder({
    required this.orderId,
    required this.poojaName,
    required this.poojaDate,
    this.checkInDate,
    this.bookingType = 'pooja',
    this.roomName,
    this.roomId,
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
    this.numberOfRooms = 0,
    this.numberOfNights = 0,
    this.stayRatePerRoom = 0,
    this.cancelled = false,
    this.rescheduled = false,
    this.isPrivatePooja = false,
  });

  bool get isRoomOnly => bookingType == 'room_only';

  String get displayTitle => isRoomOnly
      ? (roomName?.isNotEmpty == true ? 'Room Stay – $roomName' : 'Room Booking')
      : poojaName;

  DateTime get eventDate => isRoomOnly ? (checkInDate ?? poojaDate) : poojaDate;

  int get poojaAmount => totalAmount - stayAmount;
  int get stayAmount => stayRatePerRoom * numberOfRooms * numberOfNights;

  factory AdminOrder.fromJson(Map<String, dynamic> json) {
    final hex = (json['poojaColorHex'] as String? ?? '#1565C0')
        .replaceFirst('#', '');
    final color = Color(int.parse('FF$hex', radix: 16));
    return AdminOrder(
      orderId: json['orderId'] as String? ?? '',
      poojaName: json['poojaName'] as String? ?? '',
      poojaDate: DateTime.tryParse(json['poojaDate'] as String? ?? '') ?? DateTime.now(),
      checkInDate: DateTime.tryParse(json['checkInDate'] as String? ?? ''),
      bookingType: json['bookingType'] as String? ?? 'pooja',
      roomName: json['roomName'] as String?,
      roomId: (json['roomId'] as num?)?.toInt(),
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
      numberOfRooms: (json['numberOfRooms'] as num?)?.toInt() ?? 0,
      numberOfNights: (json['numberOfNights'] as num?)?.toInt() ?? 0,
      stayRatePerRoom: (json['stayRatePerRoom'] as num?)?.toInt() ?? 0,
      cancelled: json['cancelled'] as bool? ?? false,
      rescheduled: json['rescheduled'] as bool? ?? false,
      isPrivatePooja: json['isPrivatePooja'] as bool? ?? false,
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
  final List<DateTime> muhurtaDates;
  final int stayRatePerNight;
  final bool privatePooja;
  final int privatePoojaRate;
  final int gurujiDefaultRate;

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
    this.muhurtaDates = const [],
    this.stayRatePerNight = 0,
    this.privatePooja = false,
    this.privatePoojaRate = 0,
    this.gurujiDefaultRate = 0,
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
        stayRatePerNight: (json['stayRatePerNight'] as num?)?.toInt() ?? 0,
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
        muhurtaDates: (json['muhurtaDates'] as List?)
                ?.map((e) => DateTime.tryParse(e as String))
                .whereType<DateTime>()
                .toList() ??
            [],
        privatePooja: json['privatePooja'] as bool? ?? false,
        privatePoojaRate: (json['privatePoojaRate'] as num?)?.toInt() ?? 0,
        gurujiDefaultRate: (json['gurujiDefaultRate'] as num?)?.toInt() ?? 0,
      );

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}

class GurujiDirectoryEntry {
  final int id;
  final String name;
  final String phone;
  final String email;

  const GurujiDirectoryEntry({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
  });

  factory GurujiDirectoryEntry.fromJson(Map<String, dynamic> json) => GurujiDirectoryEntry(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
      );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'G';
  }
}

class GurujiPoojaRate {
  final int poojaId;
  final String poojaName;
  final int rate;
  final bool isOverridden;

  const GurujiPoojaRate({
    required this.poojaId,
    required this.poojaName,
    required this.rate,
    required this.isOverridden,
  });

  factory GurujiPoojaRate.fromJson(Map<String, dynamic> json) => GurujiPoojaRate(
        poojaId: (json['poojaId'] as num?)?.toInt() ?? 0,
        poojaName: json['poojaName'] as String? ?? '',
        rate: (json['rate'] as num?)?.toInt() ?? 0,
        isOverridden: json['isOverridden'] as bool? ?? false,
      );
}

class AdminRoom {
  final int id;
  final String name;
  final String type;
  final int pricePerNight;
  final String capacity;
  final List<String> amenities;
  final String description;
  final String imageUrl;
  final bool available;
  final int displayOrder;
  final int count;

  const AdminRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.pricePerNight,
    required this.capacity,
    required this.amenities,
    required this.description,
    required this.imageUrl,
    required this.available,
    required this.displayOrder,
    this.count = 1,
  });

  factory AdminRoom.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return AdminRoom(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'Non-AC',
      pricePerNight: (json['pricePerNight'] as num?)?.toInt() ?? 0,
      capacity: json['capacity'] as String? ?? '2 Persons',
      amenities: parseList(json['amenities']),
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      available: json['available'] as bool? ?? true,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 1,
    );
  }
}

class RoomBlock {
  final int id;
  final int roomId;
  final String guestName;
  final String notes;
  final DateTime checkInDate;
  final int numberOfNights;
  final int numberOfRooms;

  const RoomBlock({
    required this.id,
    required this.roomId,
    required this.guestName,
    required this.notes,
    required this.checkInDate,
    required this.numberOfNights,
    required this.numberOfRooms,
  });

  factory RoomBlock.fromJson(Map<String, dynamic> json) => RoomBlock(
        id: (json['id'] as num?)?.toInt() ?? 0,
        roomId: (json['roomId'] as num?)?.toInt() ?? 0,
        guestName: json['guestName'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        checkInDate: DateTime.tryParse(json['checkInDate'] as String? ?? '') ?? DateTime.now(),
        numberOfNights: (json['numberOfNights'] as num?)?.toInt() ?? 1,
        numberOfRooms: (json['numberOfRooms'] as num?)?.toInt() ?? 1,
      );
}

class RoomBlockBoard {
  final int roomId;
  final int totalCount;
  final String date;
  final int onlineBookedCount;
  final List<RoomBlock> walkInBlocks;
  final int walkInBlockedCount;
  final int availableCount;

  const RoomBlockBoard({
    required this.roomId,
    required this.totalCount,
    required this.date,
    required this.onlineBookedCount,
    required this.walkInBlocks,
    required this.walkInBlockedCount,
    required this.availableCount,
  });

  factory RoomBlockBoard.fromJson(Map<String, dynamic> json) => RoomBlockBoard(
        roomId: (json['roomId'] as num?)?.toInt() ?? 0,
        totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
        date: json['date'] as String? ?? '',
        onlineBookedCount: (json['onlineBookedCount'] as num?)?.toInt() ?? 0,
        walkInBlocks: (json['walkInBlocks'] as List? ?? [])
            .map((e) => RoomBlock.fromJson(e as Map<String, dynamic>))
            .toList(),
        walkInBlockedCount: (json['walkInBlockedCount'] as num?)?.toInt() ?? 0,
        availableCount: (json['availableCount'] as num?)?.toInt() ?? 0,
      );
}

class AccommodationSettings {
  final int totalRooms;
  final int personsPerRoom;
  final int pricePerRoom;
  final int pricePerPerson;

  const AccommodationSettings({
    this.totalRooms = 0,
    this.personsPerRoom = 2,
    this.pricePerRoom = 0,
    this.pricePerPerson = 0,
  });

  static const empty = AccommodationSettings();

  factory AccommodationSettings.fromJson(Map<String, dynamic> json) =>
      AccommodationSettings(
        totalRooms: (json['totalRooms'] as num?)?.toInt() ?? 0,
        personsPerRoom: (json['personsPerRoom'] as num?)?.toInt() ?? 2,
        pricePerRoom: (json['pricePerRoom'] as num?)?.toInt() ?? 0,
        pricePerPerson: (json['pricePerPerson'] as num?)?.toInt() ?? 0,
      );
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
