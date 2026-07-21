import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/reservation.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/qr_dialog.dart';
import 'invite_screen.dart';
import 'login_screen.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  Future<_ResaBundle>? _future;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return _LoggedOutView(onLogged: () => setState(() => _future = _load()));
    }
    _future ??= _load();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MA LISTE'),
        actions: [
          IconButton(
            tooltip: 'Rejoindre une invitation',
            icon: const Icon(Icons.link),
            onPressed: _openJoinDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          setState(() => _future = _load());
          await _future;
        },
        child: FutureBuilder<_ResaBundle>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LpLoader();
            }
            if (snap.hasError) {
              return ListView(children: [
                const SizedBox(height: 60),
                ErrorView(
                    message: '${snap.error}',
                    onRetry: () => setState(() => _future = _load())),
              ]);
            }
            final b = snap.data!;
            if (b.reservations.isEmpty && b.guests.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 80),
                EmptyState(
                  icon: Icons.confirmation_number_outlined,
                  message:
                      'Aucune réservation pour le moment.\nFonce sur les soirées.',
                ),
              ]);
            }
            return _list(b);
          },
        ),
      ),
    );
  }

  Future<_ResaBundle> _load() async {
    final api = context.read<ApiService>();
    final resaF = api.myReservations();
    final guestF = api.myGuestReservations();
    return _ResaBundle(
      reservations: await resaF,
      guests: await guestF,
    );
  }

  Widget _list(_ResaBundle b) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (b.reservations.isNotEmpty) ...[
          Text('MES RÉSERVATIONS', style: AppTheme.heading(size: 20)),
          const SizedBox(height: 14),
          ...b.reservations.map(_reservationCard),
        ],
        if (b.guests.isNotEmpty) ...[
          const SizedBox(height: 26),
          RichText(
            text: TextSpan(
              style: AppTheme.heading(size: 20),
              children: [
                const TextSpan(text: 'MES '),
                TextSpan(
                    text: 'INVITATIONS',
                    style: AppTheme.heading(size: 20, color: AppColors.lime)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...b.guests.map(_guestCard),
        ],
      ],
    );
  }

  Widget _reservationCard(Reservation r) {
    final statusLabel = r.isPaid
        ? 'CONFIRMÉ'
        : r.isPending
            ? 'EN ATTENTE'
            : 'ANNULÉ';
    final statusColor = r.isPaid
        ? AppColors.lime
        : r.isPending
            ? AppColors.accent
            : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Fmt.date(r.eventDate), style: AppTheme.mono(size: 10.5)),
                    const SizedBox(height: 5),
                    Text(r.eventTitle?.toUpperCase() ?? '',
                        style: AppTheme.heading(size: 20)),
                    const SizedBox(height: 4),
                    Text('✦ ${r.formulaName ?? ''}',
                        style: const TextStyle(
                            color: AppColors.accent, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: statusColor),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ),
                  if (r.amountPaidCents != null) ...[
                    const SizedBox(height: 8),
                    Text(Fmt.price(r.amountPaidCents),
                        style: AppTheme.heading(size: 18)),
                  ],
                ],
              ),
            ],
          ),
          if (r.isPaid) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.qr_code_2, size: 20),
                label: const Text('Mon QR code'),
                onPressed: () => _showResaQr(r.id),
              ),
            ),
            if (r.hasInvite) _inviteBanner(r),
          ],
        ],
      ),
    );
  }

  Widget _inviteBanner(Reservation r) {
    // Le lien pointe vers le front web ; il ouvre invite.html côté navigateur,
    // et dans l'app il peut être collé dans « Rejoindre une invitation ».
    final link = '${_frontendBase()}/invite.html?token=${r.inviteToken}';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.raised,
        border: Border.all(color: AppColors.accent2.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('✦ TU PEUX INVITER DU MONDE',
              style: AppTheme.heading(size: 15, color: AppColors.accent)),
          const SizedBox(height: 4),
          Text(
            'Ta formule inclut ${r.formulaMaxGuests} invité${(r.formulaMaxGuests ?? 0) > 1 ? 's' : ''}. Partage ce lien.',
            style: const TextStyle(color: AppColors.sub, fontSize: 12.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(link,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.text, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                  showSnack(context, 'Lien copié ✓');
                },
                child: const Text('COPIER'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _guestCard(GuestReservation g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Fmt.date(g.eventDate), style: AppTheme.mono(size: 10.5)),
          const SizedBox(height: 5),
          Text(g.eventTitle?.toUpperCase() ?? '',
              style: AppTheme.heading(size: 20)),
          const SizedBox(height: 4),
          Text('Invité(e) par ${g.hostName}',
              style: const TextStyle(color: AppColors.lime, fontSize: 13)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.qr_code_2, size: 20),
              label: const Text('Mon QR invité'),
              onPressed: () => _showGuestQr(g.id),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showResaQr(int id) async {
    final api = context.read<ApiService>();
    try {
      final ticket = await api.reservationQr(id);
      if (!mounted) return;
      await QrTicketSheet.show(context, ticket);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _showGuestQr(int guestId) async {
    final api = context.read<ApiService>();
    try {
      final ticket = await api.guestQr(guestId);
      if (!mounted) return;
      await QrTicketSheet.show(context, ticket, isGuest: true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
  }

  Future<void> _openJoinDialog() async {
    final joined = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const InviteScreen()),
    );
    if (joined == true && mounted) {
      setState(() => _future = _load());
    }
  }

  String _frontendBase() => Config.frontendUrl;
}

class _ResaBundle {
  final List<Reservation> reservations;
  final List<GuestReservation> guests;
  _ResaBundle({required this.reservations, required this.guests});
}

class _LoggedOutView extends StatelessWidget {
  final VoidCallback onLogged;
  const _LoggedOutView({required this.onLogged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MA LISTE')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 44, color: AppColors.muted),
              const SizedBox(height: 16),
              Text('CONNECTE-TOI',
                  style: AppTheme.heading(size: 24)),
              const SizedBox(height: 8),
              const Text(
                'Tes réservations, tes QR codes et tes invitations sont ici.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.sub, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final ok = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                    if (ok == true) onLogged();
                  },
                  child: const Text('Se connecter →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
