class PricingRule {
  const PricingRule({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.priceAmount,
    required this.currency,
    required this.isActive,
    this.effectiveFrom,
    this.effectiveTo,
  });

  final String id;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final double priceAmount;
  final String currency;
  final bool isActive;
  final String? effectiveFrom;
  final String? effectiveTo;

  factory PricingRule.fromJson(Map<String, dynamic> json) {
    return PricingRule(
      id: json['id'] as String,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      priceAmount: double.tryParse(json['price_amount'].toString()) ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      isActive: json['is_active'] as bool? ?? true,
      effectiveFrom: json['effective_from'] as String?,
      effectiveTo: json['effective_to'] as String?,
    );
  }
}
