class TurfLocation {
  const TurfLocation({
    required this.addressLine1,
    this.addressLine2,
    this.landmark,
    this.locality,
    required this.city,
    this.district,
    required this.state,
    this.country = 'India',
    required this.pincode,
    required this.latitude,
    required this.longitude,
  });

  final String addressLine1;
  final String? addressLine2;
  final String? landmark;
  final String? locality;
  final String city;
  final String? district;
  final String state;
  final String country;
  final String pincode;
  final double latitude;
  final double longitude;

  factory TurfLocation.fromJson(Map<String, dynamic> json) {
    return TurfLocation(
      addressLine1: json['address_line_1'] as String? ?? '',
      addressLine2: json['address_line_2'] as String?,
      landmark: json['landmark'] as String?,
      locality: json['locality'] as String?,
      city: json['city'] as String? ?? '',
      district: json['district'] as String?,
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      pincode: json['pincode'] as String? ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address_line_1': addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) 'address_line_2': addressLine2,
      if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
      if (locality != null && locality!.isNotEmpty) 'locality': locality,
      'city': city,
      if (district != null && district!.isNotEmpty) 'district': district,
      'state': state,
      'country': country,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get shortAddress => [city, state].where((s) => s.isNotEmpty).join(', ');
}
