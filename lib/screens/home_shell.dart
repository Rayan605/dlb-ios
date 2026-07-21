import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../theme.dart';
import 'events_screen.dart';
import 'my_reservations_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'scanner_screen.dart';

class HomeShell extends StatefulWidget {
  final int initialIndex;
  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Rafraîchit les notifs au retour au premier plan.
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationProvider>().refresh(pushNew: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canScan = context.watch<AuthProvider>().canScan;
    final unread = context.watch<NotificationProvider>().unreadCount;

    final tabs = <_Tab>[
      _Tab(const EventsScreen(), Icons.local_fire_department_outlined,
          Icons.local_fire_department, 'Soirées'),
      _Tab(const MyReservationsScreen(), Icons.confirmation_number_outlined,
          Icons.confirmation_number, 'Ma liste'),
      _Tab(const NotificationsScreen(), Icons.notifications_outlined,
          Icons.notifications, 'Notifs', badge: unread),
      if (canScan)
        _Tab(const ScannerScreen(), Icons.qr_code_scanner_outlined,
            Icons.qr_code_scanner, 'Scanner'),
      _Tab(const ProfileScreen(), Icons.person_outline, Icons.person, 'Profil'),
    ];

    final safeIndex = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: (i) {
            setState(() => _index = i);
            if (tabs[i].label == 'Notifs') {
              context.read<NotificationProvider>().markAllSeen();
            }
          },
          items: [
            for (final t in tabs)
              BottomNavigationBarItem(
                icon: _IconWithBadge(icon: t.icon, badge: t.badge),
                activeIcon: _IconWithBadge(icon: t.activeIcon, badge: t.badge),
                label: t.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab {
  final Widget screen;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
  _Tab(this.screen, this.icon, this.activeIcon, this.label, {this.badge = 0});
}

class _IconWithBadge extends StatelessWidget {
  final IconData icon;
  final int badge;
  const _IconWithBadge({required this.icon, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    if (badge <= 0) return Icon(icon);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              badge > 9 ? '9+' : '$badge',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
