import '../../../core/network/api_client.dart';
import '../../../shared/models/availability_slot.dart';
import '../../../shared/models/court_block.dart';
import '../../../shared/models/operating_hours.dart';
import '../../../shared/models/pricing_rule.dart';
import '../../../shared/models/scheduling_rules.dart';

class MarketplaceRepository {
  MarketplaceRepository(this._client);

  final ApiClient _client;

  String _courtBase(String turfId, String courtId) => '/turfs/$turfId/courts/$courtId';

  // Operating hours

  Future<List<OperatingHoursWindow>> listOperatingHours(String turfId, String courtId) async {
    final response = await _client.get('${_courtBase(turfId, courtId)}/operating-hours');
    final rows = response['data'] as List<dynamic>;
    return rows.map((e) => OperatingHoursWindow.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OperatingHoursWindow> createOperatingHours(
    String turfId,
    String courtId, {
    required int dayOfWeek,
    required String startTime,
    required String endTime,
  }) async {
    final response = await _client.post('${_courtBase(turfId, courtId)}/operating-hours', data: {
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
    });
    return OperatingHoursWindow.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<OperatingHoursWindow> updateOperatingHours(
    String turfId,
    String courtId,
    String id, {
    int? dayOfWeek,
    String? startTime,
    String? endTime,
  }) async {
    final response = await _client.patch('${_courtBase(turfId, courtId)}/operating-hours/$id', data: {
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
    });
    return OperatingHoursWindow.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteOperatingHours(String turfId, String courtId, String id) async {
    await _client.delete('${_courtBase(turfId, courtId)}/operating-hours/$id');
  }

  // Scheduling rules

  Future<SchedulingRules> getSchedulingRules(String turfId, String courtId) async {
    final response = await _client.get('${_courtBase(turfId, courtId)}/scheduling-rules');
    return SchedulingRules.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<SchedulingRules> saveSchedulingRules(
    String turfId,
    String courtId, {
    int? slotDurationMinutes,
    int? bookingIntervalMinutes,
    int? minAdvanceMinutes,
    int? maxAdvanceDays,
    int? bufferMinutes,
    String? timezone,
  }) async {
    final response = await _client.put('${_courtBase(turfId, courtId)}/scheduling-rules', data: {
      if (slotDurationMinutes != null) 'slot_duration_minutes': slotDurationMinutes,
      if (bookingIntervalMinutes != null) 'booking_interval_minutes': bookingIntervalMinutes,
      if (minAdvanceMinutes != null) 'min_advance_minutes': minAdvanceMinutes,
      if (maxAdvanceDays != null) 'max_advance_days': maxAdvanceDays,
      if (bufferMinutes != null) 'buffer_minutes': bufferMinutes,
      if (timezone != null) 'timezone': timezone,
    });
    return SchedulingRules.fromJson(response['data'] as Map<String, dynamic>);
  }

  // Pricing rules

  Future<List<PricingRule>> listPricingRules(String turfId, String courtId) async {
    final response = await _client.get('${_courtBase(turfId, courtId)}/pricing');
    final rows = response['data'] as List<dynamic>;
    return rows.map((e) => PricingRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PricingRule> createPricingRule(
    String turfId,
    String courtId, {
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    required double priceAmount,
    bool isActive = true,
  }) async {
    final response = await _client.post('${_courtBase(turfId, courtId)}/pricing', data: {
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'price_amount': priceAmount,
      'is_active': isActive,
    });
    return PricingRule.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<PricingRule> updatePricingRule(
    String turfId,
    String courtId,
    String id, {
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    double? priceAmount,
    bool? isActive,
  }) async {
    final response = await _client.patch('${_courtBase(turfId, courtId)}/pricing/$id', data: {
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (priceAmount != null) 'price_amount': priceAmount,
      if (isActive != null) 'is_active': isActive,
    });
    return PricingRule.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deletePricingRule(String turfId, String courtId, String id) async {
    await _client.delete('${_courtBase(turfId, courtId)}/pricing/$id');
  }

  // Blocks

  Future<List<CourtBlock>> listBlocks(String turfId, String courtId, {String status = 'active'}) async {
    final response = await _client.get('${_courtBase(turfId, courtId)}/blocks', query: {'status': status});
    final payload = response['data'] as Map<String, dynamic>;
    final rows = payload['data'] as List<dynamic>;
    return rows.map((e) => CourtBlock.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CourtBlock> createBlock(
    String turfId,
    String courtId, {
    required DateTime startDatetime,
    required DateTime endDatetime,
    String? reason,
  }) async {
    final response = await _client.post('${_courtBase(turfId, courtId)}/blocks', data: {
      'start_datetime': startDatetime.toUtc().toIso8601String(),
      'end_datetime': endDatetime.toUtc().toIso8601String(),
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    return CourtBlock.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<void> deleteBlock(String turfId, String courtId, String id) async {
    await _client.delete('${_courtBase(turfId, courtId)}/blocks/$id');
  }

  // Availability

  Future<DayAvailability> getAvailability(String turfId, String courtId, String date) async {
    final response = await _client.get('${_courtBase(turfId, courtId)}/availability', query: {'date': date});
    return DayAvailability.fromJson(response['data'] as Map<String, dynamic>);
  }
}
