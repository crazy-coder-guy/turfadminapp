import 'package:equatable/equatable.dart';

class Sport extends Equatable {
  const Sport({
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

  factory Sport.fromJson(Map<String, dynamic> json) {
    return Sport(
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
