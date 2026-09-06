import 'package:equatable/equatable.dart';

class Amenity extends Equatable {
  const Amenity({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.status,
  });

  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String status;

  bool get isActive => status == 'active';

  factory Amenity.fromJson(Map<String, dynamic> json) {
    return Amenity(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }

  @override
  List<Object?> get props => [id, name, status];
}
