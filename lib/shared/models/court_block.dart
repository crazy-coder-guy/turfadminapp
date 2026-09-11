class CourtBlock {
  const CourtBlock({
    required this.id,
    required this.startDatetime,
    required this.endDatetime,
    this.reason,
    required this.status,
  });

  final String id;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String? reason;
  final String status;

  factory CourtBlock.fromJson(Map<String, dynamic> json) {
    return CourtBlock(
      id: json['id'] as String,
      startDatetime: DateTime.parse(json['start_datetime'] as String),
      endDatetime: DateTime.parse(json['end_datetime'] as String),
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }
}
