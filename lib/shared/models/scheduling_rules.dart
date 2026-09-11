class SchedulingRules {
  const SchedulingRules({
    required this.slotDurationMinutes,
    required this.bookingIntervalMinutes,
    required this.minAdvanceMinutes,
    required this.maxAdvanceDays,
    required this.bufferMinutes,
    required this.timezone,
  });

  final int slotDurationMinutes;
  final int bookingIntervalMinutes;
  final int minAdvanceMinutes;
  final int maxAdvanceDays;
  final int bufferMinutes;
  final String timezone;

  factory SchedulingRules.fromJson(Map<String, dynamic> json) {
    return SchedulingRules(
      slotDurationMinutes: (json['slot_duration_minutes'] as num).toInt(),
      bookingIntervalMinutes: (json['booking_interval_minutes'] as num).toInt(),
      minAdvanceMinutes: (json['min_advance_minutes'] as num).toInt(),
      maxAdvanceDays: (json['max_advance_days'] as num).toInt(),
      bufferMinutes: (json['buffer_minutes'] as num).toInt(),
      timezone: json['timezone'] as String? ?? 'Asia/Kolkata',
    );
  }
}
