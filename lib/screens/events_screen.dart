import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/event.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/event_card.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool _past = false;
  late Future<List<PartyEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PartyEvent>> _load() {
    final api = context.read<ApiService>();
    return _past ? api.pastEvents() : api.upcomingEvents();
  }

  void _switch(bool past) {
    if (past == _past) return;
    setState(() {
      _past = past;
      _future = _load();
    });
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.accent,
                backgroundColor: AppColors.surface,
                onRefresh: _refresh,
                child: FutureBuilder<List<PartyEvent>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const LpLoader();
                    }
                    if (snap.hasError) {
                      return ListView(children: [
                        const SizedBox(height: 60),
                        ErrorView(
                            message: '${snap.error}', onRetry: _refresh),
                      ]);
                    }
                    final events = snap.data ?? [];
                    if (events.isEmpty) {
                      return ListView(children: [
                        const SizedBox(height: 80),
                        EmptyState(
                          message: _past
                              ? 'Pas encore de soirée passée à afficher.'
                              : 'Aucune soirée annoncée pour le moment.\nReviens checker, ça bouge vite.',
                        ),
                      ]);
                    }
                    return _grid(events);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                    color: AppColors.accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(Config.siteName.toUpperCase(),
                  style: AppTheme.heading(size: 26)),
              const SizedBox(width: 8),
              Text(Config.siteSlogan,
                  style: AppTheme.mono(color: AppColors.accent, size: 11)),
            ],
          ),
          const SizedBox(height: 14),
          _toggle(),
        ],
      ),
    );
  }

  Widget _toggle() {
    Widget seg(String label, bool past) {
      final active = _past == past;
      return Expanded(
        child: GestureDetector(
          onTap: () => _switch(past),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: active ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(kRadius - 1),
            ),
            alignment: Alignment.center,
            child: Text(
              label.toUpperCase(),
              style: AppTheme.heading(
                size: 15,
                color: active ? Colors.black : AppColors.sub,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Row(children: [seg('À venir', false), seg('Précédentes', true)]),
    );
  }

  Widget _grid(List<PartyEvent> events) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.66,
      ),
      itemCount: events.length,
      itemBuilder: (context, i) {
        final ev = events[i];
        void open() => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => EventDetailScreen(eventId: ev.id)),
            );
        return _past
            ? RecapCard(event: ev, onTap: open)
            : EventCard(event: ev, onTap: open);
      },
    );
  }
}
