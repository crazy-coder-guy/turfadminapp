import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../../../shared/models/amenity.dart';
import '../../../shared/models/sport.dart';
import '../data/master_data_repository.dart';

final masterDataRepositoryProvider = Provider<MasterDataRepository>((ref) {
  return MasterDataRepository(ref.read(apiClientProvider));
});

final sportsProvider = FutureProvider<List<Sport>>((ref) {
  return ref.read(masterDataRepositoryProvider).getSports();
});

final amenitiesProvider = FutureProvider<List<Amenity>>((ref) {
  return ref.read(masterDataRepositoryProvider).getAmenities();
});
