/// Configuration globale de l'application Liste Party.
///
/// [apiBase] pointe vers l'API FastAPI en production (Azure).
/// [frontendUrl] est l'URL du front web : le backend y renvoie l'utilisateur
/// après un paiement Stripe (success.html / event.html?cancelled=1). On s'en
/// sert dans la WebView de paiement pour détecter la fin du checkout.
class Config {
  Config._();

  static const String apiBase =
      'https://listeparty-enfgcwd7aedpd8h3.francecentral-01.azurewebsites.net';

  /// Doit correspondre à FRONTEND_URL côté backend (variable d'env Azure).
  /// Sert uniquement à repérer les URLs de retour Stripe dans la WebView.
  static const String frontendUrl =
      'https://ashy-wave-040a8fd0f.azurestaticapps.net';

  static const String siteName = 'Liste Party';
  static const String siteSlogan = 'Dans le bon';

  /// Intervalle de rafraîchissement du feed de notifications (app ouverte).
  static const Duration notificationsPollInterval = Duration(seconds: 45);
}
