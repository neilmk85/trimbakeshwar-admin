import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/admin_models.dart';

class AdminDataService {
  AdminDataService._();

  static const _base = 'http://localhost:8080/api';

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
          'Could not reach server at $_base.\nMake sure the Spring Boot server is running.';
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

  static Future<AdminData> _fetchData() async {
    final responses = await Future.wait([
      http.get(Uri.parse('$_base/users')).timeout(const Duration(seconds: 8)),
      http.get(Uri.parse('$_base/bookings')).timeout(const Duration(seconds: 8)),
      http.get(Uri.parse('$_base/poojas/all')).timeout(const Duration(seconds: 8)),
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
      if (beforeInstructions != null) body['beforeInstructions'] = beforeInstructions;
      if (afterInstructions != null) body['afterInstructions'] = afterInstructions;
      if (thingsToBring != null) body['thingsToBring'] = thingsToBring;

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
}
