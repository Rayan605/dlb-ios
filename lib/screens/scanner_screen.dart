import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/scan_result.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _locked = false; // pendant le cooldown post-scan
  ScanResult? _last;
  int _cooldown = 0;
  Timer? _cooldownTimer;
  final List<_HistItem> _history = [];

  static const _cooldownSeconds = 3;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Extrait le qr_token du payload « LP|RES|id|TOKEN|… » ou « LP|GUEST|id|TOKEN|… ».
  String? _extractToken(String raw) {
    final parts = raw.split('|');
    if (parts.length >= 4 && parts[0] == 'LP') {
      return parts[3];
    }
    return null;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_locked) return;
    final code = capture.barcodes.isNotEmpty
        ? capture.barcodes.first.rawValue
        : null;
    if (code == null || code.isEmpty) return;

    final token = _extractToken(code);
    setState(() => _locked = true);

    if (token == null) {
      _presentResult(const ScanResult(
        valid: false,
        type: 'unknown',
        message: 'QR non reconnu. Ce n\'est pas un billet Liste Party.',
        holderName: null,
        eventTitle: null,
        eventDate: null,
        formulaName: null,
        alreadyScanned: false,
        scannedAt: null,
        gender: null,
      ));
      return;
    }

    try {
      final result = await context.read<ApiService>().scan(token);
      _presentResult(result);
    } on ApiException catch (e) {
      _presentResult(ScanResult(
        valid: false,
        type: 'unknown',
        message: e.message,
        holderName: null,
        eventTitle: null,
        eventDate: null,
        formulaName: null,
        alreadyScanned: false,
        scannedAt: null,
        gender: null,
      ));
    } catch (e) {
      _presentResult(ScanResult(
        valid: false,
        type: 'unknown',
        message: 'Erreur réseau : $e',
        holderName: null,
        eventTitle: null,
        eventDate: null,
        formulaName: null,
        alreadyScanned: false,
        scannedAt: null,
        gender: null,
      ));
    }
  }

  void _presentResult(ScanResult r) {
    if (!mounted) return;
    setState(() {
      _last = r;
      _history.insert(0, _HistItem(r, TimeOfDay.now()));
      if (_history.length > 25) _history.removeLast();
      _cooldown = _cooldownSeconds;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) {
        t.cancel();
        setState(() {
          _locked = false;
          _last = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final canScan = context.watch<AuthProvider>().canScan;
    if (!canScan) {
      return Scaffold(
        appBar: AppBar(title: const Text('SCANNER')),
        body: const EmptyState(
          icon: Icons.lock_outline,
          message:
              'Accès réservé aux comptes scanner.\nDemande à un admin de t\'activer.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SCANNER'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_outlined),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                _viewfinder(),
                if (_last != null) _resultToast(_last!),
              ],
            ),
          ),
          Expanded(flex: 2, child: _historyPanel()),
        ],
      ),
    );
  }

  Widget _viewfinder() {
    Color color;
    if (_last == null) {
      color = AppColors.accent;
    } else if (_last!.valid) {
      color = _last!.isGirl ? AppColors.pink : AppColors.lime;
    } else if (_last!.alreadyScanned) {
      color = AppColors.accent;
    } else {
      color = AppColors.danger;
    }
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(kRadius + 6),
        ),
      ),
    );
  }

  Widget _resultToast(ScanResult r) {
    Color color;
    String badge;
    IconData icon;
    if (r.valid) {
      if (r.isGirl) {
        color = AppColors.pink;
        badge = '♀ ENTRÉE GRATUITE';
        icon = Icons.check_circle;
      } else {
        color = AppColors.lime;
        badge = '✓ BIENVENUE';
        icon = Icons.check_circle;
      }
    } else if (r.alreadyScanned) {
      color = AppColors.accent;
      badge = '⚠ DÉJÀ SCANNÉ';
      icon = Icons.warning_amber_rounded;
    } else {
      color = AppColors.danger;
      badge = '✕ REFUSÉ';
      icon = Icons.cancel;
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg.withValues(alpha: 0.95),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(kRadius + 2),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(badge,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.5)),
                  ),
                  const SizedBox(height: 6),
                  Text(r.holderName ?? (r.valid ? 'Valide' : 'Refusé'),
                      style: AppTheme.heading(size: 20)),
                  if (r.formulaName != null || r.eventTitle != null)
                    Text(r.formulaName ?? r.eventTitle ?? '',
                        style: const TextStyle(
                            color: AppColors.sub, fontSize: 12.5)),
                  if (!r.valid) ...[
                    const SizedBox(height: 2),
                    Text(r.message,
                        style: const TextStyle(
                            color: AppColors.sub, fontSize: 12)),
                  ],
                  const SizedBox(height: 4),
                  Text('Prochain scan dans ${_cooldown}s',
                      style: AppTheme.mono(size: 10, color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyPanel() {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('HISTORIQUE', style: AppTheme.heading(size: 16)),
                Text('${_history.length} scan${_history.length > 1 ? 's' : ''}',
                    style: AppTheme.mono(size: 10)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _history.isEmpty
                ? const EmptyState(
                    icon: Icons.qr_code_scanner,
                    message: 'Vise un QR code pour le valider.')
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, i) {
                      final h = _history[i];
                      final r = h.result;
                      Color dot = r.valid
                          ? (r.isGirl ? AppColors.pink : AppColors.lime)
                          : (r.alreadyScanned
                              ? AppColors.accent
                              : AppColors.danger);
                      return ListTile(
                        dense: true,
                        leading: Container(
                          width: 10,
                          height: 10,
                          decoration:
                              BoxDecoration(color: dot, shape: BoxShape.circle),
                        ),
                        title: Text(r.holderName ?? 'Inconnu',
                            style: const TextStyle(
                                color: AppColors.bright,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        subtitle: Text(r.formulaName ?? r.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.sub, fontSize: 12)),
                        trailing: Text(h.time.format(context),
                            style: AppTheme.mono(size: 10)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistItem {
  final ScanResult result;
  final TimeOfDay time;
  _HistItem(this.result, this.time);
}
