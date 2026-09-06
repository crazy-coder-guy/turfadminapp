import 'package:equatable/equatable.dart';

class Owner extends Equatable {
  const Owner({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.profileImageUrl,
    required this.ownerType,
    required this.businessName,
    required this.panNumber,
    this.gstin,
    required this.status,
    required this.phoneVerified,
    required this.emailVerified,
    this.lastLoginAt,
    required this.createdAt,
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final String email;
  final String profileImageUrl;
  final String ownerType;
  final String businessName;
  final String panNumber;
  final String? gstin;
  final String status;
  final bool phoneVerified;
  final bool emailVerified;
  final DateTime? lastLoginAt;
  final DateTime createdAt;

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profile_image_url'] as String? ?? '',
      ownerType: json['owner_type'] as String,
      businessName: json['business_name'] as String,
      panNumber: json['pan_number'] as String,
      gstin: json['gstin'] as String?,
      status: json['status'] as String,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      emailVerified: json['email_verified'] as bool? ?? false,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'] as String)
          : null,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, businessName, status];
}
