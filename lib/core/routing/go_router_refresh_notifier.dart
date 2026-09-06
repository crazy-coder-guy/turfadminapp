import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }
}
