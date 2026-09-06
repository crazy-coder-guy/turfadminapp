import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign out of admin portal?',
      message: 'You will need to sign in again to access turf bookings and business settings.',
      confirmLabel: 'Sign out',
      destructive: true,
    );
    if (confirmed) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(authControllerProvider).owner;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Account & Settings',
          style: TextStyle(
            color: Color(0xFF0F172A),
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
      body: owner == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 2.5,
                            ),
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: owner.profileImageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(
                                width: 80,
                                height: 80,
                                color: const Color(0xFFEFF8FF),
                                alignment: Alignment.center,
                                child: Text(
                                  owner.fullName.isNotEmpty ? owner.fullName[0].toUpperCase() : 'A',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          owner.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          owner.businessName,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: owner.status == 'active' ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: owner.status == 'active' ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: owner.status == 'active' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${owner.status.toUpperCase()} PARTNER',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: owner.status == 'active' ? const Color(0xFF047857) : const Color(0xFFB45309),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  const Text(
                    'BUSINESS DETAILS',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _ProfileRowItem(
                    icon: Icons.phone_outlined,
                    label: 'Mobile Number',
                    value: owner.phoneNumber,
                  ),
                  const Divider(height: 1, indent: 52, color: Color(0xFFF1F5F9)),
                  _ProfileRowItem(
                    icon: Icons.mail_outline_rounded,
                    label: 'Work Email',
                    value: owner.email,
                  ),
                  const Divider(height: 1, indent: 52, color: Color(0xFFF1F5F9)),
                  _ProfileRowItem(
                    icon: Icons.badge_outlined,
                    label: 'PAN Number',
                    value: owner.panNumber,
                  ),
                  if (owner.gstin != null && owner.gstin!.isNotEmpty) ...[
                    const Divider(height: 1, indent: 52, color: Color(0xFFF1F5F9)),
                    _ProfileRowItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'GSTIN',
                      value: owner.gstin!,
                    ),
                  ],
                  const SizedBox(height: 32),

                  const Text(
                    'VERIFICATION & DOCUMENTS',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  InkWell(
                    onTap: () => context.go('/profile/documents'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Icon(
                              Icons.folder_open_rounded,
                              color: Color(0xFF475569),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Business Documents',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 52, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 44),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _logout(context, ref),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        side: const BorderSide(color: Color(0xFFFCA5A5), width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFDC2626)),
                      label: const Text(
                        'Sign Out of Account',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'Turf Partner Admin v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ProfileRowItem extends StatelessWidget {
  const _ProfileRowItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, color: const Color(0xFF475569), size: 18),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
