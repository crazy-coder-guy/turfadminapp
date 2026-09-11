class OperatingHoursWindow {
  const OperatingHoursWindow({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
  });

  final String id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;

  factory OperatingHoursWindow.fromJson(Map<String, dynamic> json) {
    return OperatingHoursWindow(
      id: json['id'] as String,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );
  }
}

const List<String> kDayOfWeekLabels = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];
