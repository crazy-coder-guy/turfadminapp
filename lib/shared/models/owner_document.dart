class OwnerDocument {
  const OwnerDocument({
    required this.id,
    required this.ownerId,
    required this.documentType,
    required this.documentNumber,
    required this.documentUrl,
    required this.verificationStatus,
    this.rejectionReason,
  });

  final String id;
  final String ownerId;
  final String documentType;
  final String documentNumber;
  final String documentUrl;
  final String verificationStatus;
  final String? rejectionReason;

  factory OwnerDocument.fromJson(Map<String, dynamic> json) {
    return OwnerDocument(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      documentType: json['document_type'] as String,
      documentNumber: json['document_number'] as String,
      documentUrl: json['document_url'] as String,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}
