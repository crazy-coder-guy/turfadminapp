class OwnerDocumentTypeOption {
  const OwnerDocumentTypeOption(this.value, this.label);

  final String value;
  final String label;
}

const List<OwnerDocumentTypeOption> kOwnerDocumentTypes = [
  OwnerDocumentTypeOption('pan_card', 'PAN Card'),
  OwnerDocumentTypeOption('aadhaar_card', 'Aadhaar Card'),
  OwnerDocumentTypeOption('gst_certificate', 'GST Certificate'),
  OwnerDocumentTypeOption('business_license', 'Business License'),
  OwnerDocumentTypeOption('bank_statement', 'Bank Statement / Cancelled Cheque'),
  OwnerDocumentTypeOption('address_proof', 'Address Proof'),
];

String ownerDocumentTypeLabel(String value) {
  for (final option in kOwnerDocumentTypes) {
    if (option.value == value) return option.label;
  }
  return value;
}

const String kDocumentNumberPendingAdminEntry = 'PENDING_ADMIN_ENTRY';
