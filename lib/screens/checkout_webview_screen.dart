import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme.dart';

enum CheckoutStatus { success, cancelled }

class CheckoutResult {
  final CheckoutStatus status;
  final String? sessionId;
  const CheckoutResult(this.status, {this.sessionId});
}

/// Ouvre Stripe Checkout (URL renvoyée par /reservations/checkout) dans une
/// WebView. On intercepte la navigation :
///  - retour vers success.html?session_id=... → succès
///  - retour vers event.html?...cancelled=1   → annulation
///
/// Les billets d'entrée à un événement réel sont un service physique : le
/// paiement externe (hors achat in-app App Store / Google Play) est autorisé.
class CheckoutWebViewScreen extends StatefulWidget {
  final String checkoutUrl;
  const CheckoutWebViewScreen({super.key, required this.checkoutUrl});

  @override
  State<CheckoutWebViewScreen> createState() => _CheckoutWebViewScreenState();
}

class _CheckoutWebViewScreenState extends State<CheckoutWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (_) {},
          onPageStarted: (url) {
            _intercept(url);
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (req) {
            if (_intercept(req.url)) return NavigationDecision.prevent;
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  /// Retourne true si l'URL est une URL de retour (et ferme l'écran).
  bool _intercept(String url) {
    if (_closed) return true;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final path = uri.path.toLowerCase();

    if (path.contains('success')) {
      _closed = true;
      final sessionId = uri.queryParameters['session_id'];
      _pop(CheckoutResult(CheckoutStatus.success, sessionId: sessionId));
      return true;
    }
    if (uri.queryParameters['cancelled'] == '1' ||
        path.contains('cancel')) {
      _closed = true;
      _pop(const CheckoutResult(CheckoutStatus.cancelled));
      return true;
    }
    return false;
  }

  void _pop(CheckoutResult result) {
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PAIEMENT SÉCURISÉ'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context)
              .pop(const CheckoutResult(CheckoutStatus.cancelled)),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const LinearProgressIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.raised,
            ),
        ],
      ),
    );
  }
}
