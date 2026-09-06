import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../../../shared/models/owner_document.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/documents_repository.dart';

final documentsRepositoryProvider = Provider<DocumentsRepository>((ref) {
  return DocumentsRepository(ref.read(apiClientProvider));
});

final ownerDocumentsProvider = FutureProvider.autoDispose<List<OwnerDocument>>((ref) async {
  final owner = ref.watch(authControllerProvider).owner;
  if (owner == null) return const [];
  final page = await ref.read(documentsRepositoryProvider).list(owner.id);
  return page.items;
});
