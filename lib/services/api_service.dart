import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/event.dart';
import '../models/formula.dart';
import '../models/reservation.dart';
import '../models/scan_result.dart';
import '../models/app_notification.dart';

/// Exception métier : message déjà en français, prêt à afficher.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

/// Client de l'API Liste Party. Le token JWT est injecté via [tokenProvider].
class ApiService {
  ApiService({String? Function()? tokenProvider})
      : _tokenProvider = tokenProvider;

  final String _base = Config.apiBase;
  String? Function()? _tokenProvider;

  set tokenProvider(String? Function()? p) => _tokenProvider = p;

  Map<String, String> _headers({bool json = true}) {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    final token = _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('$_base$path').replace(queryParameters: q);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode == 204) return null;
    dynamic data;
    final ct = res.headers['content-type'] ?? '';
    if (ct.contains('application/json') && res.body.isNotEmpty) {
      data = jsonDecode(utf8.decode(res.bodyBytes));
    } else {
      data = res.body;
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    String msg;
    if (data is Map && data['detail'] != null) {
      final d = data['detail'];
      msg = d is String ? d : d.toString();
    } else {
      msg = data is String && data.isNotEmpty
          ? data
          : 'Erreur ${res.statusCode}';
    }
    throw ApiException(msg, statusCode: res.statusCode);
  }

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) async {
    final res = await http.get(_uri(path, query), headers: _headers(json: false));
    return _decode(res);
  }

  Future<dynamic> _post(String path, [Object? body]) async {
    final res = await http.post(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> _delete(String path) async {
    final res = await http.delete(_uri(path), headers: _headers());
    return _decode(res);
  }

  // ─── AUTH ────────────────────────────────────────────────
  /// Retourne le map brut { access_token, token_type, user }.
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required String social,
  }) async {
    final data = await _post('/auth/register', {
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'social': social,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> me() async {
    final data = await _get('/auth/me');
    return Map<String, dynamic>.from(data as Map);
  }

  /// Supprime définitivement le compte de l'utilisateur connecté
  /// (exigence Apple App Store 5.1.1(v) — account deletion).
  Future<void> deleteAccount() async {
    await _delete('/auth/me');
  }

  // ─── EVENTS ──────────────────────────────────────────────
  Future<List<PartyEvent>> upcomingEvents() async {
    final data = await _get('/events', {'upcoming_only': 'true'});
    return (data as List)
        .map((e) => PartyEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PartyEvent>> pastEvents() async {
    final data = await _get('/events/past');
    return (data as List)
        .map((e) => PartyEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PartyEvent> event(int id) async {
    final data = await _get('/events/$id');
    return PartyEvent.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ─── FORMULAS ────────────────────────────────────────────
  Future<List<Formula>> formulas() async {
    final data = await _get('/formulas');
    return (data as List)
        .map((e) => Formula.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<int, FormulaAvailability>> formulaAvailability(int eventId) async {
    final data = await _get('/events/$eventId/formula-availability');
    final map = <int, FormulaAvailability>{};
    (data as Map).forEach((k, v) {
      map[int.parse('$k')] =
          FormulaAvailability.fromJson(Map<String, dynamic>.from(v as Map));
    });
    return map;
  }

  // ─── RESERVATIONS ────────────────────────────────────────
  /// Crée une session Stripe Checkout. Retourne l'URL à ouvrir en WebView.
  Future<String> createCheckout({
    required int eventId,
    required int formulaId,
  }) async {
    final data = await _post('/reservations/checkout', {
      'event_id': eventId,
      'formula_id': formulaId,
      'quantity': 1,
    });
    return (data as Map)['checkout_url'] as String;
  }

  /// Réservation gratuite (formule filles). Pas de Stripe.
  Future<Reservation> createFreeReservation({
    required int eventId,
    required int formulaId,
  }) async {
    final data = await _post('/reservations/free', {
      'event_id': eventId,
      'formula_id': formulaId,
      'quantity': 1,
    });
    return Reservation.fromJson(Map<String, dynamic>.from(data as Map));
  }

  /// Confirme une résa après retour du paiement Stripe.
  Future<Reservation> confirmBySession(String sessionId) async {
    final data = await _get('/reservations/confirm', {'session_id': sessionId});
    return Reservation.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<Reservation>> myReservations() async {
    final data = await _get('/reservations/me');
    return (data as List)
        .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QrTicket> reservationQr(int reservationId) async {
    final data = await _get('/reservations/$reservationId/qr');
    return QrTicket.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ─── INVITATIONS / GUESTS ────────────────────────────────
  Future<Map<String, dynamic>> inviteInfo(String inviteToken) async {
    final data = await _get('/invitations/$inviteToken');
    return Map<String, dynamic>.from(data as Map);
  }

  Future<GuestReservation> joinAsGuest(String inviteToken) async {
    final data = await _post('/invitations/$inviteToken/join');
    return GuestReservation.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<List<GuestReservation>> myGuestReservations() async {
    final data = await _get('/guests/me');
    return (data as List)
        .map((e) => GuestReservation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QrTicket> guestQr(int guestId) async {
    final data = await _get('/invitations/guest/$guestId/qr');
    return QrTicket.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ─── SCANNER ─────────────────────────────────────────────
  Future<ScanResult> scan(String qrToken) async {
    final data = await _get('/scan/$qrToken');
    return ScanResult.fromJson(Map<String, dynamic>.from(data as Map));
  }

  // ─── NOTIFICATIONS ───────────────────────────────────────
  /// Nécessite l'ajout des endpoints côté backend (voir backend_patch/).
  Future<List<AppNotification>> notifications() async {
    final data = await _get('/notifications');
    return (data as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  
}