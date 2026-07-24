import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event.dart';
import '../models/formula.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/formula_card.dart';
import 'checkout_webview_screen.dart';
import 'login_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<_EventBundle> _future;
  int _galleryIndex = 0;
  int? _selectedFormulaId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_EventBundle> _load() async {
    final api = context.read<ApiService>();
    final eventF = api.event(widget.eventId);
    final formulasF = api.formulas();
    final availF = api.formulaAvailability(widget.eventId);
    return _EventBundle(
      event: await eventF,
      formulas: await formulasF,
      availability: await availF,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOIRÉE')),
      body: FutureBuilder<_EventBundle>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LpLoader();
          }
          if (snap.hasError) {
            return ErrorView(message: '${snap.error}', onRetry: _refresh);
          }
          return _content(snap.data!);
        },
      ),
    );
  }

  Widget _content(_EventBundle b) {
    final ev = b.event;
    final user = context.watch<AuthProvider>().user;

    // Filtre : les formules filles ne s'affichent que pour les comptes 'F'.
    final formulas = b.formulas.where((f) {
      if (f.isGirlsOnly) return user?.gender == 'F';
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _gallery(ev),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${ev.department} · ${ev.city}',
                  style: AppTheme.mono(color: AppColors.accent, size: 11)),
              const SizedBox(height: 8),
              Text(ev.title.toUpperCase(), style: AppTheme.heading(size: 34)),
              if (ev.description != null && ev.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(ev.description!,
                    style: const TextStyle(
                        color: AppColors.text, height: 1.6, fontSize: 14.5)),
              ],
              const SizedBox(height: 18),
              _metaStrip(ev),
              const SizedBox(height: 28),
              SectionTitle(
                  eyebrow: 'Une place, une formule',
                  title: 'Choisis ta',
                  highlight: 'formule'),
              const SizedBox(height: 16),
              ...formulas.map((f) {
                final avail = b.availability[f.id];
                final isFull = avail?.isFull ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FormulaCard(
                    formula: f,
                    availability: avail,
                    selected: _selectedFormulaId == f.id,
                    disabled: isFull,
                    onTap: () => setState(() => _selectedFormulaId = f.id),
                  ),
                );
              }),
              const SizedBox(height: 8),
              _reserveButton(ev, formulas),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  '1 place par personne · Paiement sécurisé Stripe · CB acceptées',
                  textAlign: TextAlign.center,
                  style: AppTheme.mono(size: 10, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gallery(PartyEvent ev) {
    if (ev.images.isEmpty) {
      return AspectRatio(
        aspectRatio: 8 / 10,
        child: Container(
          color: AppColors.raised,
          alignment: Alignment.center,
          child: Text('Liste Party',
              style: AppTheme.heading(size: 30, color: AppColors.muted)),
        ),
      );
    }
    final main = ev.images[_galleryIndex.clamp(0, ev.images.length - 1)];
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 8 / 10,
          child: CachedNetworkImage(imageUrl: main.url, fit: BoxFit.cover),
        ),
        if (ev.images.length > 1)
          SizedBox(
            height: 70,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(10),
              itemCount: ev.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final active = i == _galleryIndex;
                return GestureDetector(
                  onTap: () => setState(() => _galleryIndex = i),
                  child: Container(
                    width: 68,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: active ? AppColors.accent : AppColors.border,
                        width: active ? 1.6 : 1,
                      ),
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                        imageUrl: ev.images[i].url, fit: BoxFit.cover),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _metaStrip(PartyEvent ev) {
    Widget item(String label, String value, {Color? valueColor}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: AppTheme.mono(size: 9.5)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      color: valueColor ?? AppColors.bright,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
        );
    final placesLabel = ev.isFull
        ? 'COMPLET'
        : ev.isUrgent
            ? '🔥 ${ev.seatsLeft}'
            : '${ev.seatsLeft} / ${ev.maxPeople}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Row(
        children: [
          item('Date', Fmt.dateShort(ev.date)),
          item('Heure', Fmt.time(ev.date)),
          item('Lieu', ev.city),
          item('Places', placesLabel,
              valueColor: ev.isFull ? AppColors.danger : null),
        ],
      ),
    );
  }

  Widget _reserveButton(PartyEvent ev, List<Formula> formulas) {
    if (ev.reservationsClosed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.raised,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Text('🔒 Réservations fermées pour cette soirée.',
            textAlign: TextAlign.center,
            style: AppTheme.heading(size: 16, color: AppColors.sub)),
      );
    }
    final disabled = ev.isFull || _submitting;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: disabled ? null : () => _reserve(ev, formulas),
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black),
              )
            : Text(ev.isFull ? 'Soirée complète' : 'Réserver et payer →'),
      ),
    );
  }

  Future<void> _reserve(PartyEvent ev, List<Formula> formulas) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (ok != true) return;
    }
    if (_selectedFormulaId == null) {
      showSnack(context, 'Choisis une formule avant de continuer.', error: true);
      return;
    }
    final formula = formulas.firstWhere((f) => f.id == _selectedFormulaId);
    final api = context.read<ApiService>();
    setState(() => _submitting = true);

    try {
      // Formule gratuite (filles) → pas de Stripe.
      if (formula.isGirlsOnly && auth.user?.gender == 'F') {
        await api.createFreeReservation(
          eventId: ev.id,
          formulaId: formula.id,
        );
        if (!mounted) return;
        showSnack(context, 'Réservation confirmée ! Retrouve ton QR dans « Ma liste ».');
        Navigator.of(context).pop();
        return;
      }

      // Paiement Stripe via Checkout dans une WebView.
      final url = await api.createCheckout(
        eventId: ev.id,
        formulaId: formula.id,
      );
      if (!mounted) return;
      final result = await Navigator.of(context).push<CheckoutResult>(
        MaterialPageRoute(
          builder: (_) => CheckoutWebViewScreen(checkoutUrl: url),
        ),
      );
      if (!mounted) return;

      if (result?.status == CheckoutStatus.success) {
        // Confirme côté backend (au cas où le webhook n'a pas encore tourné).
        if (result!.sessionId != null) {
          try {
            await api.confirmBySession(result.sessionId!);
          } catch (_) {}
        }
        if (!mounted) return;
        showSnack(context, 'Paiement réussi ! Ton QR est dans « Ma liste ».');
        Navigator.of(context).pop();
      } else if (result?.status == CheckoutStatus.cancelled) {
        showSnack(context, 'Paiement annulé. Aucun débit effectué.');
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur : $e', error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _EventBundle {
  final PartyEvent event;
  final List<Formula> formulas;
  final Map<int, FormulaAvailability> availability;
  _EventBundle({
    required this.event,
    required this.formulas,
    required this.availability,
  });
}