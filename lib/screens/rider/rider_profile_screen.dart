import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/rider_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/rider_service.dart';

final _riderProfileProvider = FutureProvider.autoDispose<RiderModel>(
  (_) => RiderService().getProfile(),
);

class RiderProfileScreen extends ConsumerWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final profileAsync = ref.watch(_riderProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true, backgroundColor: AppColors.bgPrimary, elevation: 0,
              scrolledUnderElevation: 0, automaticallyImplyLeading: false,
              title: Text('Profile', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                  onPressed: () => ref.invalidate(_riderProfileProvider),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Avatar + info card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))]),
                      child: profileAsync.when(
                        loading: () => const Center(child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                        )),
                        error: (_, __) => Center(child: Text('Could not load profile',
                            style: GoogleFonts.inter(color: AppColors.textTertiary))),
                        data: (profile) => Column(children: [
                          Stack(children: [
                            Container(
                              width: 80, height: 80,
                              decoration: const BoxDecoration(color: AppColors.accentLight, shape: BoxShape.circle),
                              child: const Icon(Icons.person_rounded, size: 44, color: AppColors.accent),
                            ),
                            Positioned(bottom: 0, right: 0,
                              child: Container(
                                width: 26, height: 26,
                                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                              )),
                          ]),
                          const SizedBox(height: 14),
                          Text(user?.fullName ?? 'Rider', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text('ID: ${profile.uniqueId.isNotEmpty ? profile.uniqueId : '—'}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
                          const SizedBox(height: 16),
                          // Rating badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                profile.rating != null ? profile.rating!.toStringAsFixed(1) : '—',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 4),
                              Text('rating', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
                            ]),
                          ),
                          const SizedBox(height: 16),
                          // Stats strip
                          Row(children: [
                            _StatItem('${profile.totalDeliveries ?? 0}', 'Deliveries'),
                            _StatItem(_vehicleLabel(profile.vehicleType), 'Vehicle'),
                            _StatItem(profile.status, 'Status'),
                          ]),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _Section('Account', [
                      _SettingRow(Icons.edit_rounded, 'Edit Profile', () => context.push('/edit-profile')),
                      _SettingRow(Icons.lock_rounded, 'Change Password', () => context.push('/change-password')),
                    ]),
                    const SizedBox(height: 12),
                    _Section('Vehicle & Documents', [
                      _SettingRow(Icons.motorcycle_rounded, 'Vehicle Details', () => context.push('/vehicle-docs')),
                      _SettingRow(Icons.description_rounded, 'My Documents', () => context.push('/vehicle-docs')),
                    ]),
                    const SizedBox(height: 12),
                    _Section('Performance', [
                      _SettingRow(Icons.bar_chart_rounded, 'Performance Stats', () => context.push('/performance')),
                    ]),
                    const SizedBox(height: 12),
                    _Section('Payments', [
                      _SettingRow(Icons.account_balance_wallet_rounded, 'Earnings & Wallet', () => context.go('/earnings')),
                    ]),
                    const SizedBox(height: 12),
                    _Section('Support', [
                      _SettingRow(Icons.help_rounded, 'Help & Support', () => context.push('/help')),
                      _SettingRow(Icons.policy_rounded, 'Terms & Privacy', () {}),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(14)),
                      child: _SettingRow(Icons.logout_rounded, 'Sign Out', () => ref.read(authProvider.notifier).logout(), color: AppColors.error),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _vehicleLabel(String type) {
    switch (type.toUpperCase()) {
      case 'MOTORCYCLE': return 'Moto';
      case 'BICYCLE': return 'Bicycle';
      case 'VAN': return 'Van';
      case 'CAR': return 'Car';
      default: return type;
    }
  }
}

Widget _StatItem(String value, String label) {
  return Expanded(child: Column(children: [
    Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
    Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
  ]));
}

Widget _Section(String title, List<Widget> items) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textTertiary))),
      Container(
        decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(14)),
        child: Column(children: items),
      ),
    ],
  );
}

Widget _SettingRow(IconData icon, String label, VoidCallback onTap, {Color? color}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 20, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 15, color: color ?? AppColors.textPrimary))),
        Icon(Icons.chevron_right_rounded, size: 18, color: color ?? AppColors.textQuaternary),
      ]),
    ),
  );
}
