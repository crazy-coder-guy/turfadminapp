import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/court.dart';
import '../../../../shared/models/turf.dart';
import '../../../../shared/models/turf_media.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/error_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/turf_completeness.dart';
import '../../domain/turf_providers.dart';
import '../widgets/completeness_checklist.dart';
import '../widgets/turf_media_section.dart';

class TurfDetailScreen extends ConsumerWidget {
  const TurfDetailScreen({super.key, required this.turfId});

  final String turfId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turfAsync = ref.watch(turfDetailProvider(turfId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: turfAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Scaffold(
            appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
            body: ErrorStateView(
              message: error is AppException ? error.message : 'Unable to load this turf.',
              onRetry: () => ref.invalidate(turfDetailProvider(turfId)),
            ),
          ),
          data: (turf) => DefaultTabController(
            length: 3,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Cover Header
                      _HeroHeader(turf: turf, turfId: turfId),

                      // Turf Header Title & Quick Attributes
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    turf.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                StatusBadge.forTurf(
                                  approvalStatus: turf.approvalStatus,
                                  status: turf.status,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Quick Attributes Row
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (turf.location?.city.isNotEmpty ?? false) ...[
                                    _QuickAttributeChip(
                                      icon: Icons.location_on_outlined,
                                      label: turf.location!.city,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  _QuickAttributeChip(
                                    icon: Icons.sports_soccer_rounded,
                                    label: '${turf.courts.length} Court${turf.courts.length == 1 ? '' : 's'}',
                                  ),
                                  const SizedBox(width: 8),
                                  _QuickAttributeChip(
                                    icon: Icons.phone_outlined,
                                    label: turf.contactPhone,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status Banners if Rejected or Submitted
                      if (turf.approvalStatus == 'rejected')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: _RejectionBanner(turf: turf),
                        )
                      else if (turf.approvalStatus == 'submitted' || turf.approvalStatus == 'under_review')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: _ReviewStatusBanner(turf: turf),
                        )
                      else if (turf.hasPendingChanges)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          child: _PendingChangesBanner(),
                        ),

                      const SizedBox(height: 8),

                      // TabBar Header
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: Color(0xFFF1F5F9)),
                            bottom: BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        child: TabBar(
                          labelColor: AppColors.primary,
                          unselectedLabelColor: const Color(0xFF64748B),
                          indicatorColor: AppColors.primary,
                          indicatorWeight: 2.5,
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          tabs: [
                            const Tab(text: 'Overview'),
                            Tab(text: 'Courts (${turf.courts.length})'),
                            const Tab(text: 'Photos & Media'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              body: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: [
                        _OverviewTab(turf: turf),
                        _CourtsTab(turf: turf),
                        _MediaTab(turf: turf),
                      ],
                    ),
                  ),

                  // Fixed Bottom Action Bar
                  if (turf.isEditable)
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        12,
                        20,
                        76,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: _ActionBar(turf: turf),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.turf, required this.turfId});

  final Turf turf;
  final String turfId;

  @override
  Widget build(BuildContext context) {
    final coverUrl = turf.thumbnailMedia?.mediaUrl ??
        (turf.galleryMedia.isNotEmpty ? turf.galleryMedia.first.mediaUrl : null);

    return SizedBox(
      height: 210,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          coverUrl != null
              ? AppNetworkImage(
                  url: coverUrl,
                  fit: BoxFit.cover,
                  errorWidget: _buildFallbackCover(),
                )
              : _buildFallbackCover(),

          // Dark Gradient Overlay for Header Controls readability
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black54,
                  Colors.transparent,
                  Colors.black38,
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),

          // Top Floating Action Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _FrostedCircleButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => context.pop(),
                ),
                if (turf.isEditable)
                  _FrostedCircleButton(
                    icon: Icons.edit_outlined,
                    onTap: () => context.go('/turfs/$turfId/edit'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_soccer_rounded, size: 48, color: Color(0xFF64748B)),
            SizedBox(height: 6),
            Text(
              'No Cover Image Uploaded',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrostedCircleButton extends StatelessWidget {
  const _FrostedCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _QuickAttributeChip extends StatelessWidget {
  const _QuickAttributeChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.turf});

  final Turf turf;

  @override
  Widget build(BuildContext context) {
    final location = turf.location;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
      children: [
        if (turf.description != null && turf.description!.isNotEmpty) ...[
          const Text(
            'ABOUT THIS TURF',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            turf.description!,
            style: const TextStyle(fontSize: 14.5, color: Color(0xFF475569), height: 1.5),
          ),
          const SizedBox(height: 24),
        ],

        // Location & Address Section
        const Text(
          'LOCATION & ADDRESS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        if (location != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF8FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFB9E6FE)),
                ),
                child: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.addressLine1,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                    if (location.addressLine2 != null && location.addressLine2!.isNotEmpty)
                      Text(location.addressLine2!, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    Text(
                      [location.locality, location.city].where((s) => s != null && s.isNotEmpty).join(', '),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '${location.state} ${location.pincode}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'GPS: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          const Text('No location details provided.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),

        const SizedBox(height: 24),

        // Contact Information
        const Text(
          'CONTACT INFORMATION',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF475569)),
            ),
            const SizedBox(width: 12),
            Text(
              turf.contactPhone,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        if (turf.contactEmail != null && turf.contactEmail!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(Icons.mail_outline_rounded, size: 16, color: Color(0xFF475569)),
              ),
              const SizedBox(width: 12),
              Text(
                turf.contactEmail!,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        // Amenities
        const Text(
          'AMENITIES & FACILITIES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        if (turf.amenities.isEmpty)
          const Text('No amenities listed yet.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B)))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: turf.amenities
                .map((amenity) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF8FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFB9E6FE)),
                      ),
                      child: Text(
                        amenity.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }
}

class _CourtsTab extends StatelessWidget {
  const _CourtsTab({required this.turf});

  final Turf turf;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'COURTS LIST (${turf.courts.length})',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.0,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => context.go('/turfs/${turf.id}/courts/new'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Court', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (turf.courts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.sports_soccer_rounded, size: 36, color: Color(0xFF94A3B8)),
                const SizedBox(height: 8),
                const Text(
                  'No courts added yet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add individual courts to define sports, capacities, and pricing.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => context.go('/turfs/${turf.id}/courts/new'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Add your first court'),
                ),
              ],
            ),
          )
        else
          ...turf.courts.map(
            (court) => Column(
              children: [
                _CourtCard(turf: turf, court: court),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ],
            ),
          ),
      ],
    );
  }
}

class _MediaTab extends StatelessWidget {
  const _MediaTab({required this.turf});

  final Turf turf;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 90),
      children: [
        // 1. Cover Thumbnail Section
        _MediaSectionHeader(
          title: 'COVER THUMBNAIL',
          description: 'Main display photo shown in search results and venue directory.',
          count: turf.thumbnailMedia != null ? 1 : 0,
          maxCount: 1,
        ),
        const SizedBox(height: 10),
        TurfMediaSection(
          turfId: turf.id,
          media: turf.thumbnailMedia != null ? [turf.thumbnailMedia!] : const [],
          category: kMediaCategoryThumbnail,
          editable: turf.canEditMedia,
          singleSlot: true,
        ),

        const SizedBox(height: 24),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 24),

        // 2. Public Gallery Photos Section
        _MediaSectionHeader(
          title: 'GALLERY PHOTOS',
          description: 'Showcase courts, lighting, seating, and facilities to customers.',
          count: turf.galleryMedia.length,
        ),
        const SizedBox(height: 10),
        TurfMediaSection(
          turfId: turf.id,
          media: turf.galleryMedia,
          category: kMediaCategoryGallery,
          editable: turf.canEditMedia,
        ),

        const SizedBox(height: 24),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        const SizedBox(height: 24),

        // 3. Verification Documents Section
        _MediaSectionHeader(
          title: 'VERIFICATION DOCUMENTS',
          description: 'Internal documentation for admin operations and facility approval (private).',
          count: turf.reviewMedia.length,
        ),
        const SizedBox(height: 10),
        TurfMediaSection(
          turfId: turf.id,
          media: turf.reviewMedia,
          category: kMediaCategoryReview,
          editable: turf.canEditMedia,
        ),
      ],
    );
  }
}

