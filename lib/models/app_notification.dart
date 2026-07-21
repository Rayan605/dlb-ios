class AppNotification {
  final int id;
  final String title;
  final String body;
  final int? eventId;
  final String createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.eventId,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        eventId: j['event_id'] as int?,
        createdAt: j['created_at'] as String? ?? '',
      );
}
