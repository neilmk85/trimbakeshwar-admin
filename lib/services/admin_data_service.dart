import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/admin_models.dart';

class AdminDataService {
  AdminDataService._();

  static const _base = 'https://app.trimbakeshwarpoojavidhi.in/api';

  static final ValueNotifier<AdminData> dataNotifier =
      ValueNotifier(AdminData.empty);

  static final ValueNotifier<bool> loadingNotifier = ValueNotifier(false);
  static final ValueNotifier<String?> errorNotifier = ValueNotifier(null);

  /// Emits newly-arrived orders detected during background polling.
  /// Consumers should reset this to [] after handling.
  static final ValueNotifier<List<AdminOrder>> newBookingsNotifier =
      ValueNotifier([]);

  /// Order IDs seen during the initial load — used to detect truly new ones.
  static final Set<String> _knownOrderIds = {};

  static Timer? _pollingTimer;

  static Future<void> init() async {
    await refresh();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _silentRefresh();
    });
  }

  static void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  static Future<void> refresh() async {
    loadingNotifier.value = true;
    errorNotifier.value = null;
    try {
      final data = await _fetchData();
      dataNotifier.value = data;
      // Seed known IDs on initial load so we don't notify for existing bookings.
      _knownOrderIds.addAll(data.orders.map((o) => o.orderId));
    } catch (e) {
      errorNotifier.value =
          'Could not reach server.\nPlease check your internet connection and try again.';
    } finally {
      loadingNotifier.value = false;
    }
  }

  static Future<void> _silentRefresh() async {
    try {
      final data = await _fetchData();

      // Detect orders that weren't in the previous snapshot.
      final incoming = data.orders
          .where((o) => !_knownOrderIds.contains(o.orderId))
          .toList();
      if (incoming.isNotEmpty) {
        _knownOrderIds.addAll(incoming.map((o) => o.orderId));
        newBookingsNotifier.value = incoming;
      }

      dataNotifier.value = data;
      errorNotifier.value = null;
    } catch (_) {}
  }

  /// Fetches a single URL, retrying up to [retries] times on non-200 responses.
  static Future<http.Response> _getWithRetry(
    String url, {
    int retries = 4,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    for (var attempt = 0; attempt <= retries; attempt++) {
      final res = await http.get(Uri.parse(url)).timeout(timeout);
      if (res.statusCode == 200) return res;
      if (attempt < retries) {
        await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
      }
    }
    throw Exception('Server returned non-200 after $retries retries: $url');
  }

  static Future<AdminData> _fetchData() async {
    final responses = await Future.wait([
      _getWithRetry('$_base/users'),
      _getWithRetry('$_base/bookings'),
      _getWithRetry('$_base/poojas/all'),
    ]);

    if (responses[0].statusCode != 200 ||
        responses[1].statusCode != 200 ||
        responses[2].statusCode != 200) {
      throw Exception('Server returned an error');
    }

    final users =
        ((jsonDecode(responses[0].body) as Map<String, dynamic>)['data'] as List? ?? [])
            .map((u) => AdminUser.fromJson(u as Map<String, dynamic>))
            .toList();

    final orders =
        ((jsonDecode(responses[1].body) as Map<String, dynamic>)['data'] as List? ?? [])
            .map((o) => AdminOrder.fromJson(o as Map<String, dynamic>))
            .toList();

    final poojas =
        ((jsonDecode(responses[2].body) as Map<String, dynamic>)['data'] as List? ?? [])
            .map((p) => AdminPooja.fromJson(p as Map<String, dynamic>))
            .toList();

    return AdminData(
      users: users,
      orders: orders,
      poojas: poojas,
      lastUpdated: DateTime.now(),
    );
  }

  /// Create a new pooja and add it to local state.
  static Future<String?> createPooja({
    required String name,
    required String description,
    required int pricePerPerson,
    required String colorHex,
    required bool enabled,
    String? iconName,
    String? duration,
    int? displayOrder,
    String? info,
    List<String>? beforeInstructions,
    List<String>? afterInstructions,
    List<String>? thingsToBring,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'description': description,
        'pricePerPerson': pricePerPerson,
        'colorHex': colorHex,
        'enabled': enabled,
        if (iconName != null && iconName.isNotEmpty) 'iconName': iconName,
        if (duration != null && duration.isNotEmpty) 'duration': duration,
        if (displayOrder != null) 'displayOrder': displayOrder,
        if (info != null && info.isNotEmpty) 'info': info,
        if (beforeInstructions != null && beforeInstructions.isNotEmpty)
          'beforeInstructions': beforeInstructions,
        if (afterInstructions != null && afterInstructions.isNotEmpty)
          'afterInstructions': afterInstructions,
        if (thingsToBring != null && thingsToBring.isNotEmpty)
          'thingsToBring': thingsToBring,
      };
      final res = await http
          .post(
            Uri.parse('$_base/poojas'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));

      final respBody = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && respBody['success'] == true) {
        final created =
            AdminPooja.fromJson(respBody['data'] as Map<String, dynamic>);
        final current = dataNotifier.value;
        dataNotifier.value = AdminData(
          users: current.users,
          orders: current.orders,
          poojas: [...current.poojas, created],
          lastUpdated: DateTime.now(),
        );
        return null;
      }
      return respBody['message'] as String? ?? 'Create failed';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  /// Cancel a booking and patch local state immediately.
  static Future<String?> cancelBooking(String orderId) async {
    try {
      final res = await http
          .patch(Uri.parse('$_base/bookings/$orderId/cancel'))
          .timeout(const Duration(seconds: 8));

      final respBody = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && respBody['success'] == true) {
        final updated =
            AdminOrder.fromJson(respBody['data'] as Map<String, dynamic>);
        final current = dataNotifier.value;
        dataNotifier.value = AdminData(
          users: current.users,
          orders: current.orders
              .map((o) => o.orderId == orderId ? updated : o)
              .toList(),
          poojas: current.poojas,
          lastUpdated: DateTime.now(),
        );
        return null;
      }
      return respBody['message'] as String? ?? 'Cancel failed';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  /// Reschedule a booking and patch local state immediately.
  static Future<String?> rescheduleBooking(
      String orderId, DateTime newDate) async {
    try {
      final dateStr =
          '${newDate.year.toString().padLeft(4, '0')}-'
          '${newDate.month.toString().padLeft(2, '0')}-'
          '${newDate.day.toString().padLeft(2, '0')}';
      final res = await http
          .patch(
            Uri.parse('$_base/bookings/$orderId/reschedule'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'poojaDate': dateStr}),
          )
          .timeout(const Duration(seconds: 8));
      final respBody = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && respBody['success'] == true) {
        final updated =
            AdminOrder.fromJson(respBody['data'] as Map<String, dynamic>);
        final current = dataNotifier.value;
        dataNotifier.value = AdminData(
          users: current.users,
          orders: current.orders
              .map((o) => o.orderId == orderId ? updated : o)
              .toList(),
          poojas: current.poojas,
          lastUpdated: DateTime.now(),
        );
        return null;
      }
      return respBody['message'] as String? ?? 'Reschedule failed';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  static Future<AccommodationSettings?> fetchAccommodation() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/accommodation'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return AccommodationSettings.fromJson(
            body['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> updateAccommodation({
    required int totalRooms,
    required int personsPerRoom,
    required int pricePerRoom,
    required int pricePerPerson,
  }) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_base/accommodation'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'totalRooms': totalRooms,
              'personsPerRoom': personsPerRoom,
              'pricePerRoom': pricePerRoom,
              'pricePerPerson': pricePerPerson,
            }),
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return null;
      return body['message'] as String? ?? 'Update failed';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  // ── Rooms ────────────────────────────────────────────────────────────────────

  static Future<({List<AdminRoom> data, String? error})> getRooms() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/rooms'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['data'] as List? ?? [])
            .map((e) => AdminRoom.fromJson(e as Map<String, dynamic>))
            .toList();
        return (data: list, error: null);
      }
      return (data: <AdminRoom>[], error: 'Server error (${res.statusCode})');
    } catch (_) {
      return (data: <AdminRoom>[], error: 'Could not reach server');
    }
  }

  static Future<String?> createRoom({
    required String name,
    required String type,
    required int pricePerNight,
    required String capacity,
    required List<String> amenities,
    required String description,
    required String imageUrl,
    required bool available,
    required int displayOrder,
    int count = 1,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/rooms'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'type': type,
              'pricePerNight': pricePerNight,
              'capacity': capacity,
              'amenities': amenities,
              'description': description,
              'imageUrl': imageUrl,
              'available': available,
              'displayOrder': displayOrder,
              'count': count,
            }),
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201 && body['success'] == true) return null;
      return body['message'] as String? ?? 'Create failed';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  static Future<String?> updateRoom(
    int id, {
    required String name,
    required String type,
    required int pricePerNight,
    required String capacity,
    required List<String> amenities,
    required String description,
    required String imageUrl,
    required bool available,
    required int displayOrder,
    int count = 1,
  }) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_base/rooms/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'type': type,
              'pricePerNight': pricePerNight,
              'capacity': capacity,
              'amenities': amenities,
              'description': description,
              'imageUrl': imageUrl,
              'available': available,
              'displayOrder': displayOrder,
              'count': count,
            }),
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return null;
      return body['message'] as String? ?? 'Update failed';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  static Future<String?> deleteRoom(int id) async {
    try {
      final res = await http
          .delete(Uri.parse('$_base/rooms/$id'))
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return null;
      return body['message'] as String? ?? 'Delete failed';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  static Future<String?> toggleRoomAvailability(
      int id, bool available) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_base/rooms/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'available': available}),
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return null;
      return body['message'] as String? ?? 'Toggle failed';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  // ── Room walk-in blocks ─────────────────────────────────────────────────────

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Future<({RoomBlockBoard? data, String? error})> getRoomBlocks(
      int roomId, DateTime date) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/rooms/$roomId/blocks?date=${_isoDate(date)}'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return (
          data: RoomBlockBoard.fromJson(body['data'] as Map<String, dynamic>),
          error: null
        );
      }
      return (data: null, error: 'Server error (${res.statusCode})');
    } catch (_) {
      return (data: null, error: 'Could not reach server');
    }
  }

  static Future<String?> createRoomBlock(
    int roomId, {
    required DateTime checkInDate,
    required int numberOfNights,
    required int numberOfRooms,
    String? guestName,
    String? notes,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/rooms/$roomId/blocks'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'checkInDate': _isoDate(checkInDate),
              'numberOfNights': numberOfNights,
              'numberOfRooms': numberOfRooms,
              if (guestName != null && guestName.isNotEmpty) 'guestName': guestName,
              if (notes != null && notes.isNotEmpty) 'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201 && body['success'] == true) return null;
      return body['message'] as String? ?? 'Failed to block room';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  static Future<String?> releaseRoomBlock(int blockId) async {
    try {
      final res = await http
          .patch(Uri.parse('$_base/rooms/blocks/$blockId/release'))
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return null;
      return body['message'] as String? ?? 'Failed to release block';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  /// Update a pooja and patch local state immediately.
  static Future<String?> updatePooja(
    int id, {
    String? name,
    String? description,
    int? pricePerPerson,
    String? colorHex,
    bool? enabled,
    String? iconName,
    String? duration,
    int? displayOrder,
    String? info,
    List<String>? beforeInstructions,
    List<String>? afterInstructions,
    List<String>? thingsToBring,
    List<DateTime>? muhurtaDates,
    int? stayRatePerNight,
    bool? privatePooja,
    int? privatePoojaRate,
    int? gurujiDefaultRate,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (pricePerPerson != null) body['pricePerPerson'] = pricePerPerson;
      if (colorHex != null) body['colorHex'] = colorHex;
      if (enabled != null) body['enabled'] = enabled;
      if (iconName != null) body['iconName'] = iconName;
      if (duration != null) body['duration'] = duration;
      if (displayOrder != null) body['displayOrder'] = displayOrder;
      if (info != null) body['info'] = info;
      if (stayRatePerNight != null) body['stayRatePerNight'] = stayRatePerNight;
      if (privatePooja != null) body['privatePooja'] = privatePooja;
      if (privatePoojaRate != null) body['privatePoojaRate'] = privatePoojaRate;
      if (gurujiDefaultRate != null) body['gurujiDefaultRate'] = gurujiDefaultRate;
      if (beforeInstructions != null) body['beforeInstructions'] = beforeInstructions;
      if (afterInstructions != null) body['afterInstructions'] = afterInstructions;
      if (thingsToBring != null) body['thingsToBring'] = thingsToBring;
      if (muhurtaDates != null) {
        body['muhurtaDates'] = muhurtaDates.map((d) =>
            '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}').toList();
      }

      final res = await http
          .put(
            Uri.parse('$_base/poojas/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));

      final respBody = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && respBody['success'] == true) {
        final updated =
            AdminPooja.fromJson(respBody['data'] as Map<String, dynamic>);
        final current = dataNotifier.value;
        dataNotifier.value = AdminData(
          users: current.users,
          orders: current.orders,
          poojas: current.poojas
              .map((p) => p.id == id ? updated : p)
              .toList(),
          lastUpdated: DateTime.now(),
        );
        return null;
      }
      return respBody['message'] as String? ?? 'Update failed';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  // ── Guruji directory (roster + per-guruji pooja rates) ──────────────────────

  static Future<({List<GurujiDirectoryEntry> data, String? error})> getGurujiDirectory() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/guruji-directory'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['data'] as List? ?? [])
            .map((e) => GurujiDirectoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        return (data: list, error: null);
      }
      return (data: <GurujiDirectoryEntry>[], error: 'Server error (${res.statusCode})');
    } catch (_) {
      return (data: <GurujiDirectoryEntry>[], error: 'Could not reach server');
    }
  }

  static Future<String?> createGurujiDirectoryEntry({
    required String name,
    required String phone,
    String? email,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/guruji-directory'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'phone': phone,
              if (email != null) 'email': email,
            }),
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201 && body['success'] == true) return null;
      return body['message'] as String? ?? 'Create failed';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  static Future<String?> updateGurujiDirectoryEntry(
    int id, {
    required String name,
    required String phone,
    String? email,
  }) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_base/guruji-directory/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'phone': phone,
              if (email != null) 'email': email,
            }),
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return null;
      return body['message'] as String? ?? 'Update failed';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  static Future<String?> deleteGurujiDirectoryEntry(int id) async {
    try {
      final res = await http
          .delete(Uri.parse('$_base/guruji-directory/$id'))
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return null;
      return body['message'] as String? ?? 'Delete failed';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  static Future<({List<GurujiPoojaRate> data, String? error})> getGurujiPoojaRates(int gurujiId) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/guruji-directory/$gurujiId/pooja-rates'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['data'] as List? ?? [])
            .map((e) => GurujiPoojaRate.fromJson(e as Map<String, dynamic>))
            .toList();
        return (data: list, error: null);
      }
      return (data: <GurujiPoojaRate>[], error: 'Server error (${res.statusCode})');
    } catch (_) {
      return (data: <GurujiPoojaRate>[], error: 'Could not reach server');
    }
  }

  static Future<String?> setGurujiPoojaRate(int gurujiId, int poojaId, int rate) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_base/guruji-directory/$gurujiId/pooja-rates/$poojaId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'rate': rate}),
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return null;
      return body['message'] as String? ?? 'Failed to set rate';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  static Future<String?> clearGurujiPoojaRate(int gurujiId, int poojaId) async {
    try {
      final res = await http
          .put(
            Uri.parse('$_base/guruji-directory/$gurujiId/pooja-rates/$poojaId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'clearToDefault': true}),
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return null;
      return body['message'] as String? ?? 'Failed to reset rate';
    } catch (_) {
      return 'Could not reach server';
    }
  }

  // ── Guruji Pooja Assignment ledger ──────────────────────────────────────────

  static Future<({List<GurujiPoojaEntry> data, String? error})> getGurujiPoojaEntries(int gurujiId) async {
    try {
      final res = await http
          .get(Uri.parse('$_base/guruji-directory/$gurujiId/entries'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (body['data'] as List? ?? [])
            .map((e) => GurujiPoojaEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        return (data: list, error: null);
      }
      return (data: <GurujiPoojaEntry>[], error: 'Server error (${res.statusCode})');
    } catch (_) {
      return (data: <GurujiPoojaEntry>[], error: 'Could not reach server');
    }
  }

  static Future<({GurujiPoojaEntry? data, String? error})> createGurujiPoojaEntry(
    int gurujiId, {
    required int poojaId,
    required DateTime entryDate,
    required int count,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/guruji-directory/$gurujiId/entries'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'poojaId': poojaId,
              'entryDate': _isoDate(entryDate),
              'count': count,
            }),
          )
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201 && body['success'] == true) {
        return (data: GurujiPoojaEntry.fromJson(body['data'] as Map<String, dynamic>), error: null);
      }
      return (data: null, error: body['message'] as String? ?? 'Failed to record entry');
    } catch (_) {
      return (data: null, error: 'Could not reach server');
    }
  }

  static Future<String?> deleteGurujiPoojaEntry(int gurujiId, int entryId) async {
    try {
      final res = await http
          .delete(Uri.parse('$_base/guruji-directory/$gurujiId/entries/$entryId'))
          .timeout(const Duration(seconds: 8));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) return null;
      return body['message'] as String? ?? 'Failed to delete entry';
    } catch (_) {
      return 'Could not reach server';
    }
  }
}
