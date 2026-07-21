import 'package:intl/intl.dart';

/// Formatage FR partagé (prix, dates), équivalent des helpers du frontend web.
class Fmt {
  Fmt._();

  static final _price = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 0,
  );

  static String price(int? cents) => _price.format((cents ?? 0) / 100);

  static String priceOrFree(int cents, {bool free = false}) =>
      free ? 'GRATUIT' : price(cents);

  static DateTime? _parse(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.toLocal();
  }

  /// « vendredi 12 juillet 2026 »
  static String date(String? iso) {
    final d = _parse(iso);
    if (d == null) return '';
    return DateFormat('EEEE d MMMM y', 'fr_FR').format(d);
  }

  /// « 12 juil. »
  static String dateShort(String? iso) {
    final d = _parse(iso);
    if (d == null) return '';
    return DateFormat('d MMM', 'fr_FR').format(d);
  }

  /// « 23:30 »
  static String time(String? iso) {
    final d = _parse(iso);
    if (d == null) return '';
    return DateFormat('HH:mm', 'fr_FR').format(d);
  }

  /// « 12 juil. · 23:30 »
  static String dateTime(String? iso) {
    final d = _parse(iso);
    if (d == null) return '';
    return DateFormat('d MMM · HH:mm', 'fr_FR').format(d);
  }
}
