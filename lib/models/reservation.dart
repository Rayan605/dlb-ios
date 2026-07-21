class Reservation {
  final int id;
  final int eventId;
  final int formulaId;
  final int quantity;
  final String status; // 'pending' | 'paid' | 'cancelled'
  final int? amountPaidCents;
  final String? qrToken;
  final String? inviteToken;
  final String? scannedAt;
  final String? eventTitle;
  final String? eventDate;
  final String? formulaName;
  final int? formulaMaxGuests;

  const Reservation({
    required this.id,
    required this.eventId,
    required this.formulaId,
    required this.quantity,
    required this.status,
    required this.amountPaidCents,
    required this.qrToken,
    required this.inviteToken,
    required this.scannedAt,
    required this.eventTitle,
    required this.eventDate,
    required this.formulaName,
    required this.formulaMaxGuests,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get hasInvite =>
      isPaid && inviteToken != null && (formulaMaxGuests ?? 0) > 0;

  factory Reservation.fromJson(Map<String, dynamic> j) => Reservation(
        id: j['id'] as int,
        eventId: j['event_id'] as int? ?? 0,
        formulaId: j['formula_id'] as int? ?? 0,
        quantity: j['quantity'] as int? ?? 1,
        status: j['status'] as String? ?? 'pending',
        amountPaidCents: j['amount_paid_cents'] as int?,
        qrToken: j['qr_token'] as String?,
        inviteToken: j['invite_token'] as String?,
        scannedAt: j['scanned_at'] as String?,
        eventTitle: j['event_title'] as String?,
        eventDate: j['event_date'] as String?,
        formulaName: j['formula_name'] as String?,
        formulaMaxGuests: j['formula_max_guests'] as int?,
      );
}

class GuestReservation {
  final int id;
  final int reservationId;
  final int eventId;
  final String qrToken;
  final String status;
  final String? eventTitle;
  final String? eventDate;
  final String? hostFirstName;
  final String? hostLastName;

  const GuestReservation({
    required this.id,
    required this.reservationId,
    required this.eventId,
    required this.qrToken,
    required this.status,
    required this.eventTitle,
    required this.eventDate,
    required this.hostFirstName,
    required this.hostLastName,
  });

  String get hostName =>
      '${hostFirstName ?? ''} ${hostLastName ?? ''}'.trim();

  factory GuestReservation.fromJson(Map<String, dynamic> j) => GuestReservation(
        id: j['id'] as int,
        reservationId: j['reservation_id'] as int? ?? 0,
        eventId: j['event_id'] as int? ?? 0,
        qrToken: j['qr_token'] as String? ?? '',
        status: j['status'] as String? ?? 'active',
        eventTitle: j['event_title'] as String?,
        eventDate: j['event_date'] as String?,
        hostFirstName: j['host_first_name'] as String?,
        hostLastName: j['host_last_name'] as String?,
      );
}

/// Réponse des endpoints QR (/reservations/{id}/qr, /invitations/guest/{id}/qr).
class QrTicket {
  final String qrBase64;
  final String holderName;
  final String? hostName;
  final String eventTitle;
  final String eventDate;
  final String? formulaName;
  final int? quantity;

  const QrTicket({
    required this.qrBase64,
    required this.holderName,
    required this.hostName,
    required this.eventTitle,
    required this.eventDate,
    required this.formulaName,
    required this.quantity,
  });

  factory QrTicket.fromJson(Map<String, dynamic> j) => QrTicket(
        qrBase64: j['qr_base64'] as String? ?? '',
        holderName: j['holder_name'] as String? ?? '',
        hostName: j['host_name'] as String?,
        eventTitle: j['event_title'] as String? ?? '',
        eventDate: j['event_date'] as String? ?? '',
        formulaName: j['formula_name'] as String?,
        quantity: j['quantity'] as int?,
      );
}
