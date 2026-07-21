class ScanResult {
  final bool valid;
  final String type; // 'reservation' | 'guest' | 'unknown'
  final String message;
  final String? holderName;
  final String? eventTitle;
  final String? eventDate;
  final String? formulaName;
  final bool alreadyScanned;
  final String? scannedAt;
  final String? gender; // 'M' | 'F' | 'X' — toast rose pour les filles

  const ScanResult({
    required this.valid,
    required this.type,
    required this.message,
    required this.holderName,
    required this.eventTitle,
    required this.eventDate,
    required this.formulaName,
    required this.alreadyScanned,
    required this.scannedAt,
    required this.gender,
  });

  bool get isGirl => valid && gender == 'F';

  factory ScanResult.fromJson(Map<String, dynamic> j) => ScanResult(
        valid: j['valid'] == true,
        type: j['type'] as String? ?? 'unknown',
        message: j['message'] as String? ?? '',
        holderName: j['holder_name'] as String?,
        eventTitle: j['event_title'] as String?,
        eventDate: j['event_date'] as String?,
        formulaName: j['formula_name'] as String?,
        alreadyScanned: j['already_scanned'] == true,
        scannedAt: j['scanned_at'] as String?,
        gender: j['gender'] as String?,
      );
}
