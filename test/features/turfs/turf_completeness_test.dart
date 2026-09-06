import 'package:flutter_test/flutter_test.dart';
import 'package:turf_admin_app/shared/models/court.dart';
import 'package:turf_admin_app/shared/models/sport.dart';
import 'package:turf_admin_app/shared/models/turf.dart';
import 'package:turf_admin_app/shared/models/turf_location.dart';
import 'package:turf_admin_app/shared/models/turf_media.dart';
import 'package:turf_admin_app/features/turfs/domain/turf_completeness.dart';

Turf _baseTurf({
  String? description,
  TurfLocation? location,
  List<Court> courts = const [],
  List<TurfMedia> media = const [],
}) {
  final now = DateTime.now();
  return Turf(
    id: 't1',
    ownerId: 'o1',
    name: 'Test Turf',
    description: description,
    contactPhone: '9000000000',
    status: 'active',
    approvalStatus: 'draft',
    location: location,
    courts: courts,
    media: media,
    createdAt: now,
    updatedAt: now,
  );
}

const _location = TurfLocation(
  addressLine1: '1 Main Road',
  city: 'Salem',
  state: 'Tamil Nadu',
  pincode: '636001',
  latitude: 11.6,
  longitude: 78.1,
);

const _sport = Sport(id: 's1', name: 'Football', status: 'active');

Court _activeCourtWithSport() {
  return Court(
    id: 'c1',
    turfId: 't1',
    name: 'Court 1',
    isIndoor: false,
    status: 'active',
    sports: const [_sport],
  );
}

void main() {
  group('evaluateTurfCompleteness', () {
    test('a bare turf is incomplete on every axis', () {
      final result = evaluateTurfCompleteness(_baseTurf());
      expect(result.isComplete, isFalse);
      expect(result.missing, contains('Basic information'));
      expect(result.missing, contains('Location'));
      expect(result.missing, contains('At least one active court'));
      expect(result.missing, contains('Thumbnail image'));
    });

    test('missing description keeps basic information incomplete', () {
      final result = evaluateTurfCompleteness(_baseTurf(location: _location));
      expect(result.items.firstWhere((i) => i.label == 'Basic information').isComplete, isFalse);
    });

    test('a court without any sport keeps the sports check incomplete', () {
      final court = Court(id: 'c1', turfId: 't1', name: 'Court 1', isIndoor: false, status: 'active');
      final result = evaluateTurfCompleteness(_baseTurf(
        description: 'desc',
        location: _location,
        courts: [court],
      ));
      expect(
        result.items.firstWhere((i) => i.label == 'Every active court has a sport').isComplete,
        isFalse,
      );
    });

    test('an inactive court does not count toward "at least one active court"', () {
      final inactiveCourt = Court(
        id: 'c1',
        turfId: 't1',
        name: 'Court 1',
        isIndoor: false,
        status: 'inactive',
        sports: const [_sport],
      );
      final result = evaluateTurfCompleteness(_baseTurf(
        description: 'desc',
        location: _location,
        courts: [inactiveCourt],
      ));
      expect(
        result.items.firstWhere((i) => i.label == 'At least one active court').isComplete,
        isFalse,
      );
    });

    test('a fully configured turf is complete', () {
      final result = evaluateTurfCompleteness(_baseTurf(
        description: 'A great turf',
        location: _location,
        courts: [_activeCourtWithSport()],
        media: const [
          TurfMedia(
            id: 'm1',
            mediaType: 'image',
            mediaUrl: 'https://x.com/a.jpg',
            category: kMediaCategoryThumbnail,
            isPrimary: false,
            sortOrder: 0,
          ),
        ],
      ));
      expect(result.isComplete, isTrue);
      expect(result.missing, isEmpty);
    });
  });
}
