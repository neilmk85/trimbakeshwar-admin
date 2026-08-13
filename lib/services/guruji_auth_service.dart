import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GurujiAuthService {
  GurujiAuthService._();

  static const _base = 'https://app.trimbakeshwarpoojavidhi.in/api/guruji/auth';
  static const _keyPhone = 'guruji_phone';
  static const _keyName = 'guruji_name';
  static const _keyEmail = 'guruji_email';

  static final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);
  static String? loggedInName;
  static String? loggedInPhone;
  static String? loggedInEmail;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyPhone);
    if (saved != null && saved.isNotEmpty) {
      loggedInPhone = saved;
      loggedInName = prefs.getString(_keyName);
      loggedInEmail = prefs.getString(_keyEmail);
      isLoggedIn.value = true;
    }
  }

  static Future<void> _saveSession(Map<String, dynamic> data) async {
    loggedInPhone = data['phone'] as String?;
    loggedInName = data['name'] as String?;
    loggedInEmail = data['email'] as String?;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhone, loggedInPhone ?? '');
    await prefs.setString(_keyName, loggedInName ?? '');
    await prefs.setString(_keyEmail, loggedInEmail ?? '');
    isLoggedIn.value = true;
  }

  /// Returns null on success (OTP sent), error message on failure.
  static Future<String?> sendOtp(String phone) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/otp/send'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone}),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        return null; // success
      }
      if (res.statusCode == 403) {
        return body['message'] as String? ?? 'You are not authorized to access this app';
      }
      return body['message'] as String? ?? 'Could not send OTP';
    } catch (_) {
      return 'Could not reach server. Make sure the server is running.';
    }
  }

  static Future<String?> verifyOtp(String phone, String otp) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/otp/verify'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        await _saveSession(body['data'] as Map<String, dynamic>);
        return null;
      }
      return body['message'] as String? ?? 'Invalid OTP';
    } catch (_) {
      return 'Could not reach server. Make sure the server is running.';
    }
  }

  static Future<String?> loginWithEmail(String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        await _saveSession(body['data'] as Map<String, dynamic>);
        return null;
      }
      if (res.statusCode == 404) return 'User not registered';
      return body['message'] as String? ?? 'Invalid email or password';
    } catch (_) {
      return 'Could not reach server. Make sure the server is running.';
    }
  }

  static Future<String?> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_base/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'phone': phone,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && body['success'] == true) {
        await _saveSession(body['data'] as Map<String, dynamic>);
        return null;
      }
      return body['message'] as String? ?? 'Registration failed';
    } catch (_) {
      return 'Could not reach server. Make sure the server is running.';
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    loggedInPhone = null;
    loggedInName = null;
    loggedInEmail = null;
    isLoggedIn.value = false;
  }
}
