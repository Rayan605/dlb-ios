class Formula {
  final int id;
  final String name;
  final String? description;
  final int priceCents;
  final int position;
  final int maxGuests;
  final bool isGirlsOnly;

  const Formula({
    required this.id,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.position,
    required this.maxGuests,
    required this.isGirlsOnly,
  });

  bool get isFree => isGirlsOnly;

  factory Formula.fromJson(Map<String, dynamic> j) => Formula(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        description: j['description'] as String?,
        priceCents: j['price_cents'] as int? ?? 0,
        position: j['position'] as int? ?? 0,
        maxGuests: j['max_guests'] as int? ?? 0,
        isGirlsOnly: j['is_girls_only'] == 1 || j['is_girls_only'] == true,
      );
}

/// Disponibilité par formule (endpoint /events/{id}/formula-availability).
class FormulaAvailability {
  final int reservationsCount;
  final int? spotsLeft; // null = illimité
  final int maxReservations;

  const FormulaAvailability({
    required this.reservationsCount,
    required this.spotsLeft,
    required this.maxReservations,
  });

  bool get isFull => spotsLeft != null && spotsLeft! <= 0;

  factory FormulaAvailability.fromJson(Map<String, dynamic> j) =>
      FormulaAvailability(
        reservationsCount: j['reservations_count'] as int? ?? 0,
        spotsLeft: j['spots_left'] as int?,
        maxReservations: j['max_reservations'] as int? ?? 0,
      );
}
