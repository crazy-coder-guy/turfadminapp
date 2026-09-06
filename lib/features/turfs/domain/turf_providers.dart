import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/turf.dart';
import '../data/turf_repository.dart';

final turfRepositoryProvider = Provider<TurfRepository>((ref) {
  return TurfRepository(ref.read(apiClientProvider));
});

final turfListProvider = FutureProvider.autoDispose<PaginatedResponse<Turf>>((ref) {
  return ref.read(turfRepositoryProvider).listTurfs(pageSize: 100);
});

final turfDetailProvider = FutureProvider.autoDispose.family<Turf, String>((ref, turfId) {
  return ref.read(turfRepositoryProvider).getTurf(turfId);
});
