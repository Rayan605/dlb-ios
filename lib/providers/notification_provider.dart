import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/app_notification.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

/// Récupère le feed de notifications depuis l'API et déclenche une notification
/// système locale à chaque nouvelle annonce (tant que l'app tourne).
///
/// Le "lu/non-lu" est géré localement : on retient l'id max déjà vu.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider(this._api);

  static const _lastSeenKey = 'lp_notif_last_seen';
  static const _lastPushedKey = 'lp_notif_last_pushed';

  final ApiService _api;

  List<AppNotification> _items = const [];
  int _lastSeenId = 0; // pour le badge non-lu
  int _lastPushedId = 0; // pour ne pas re-notifier deux fois
  bool _loading = false;
  Timer? _timer;

  List<AppNotification> get items => _items;
  bool get loading => _loading;

  int get unreadCount =>
      _items.where((n) => n.id > _lastSeenId).length;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _lastSeenId = prefs.getInt(_lastSeenKey) ?? 0;
    _lastPushedId = prefs.getInt(_lastPushedKey) ?? 0;
    await refresh(pushNew: false);
    startPolling();
  }

  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(
      Config.notificationsPollInterval,
      (_) => refresh(pushNew: true),
    );
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh({bool pushNew = true}) async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _api.notifications();
      list.sort((a, b) => b.id.compareTo(a.id)); // plus récent d'abord

      // Notifie les nouvelles annonces jamais poussées.
      if (pushNew && _lastPushedId > 0) {
        final fresh = list.where((n) => n.id > _lastPushedId).toList()
          ..sort((a, b) => a.id.compareTo(b.id));
        for (final n in fresh) {
          await LocalNotifications.instance.show(
            id: n.id,
            title: n.title.isEmpty ? Config.siteName : n.title,
            body: n.body,
          );
        }
      }

      if (list.isNotEmpty) {
        final maxId = list.first.id;
        if (maxId > _lastPushedId) {
          _lastPushedId = maxId;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_lastPushedKey, _lastPushedId);
        }
      }
      _items = list;
    } catch (_) {
      // Silencieux : le feed peut être indisponible sans casser l'app.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Appelé quand l'utilisateur ouvre l'onglet notifications.
  Future<void> markAllSeen() async {
    if (_items.isEmpty) return;
    final maxId = _items.first.id;
    if (maxId > _lastSeenId) {
      _lastSeenId = maxId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastSeenKey, _lastSeenId);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
