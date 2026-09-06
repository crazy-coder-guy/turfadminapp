import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/turf.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../turfs/domain/turf_completeness.dart';
import '../../../turfs/domain/turf_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(authControllerProvider).owner;
    final turfsAsync = ref.watch(turfListProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Dashboard',
          style: AppTextStyles.appHeader().copyWith(
            color: const Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(turfListProvider),
          child: turfsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorStateView(
              message: error is Exception ? error.toString() : 'Something went wrong.',
              onRetry: () => ref.invalidate(turfListProvider),
            ),
            data: (page) {
              final turfs = page.items;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                children: [
                  Text(
                    '$greeting 👋',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    owner != null ? 'Manage ${owner.businessName}' : 'Manage your turf business',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'OVERVIEW',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _OverviewGrid(turfs: turfs),
                  const SizedBox(height: 32),
                  ..._buildPendingActions(context, turfs),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPendingActions(BuildContext context, List<Turf> turfs) {
    final actions = <_PendingAction>[];

    if (turfs.isEmpty) {
      actions.add(
        _PendingAction(
          message: 'Create your first turf to get started',
          onTap: () => context.go('/turfs/new'),
        ),
      );
    }

    for (final turf in turfs) {
      if (turf.approvalStatus == 'rejected') {
        actions.add(
          _PendingAction(
            message: '"${turf.name}" was rejected — review feedback',
            onTap: () => context.go('/turfs/${turf.id}'),
          ),
        );
      } else if (turf.approvalStatus == 'under_review') {
        actions.add(
          _PendingAction(
            message: '"${turf.name}" is under review',
            onTap: () => context.go('/turfs/${turf.id}'),
          ),
        );
      } else if (turf.approvalStatus == 'draft') {
        final completeness = evaluateTurfCompleteness(turf);
        if (!completeness.isComplete) {
          actions.add(
            _PendingAction(
              message: 'Complete "${turf.name}": ${completeness.missing.first}',
              onTap: () => context.go('/turfs/${turf.id}'),
            ),
          );
        } else {
          actions.add(
            _PendingAction(
              message: '"${turf.name}" is ready — submit it for review',
              onTap: () => context.go('/turfs/${turf.id}'),
            ),
          );
        }
      }
    }

    if (actions.isEmpty) return const [];

    return [
      const Text(
        'PENDING ACTIONS',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Color(0xFF94A3B8),
        ),
      ),
      const SizedBox(height: 8),
      ...actions.map(
        (action) => Column(
          children: [
            InkWell(
              onTap: action.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action.message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],
        ),
      ),
    ];
  }
}

class _PendingAction {
  _PendingAction({required this.message, required this.onTap});
  final String message;
  final VoidCallback onTap;
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.turfs});

  final List<Turf> turfs;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{
      'Total': turfs.length,
      'Draft': turfs.where((t) => t.approvalStatus == 'draft').length,
      'Submitted': turfs.where((t) => t.approvalStatus == 'submitted').length,
      'Under review': turfs.where((t) => t.approvalStatus == 'under_review').length,
      'Live': turfs.where((t) => t.isLive).length,
      'Rejected': turfs.where((t) => t.approvalStatus == 'rejected').length,
    };

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: counts.entries
          .map((entry) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