class _MediaSectionHeader extends StatelessWidget {
  const _MediaSectionHeader({
    required this.title,
    required this.description,
    required this.count,
    this.maxCount,
  });

  final String title;
  final String description;
  final int count;
  final int? maxCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                maxCount != null ? '$count / $maxCount' : '$count Uploaded',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _CourtCard extends StatelessWidget {
  const _CourtCard({required this.turf, required this.court});

  final Turf turf;
  final Court court;

  void _showCourtDetailsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ListView(
                controller: scrollController,
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Court Header with Edit button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          court.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      StatusBadge(
                        label: court.isActive ? 'ACTIVE' : 'INACTIVE',
                        tone: court.isActive ? StatusTone.success : StatusTone.neutral,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Attributes Badges (Type, Surface, Environment)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SheetChip(
                        icon: Icons.roofing_rounded,
                        label: court.isIndoor ? 'Indoor Court' : 'Outdoor Court',
                      ),
                      if (court.surfaceType != null && court.surfaceType!.isNotEmpty)
                        _SheetChip(
                          icon: Icons.grass_rounded,
                          label: court.surfaceType!,
                        ),
                      if (court.capacity != null && court.capacity! > 0)
                        _SheetChip(
                          icon: Icons.groups_outlined,
                          label: 'Capacity: ${court.capacity} Players',
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 20),

                  // Description
                  if (court.description != null && court.description!.isNotEmpty) ...[
                    const Text(
                      'COURT DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      court.description!,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Supported Sports
                  const Text(
                    'SUPPORTED SPORTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (court.sports.isEmpty)
                    const Text('No sports assigned.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B)))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: court.sports
                          .map((sport) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF8FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFB9E6FE)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.sports_soccer_rounded, size: 14, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      sport.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 24),

                  // Amenities
                  if (court.amenities.isNotEmpty) ...[
                    const Text(
                      'COURT AMENITIES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: court.amenities
                          .map((amenity) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  amenity.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons (Edit Court)
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/turfs/${turf.id}/courts/${court.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(
                      'Edit Court Configurations',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCourtDetailsSheet(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF8FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB9E6FE)),
              ),
              child: const Icon(Icons.sports_soccer_rounded, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    court.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    court.sports.isEmpty
                        ? 'No sports assigned'
                        : court.sports.map((s) => s.name).join(', '),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            StatusBadge(
              label: court.isActive ? 'ACTIVE' : 'INACTIVE',
              tone: court.isActive ? StatusTone.success : StatusTone.neutral,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}

class _RejectionBanner extends StatelessWidget {
  const _RejectionBanner({required this.turf});

  final Turf turf;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
              SizedBox(width: 8),
              Text(
                'Submission Rejected',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF991B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            turf.rejectionReason ?? 'No reason provided.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D)),
          ),
        ],
      ),
    );
  }
}

class _ReviewStatusBanner extends StatelessWidget {
  const _ReviewStatusBanner({required this.turf});

  final Turf turf;

  @override
  Widget build(BuildContext context) {
    final isUnderReview = turf.approvalStatus == 'under_review';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isUnderReview
                  ? 'Your turf is under review by our operations team.'
                  : 'Your turf has been submitted and is awaiting review.',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingChangesBanner extends StatelessWidget {
  const _PendingChangesBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB9E6FE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This turf is still LIVE with your last-approved details. Your recent changes are awaiting review by the super admin.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF175CD3)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerStatefulWidget {
  const _ActionBar({required this.turf});

  final Turf turf;

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _isSubmitting = false;
  bool _isDeactivating = false;

  Future<void> _submit() async {
    final completeness = evaluateTurfCompleteness(widget.turf);
    if (!completeness.isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all required details before submitting for review.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref.read(turfRepositoryProvider).submitTurf(widget.turf.id);
      ref.invalidate(turfDetailProvider(widget.turf.id));
      ref.invalidate(turfListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turf submitted for review.')),
        );
      }
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deactivate() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Deactivate turf?',
      message: 'This turf will be marked inactive and hidden from listings.',
      confirmLabel: 'Deactivate',
      destructive: true,
    );
    if (!confirmed) return;
    setState(() => _isDeactivating = true);
    try {
      await ref.read(turfRepositoryProvider).deactivateTurf(widget.turf.id);
      ref.invalidate(turfListProvider);
      if (mounted) context.go('/turfs');
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isDeactivating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppButton(
            label: widget.turf.approvalStatus == 'rejected' ? 'Fix & Resubmit' : 'Submit for Review',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: OutlinedButton(
            onPressed: _isDeactivating ? null : _deactivate,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              backgroundColor: const Color(0xFFFEF2F2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _isDeactivating
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text(
                    'Deactivate',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                  ),
          ),
        ),
      ],
    );
  }
}
