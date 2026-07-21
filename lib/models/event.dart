class EventMedia {
  final int id;
  final String url;
  final int position;
  final bool isRecap;
  final String mediaType; // 'image' | 'video'

  const EventMedia({
    required this.id,
    required this.url,
    required this.position,
    required this.isRecap,
    required this.mediaType,
  });

  bool get isVideo => mediaType == 'video';

  factory EventMedia.fromJson(Map<String, dynamic> j) => EventMedia(
        id: j['id'] as int,
        url: j['url'] as String? ?? '',
        position: j['position'] as int? ?? 0,
        isRecap: j['is_recap'] == true || j['is_recap'] == 1,
        mediaType: j['media_type'] as String? ?? 'image',
      );
}

class PartyEvent {
  final int id;
  final String title;
  final String? description;
  final String date; // ISO 8601
  final String city;
  final String department;
  final int maxPeople;
  final bool isPast;
  final int reservationsOpen; // 1 ouvert / 0 fermé
  final List<EventMedia> images;
  final List<EventMedia> recapImages;
  final int seatsTaken;
  final int seatsLeft;

  const PartyEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.city,
    required this.department,
    required this.maxPeople,
    required this.isPast,
    required this.reservationsOpen,
    required this.images,
    required this.recapImages,
    required this.seatsTaken,
    required this.seatsLeft,
  });

  bool get isFull => seatsLeft <= 0;
  bool get isUrgent => !isFull && seatsLeft <= 10;
  bool get reservationsClosed => reservationsOpen == 0;
  EventMedia? get cover => images.isNotEmpty ? images.first : null;
  EventMedia? get recapCover =>
      recapImages.isNotEmpty ? recapImages.first : null;

  factory PartyEvent.fromJson(Map<String, dynamic> j) {
    List<EventMedia> parse(String key) => ((j[key] as List?) ?? [])
        .map((e) => EventMedia.fromJson(e as Map<String, dynamic>))
        .toList();
    return PartyEvent(
      id: j['id'] as int,
      title: j['title'] as String? ?? '',
      description: j['description'] as String?,
      date: j['date'] as String? ?? '',
      city: j['city'] as String? ?? '',
      department: j['department'] as String? ?? '',
      maxPeople: j['max_people'] as int? ?? 0,
      isPast: j['is_past'] == true || j['is_past'] == 1,
      reservationsOpen: (j['reservations_open'] as int?) ?? 1,
      images: parse('images'),
      recapImages: parse('recap_images'),
      seatsTaken: j['seats_taken'] as int? ?? 0,
      seatsLeft: j['seats_left'] as int? ?? 0,
    );
  }
}
