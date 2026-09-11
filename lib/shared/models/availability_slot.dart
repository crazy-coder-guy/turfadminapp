class AvailabilitySlot {
  const AvailabilitySlot({
    required this.startTime,
    required this.endTime,
    required this.startDatetime,
    required this.endDatetime,
    required this.status,
  });

  final String startTime;
  final String endTime;
  final DateTime startDatetime;
  final DateTime endDatetime;
  final String status;

  bool get isAvailable => status == 'AVAILABLE';
  bool get isBooked => status == 'BOOKED';
  bool get isBlocked => status == 'BLOCKED';

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      startDatetime: DateTime.parse(json['start_datetime'] as String),
      endDatetime: DateTime.parse(json['end_datetime'] as String),
      status: json['status'] as String,
    );
  }
}

class DayAvailability {
  const DayAvailability({
    required this.courtId,
    required this.date,
    required this.timezone,
    required this.isBookable,
    required this.slots,
  });

  final String courtId;
  final String date;
  final String timezone;
  final bool isBookable;
  final List<AvailabilitySlot> slots;

  factory DayAvailability.fromJson(Map<String, dynamic> json) {
    final slotsJson = json['slots'] as List<dynamic>? ?? const [];
    return DayAvailability(
      courtId: json['court_id'] as String,
      date: json['date'] as String,
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
      isBookable: json['is_bookable'] as bool? ?? false,
      slots: slotsJson.map((e) => AvailabilitySlot.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
