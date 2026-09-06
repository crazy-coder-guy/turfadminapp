import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/turf.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/turf_providers.dart';

class TurfListScreen extends ConsumerStatefulWidget {
  const TurfListScreen({super.key});

  @override
  ConsumerState<TurfListScreen> createState() => _TurfListScreenState();
}

class _TurfListScreenState extends ConsumerState<TurfListScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'approved', 'pending', 'draft'

  @override
  Widget build(BuildContext context) {
    final turfsAsync = ref.watch(turfListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Turf Management',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manage your sports venues and court allocations',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(turfListProvider),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Refresh turfs',
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 74),
        child: FloatingActionButton.extended(
          onPressed: () => context.go('/turfs/new'),
          backgroundColor: AppColors.primary,
          elevation: 3,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Add New Turf',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14),
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(turfListProvider),
          child: turfsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => ErrorStateView(
              message: 'Unable to load your turfs.',
              onRetry: () => ref.invalidate(turfListProvider),
            ),
            data: (page) {
              final allTurfs = page.items;
              if (allTurfs.isEmpty) {
                return EmptyStateView(
                  title: 'No venues listed yet',
                  message: 'Add your first sports turf to start managing court schedules and bookings.',
                  icon: Icons.sports_soccer_outlined,
                  actionLabel: 'Create your first turf',
                  onAction: () => context.go('/turfs/new'),
                );
              }

              // Compute counts for filter pills
              final totalCount = allTurfs.length;
              final approvedCount = allTurfs.where((t) => t.approvalStatus == 'approved').length;
              final pendingCount = allTurfs.where((t) => t.approvalStatus == 'submitted' || t.approvalStatus == 'under_review').length;
              final draftCount = allTurfs.where((t) => t.approvalStatus == 'draft' || t.approvalStatus == 'rejected').length;

              // Filter list
              final filteredTurfs = allTurfs.where((turf) {
                final matchesSearch = _searchQuery.isEmpty ||
                    turf.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (turf.location?.city.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

                if (!matchesSearch) return false;

                if (_selectedFilter == 'approved') return turf.approvalStatus == 'approved';
                if (_selectedFilter == 'pending') return turf.approvalStatus == 'submitted' || turf.approvalStatus == 'under_review';
                if (_selectedFilter == 'draft') return turf.approvalStatus == 'draft' || turf.approvalStatus == 'rejected';
                return true;
              }).toList();

              return CustomScrollView(
                slivers: [
                  // Search & Quick Filter Controls
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Input Box
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: TextField(
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                              decoration: const InputDecoration(
                                hintText: 'Search venue name or city...',
                                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                                prefixIcon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Status Filter Chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'All ($totalCount)',
                                  isSelected: _selectedFilter == 'all',
                                  onTap: () => setState(() => _selectedFilter = 'all'),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Approved ($approvedCount)',
                                  isSelected: _selectedFilter == 'approved',
                                  onTap: () => setState(() => _selectedFilter = 'approved'),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Under Review ($pendingCount)',
                                  isSelected: _selectedFilter == 'pending',
                                  onTap: () => setState(() => _selectedFilter = 'pending'),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Draft / Action Needed ($draftCount)',
                                  isSelected: _selectedFilter == 'draft',
                                  onTap: () => setState(() => _selectedFilter = 'draft'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Divider
                  const SliverToBoxAdapter(
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),

                  // Venue List Items
                  if (filteredTurfs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
                            SizedBox(height: 12),
                            Text(
                              'No matching turfs found',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Try adjusting your search terms or filter selection.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final turf = filteredTurfs[index];
                            final isLast = index == filteredTurfs.length - 1;
                            return Column(
                              children: [
                                _TurfListItem(turf: turf),
                                if (!isLast) const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              ],
                            );
                          },
                          childCount: filteredTurfs.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

class _TurfListItem extends StatelessWidget {
  const _TurfListItem({required this.turf});

  final Turf turf;

  @override
  Widget build(BuildContext context) {
    final coverUrl = turf.thumbnailMedia?.mediaUrl ??
        (turf.galleryMedia.isNotEmpty ? turf.galleryMedia.first.mediaUrl : null);

    return InkWell(
      onTap: () => context.go('/turfs/${turf.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Venue Cover Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: coverUrl != null
                    ? AppNetworkImage(
                        url: coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: _placeholderImage(),
                        placeholder: _placeholderImage(),
                      )
                    : _placeholderImage(),
              ),
            ),
            const SizedBox(width: 14),

            // Main Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          turf.name,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge.forTurf(approvalStatus: turf.approvalStatus, status: turf.status),
                      if (turf.hasPendingChanges) ...[
                        const SizedBox(width: 6),
                        const Tooltip(
                          message: 'Recent changes are awaiting super admin review',
                          child: Icon(Icons.fact_check_outlined, size: 16, color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Location & City
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          turf.location != null ? turf.location!.shortAddress : 'No location added',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Quick Attributes (Courts + Phone)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF8FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.sports_soccer_rounded, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${turf.courts.length} Court${turf.courts.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        turf.contactPhone,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: const Icon(Icons.sports_soccer_rounded, color: Color(0xFF94A3B8), size: 28),
    );
  }
}

