import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/api_service.dart';

/// Source de vérité de la session. Persiste le token JWT et l'utilisateur
/// dans SharedPreferences (équivalent du localStorage du web).
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._api) {
    _api.tokenProvider = () => _token;
  }

  static const _tokenKey = 'lp_token';
  static const _userKey = 'lp_user';

  final ApiService _api;

  String? _token;
  AppUser? _user;
  bool _initialized = false;

  String? get token => _token;
  AppUser? get user => _user;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;
  bool get isInitialized => _initialized;
  bool get canScan => _user?.canScan ?? false;

  /// Charge la session au démarrage.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final rawUser = prefs.getString(_userKey);
    if (rawUser != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
      } catch (_) {}
    }
    // Rafraîchit le profil si un token existe (vérifie sa validité).
    if (isLoggedIn) {
      try {
        final me = await _api.me();
        _user = AppUser.fromJson(me);
        await _persist();
      } on ApiException catch (e) {
        if (e.statusCode == 401) await logout();
      } catch (_) {
        // Hors-ligne : on garde la session en cache.
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(_tokenKey, _token!);
    } else {
      await prefs.remove(_tokenKey);
    }
    if (_user != null) {
      await prefs.setString(_userKey, jsonEncode(_user!.toJson()));
    } else {
      await prefs.remove(_userKey);
    }
  }

  void _setSession(Map<String, dynamic> data) {
    _token = data['access_token'] as String?;
    _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> login({required String email, required String password}) async {
    final data = await _api.login(email: email, password: password);
    _setSession(data);
    await _persist();
    notifyListeners();
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required String social,
  }) async {
    final data = await _api.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      social: social,
    );
    _setSession(data);
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _persist();
    notifyListeners();
  }
}
