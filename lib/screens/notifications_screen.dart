import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_notification.dart';
import '../providers/notification_provider.dart';
import '../services/format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'event_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().markAllSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('NOTIFICATIONS')),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () => provider.refresh(pushNew: false),
        child: provider.items.isEmpty
            ? ListView(children: [
                const SizedBox(height: 80),
                EmptyState(
                  icon: Icons.notifications_none,
                  message: provider.loading
                      ? 'Chargement…'
                      : 'Aucune notification pour l\'instant.\nTu seras prévenu dès qu\'une soirée est annoncée.',
                ),
              ])
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _tile(provider.items[i]),
              ),
      ),
    );
  }

  Widget _tile(AppNotification n) {
    return InkWell(
      borderRadius: BorderRadius.circular(kRadius),
      onTap: n.eventId != null
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventDetailScreen(eventId: n.eventId!),
                ),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(kRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(kRadius),
              ),
              child: const Icon(Icons.local_fire_department,
                  color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title.toUpperCase(),
                      style: AppTheme.heading(size: 17)),
                  const SizedBox(height: 4),
                  Text(n.body,
                      style: const TextStyle(
                          color: AppColors.text, height: 1.45, fontSize: 13.5)),
                  const SizedBox(height: 8),
                  Text(Fmt.dateTime(n.createdAt),
                      style: AppTheme.mono(size: 10, color: AppColors.muted)),
                ],
              ),
            ),
            if (n.eventId != null)
              const Icon(Icons.chevron_right, color: AppColors.sub),
          ],
        ),
      ),
    );
  }
}
