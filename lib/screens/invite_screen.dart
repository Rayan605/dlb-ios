import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/format.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'login_screen.dart';

/// Rejoindre une réservation en tant qu'invité. On accepte soit le token brut,
/// soit un lien complet (…/invite.html?token=XXXX).
class InviteScreen extends StatefulWidget {
  final String? initialToken;
  const InviteScreen({super.key, this.initialToken});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final _input = TextEditingController();
  Map<String, dynamic>? _info;
  bool _loading = false;
  bool _joining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      _input.text = widget.initialToken!;
      _lookup();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String _extractToken(String raw) {
    final v = raw.trim();
    final uri = Uri.tryParse(v);
    if (uri != null && uri.queryParameters['token'] != null) {
      return uri.queryParameters['token']!;
    }
    return v;
  }

  Future<void> _lookup() async {
    final token = _extractToken(_input.text);
    if (token.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final info = await context.read<ApiService>().inviteInfo(token);
      if (!mounted) return;
      setState(() => _info = info);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      final ok = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => const LoginScreen()));
      if (ok != true) return;
    }
    final token = _extractToken(_input.text);
    setState(() => _joining = true);
    try {
      await context.read<ApiService>().joinAsGuest(token);
      if (!mounted) return;
      showSnack(context, 'Tu es dans la liste ! Ton QR invité est prêt.');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    } catch (e) {
      if (mounted) showSnack(context, 'Erreur : $e', error: true);
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('INVITATION')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("QUELQU'UN\nT'A INVITÉ ?", style: AppTheme.heading(size: 32)),
              const SizedBox(height: 8),
              const Text(
                'Colle le lien ou le code d\'invitation reçu pour rejoindre sa réservation.',
                style: TextStyle(color: AppColors.sub, height: 1.5),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _input,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Lien ou code',
                  hintText: 'https://…/invite.html?token=…',
                ),
                onSubmitted: (_) => _lookup(),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loading ? null : _lookup,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accent))
                    : const Text('Vérifier l\'invitation'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 18),
                Text(_error!,
                    style: const TextStyle(color: AppColors.danger)),
              ],
              if (_info != null) _infoCard(_info!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(Map<String, dynamic> info) {
    final spotsLeft = info['spots_left'] as int? ?? 0;
    final full = spotsLeft <= 0;
    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.accent2.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(kRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('INVITATION VALIDE',
              style: AppTheme.mono(color: AppColors.lime, size: 11)),
          const SizedBox(height: 10),
          Text('${info['event_title'] ?? ''}'.toUpperCase(),
              style: AppTheme.heading(size: 24)),
          const SizedBox(height: 4),
          Text(Fmt.date(info['event_date'] as String?),
              style: const TextStyle(color: AppColors.sub, fontSize: 13)),
          const SizedBox(height: 12),
          _row('Hôte', '${info['host_name'] ?? ''}'),
          _row('Formule', '${info['formula_name'] ?? ''}'),
          _row('Places invités',
              full ? 'Complet' : '$spotsLeft restante${spotsLeft > 1 ? 's' : ''}'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (full || _joining) ? null : _join,
              child: _joining
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : Text(full ? 'Complet' : 'Rejoindre la soirée →'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 110,
                child: Text(label.toUpperCase(),
                    style: AppTheme.mono(size: 10))),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.bright, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );
}
