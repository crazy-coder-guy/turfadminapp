import '../../../shared/models/turf.dart';

class CompletenessItem {
  const CompletenessItem(this.label, this.isComplete);
  final String label;
  final bool isComplete;
}

class TurfCompleteness {
  const TurfCompleteness(this.items);

  final List<CompletenessItem> items;

  bool get isComplete => items.every((item) => item.isComplete);

  List<String> get missing =>
      items.where((item) => !item.isComplete).map((item) => item.label).toList();
}

TurfCompleteness evaluateTurfCompleteness(Turf turf) {
  final hasBasicInfo = turf.name.trim().isNotEmpty &&
      (turf.description?.trim().isNotEmpty ?? false) &&
      turf.contactPhone.trim().isNotEmpty;

  final hasLocation = turf.location != null &&
      turf.location!.addressLine1.isNotEmpty &&
      turf.location!.city.isNotEmpty &&
      turf.location!.state.isNotEmpty &&
      turf.location!.pincode.isNotEmpty;

  final activeCourts = turf.courts.where((c) => c.isActive).toList();
  final hasActiveCourt = activeCourts.isNotEmpty;
  final everyActiveCourtHasSport =
      activeCourts.isNotEmpty && activeCourts.every((c) => c.sports.isNotEmpty);

  final hasThumbnail = turf.thumbnailMedia != null;

  return TurfCompleteness([
    CompletenessItem('Basic information', hasBasicInfo),
    CompletenessItem('Location', hasLocation),
    CompletenessItem('At least one active court', hasActiveCourt),
    CompletenessItem('Every active court has a sport', everyActiveCourtHasSport),
    CompletenessItem('Thumbnail image', hasThumbnail),
  ]);
}
