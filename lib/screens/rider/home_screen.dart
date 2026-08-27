import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/rider_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/real_time_service.dart';
import '../../models/dashboard_model.dart';

enum _OnlineState { offline, activating, online }

final _dashboardProvider = FutureProvider.autoDispose<RiderDashboardModel>(
  (_) => DashboardService().getRiderDashboard(),
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  _OnlineState _onlineState = _OnlineState.offline;
  late final AnimationController _sonarCtrl;
  Timer? _activationTimer;

  @override
  void initState() {
    super.initState();
    _sonarCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _sonarCtrl.dispose();
    _activationTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleOnline() async {
    if (_onlineState == _OnlineState.offline) {
      setState(() => _onlineState = _OnlineState.activating);
      _activationTimer = Timer(const Duration(milliseconds: 1600), () async {
        final success = await _updateStatus(true);
        if (mounted) setState(() => _onlineState = success ? _OnlineState.online : _OnlineState.offline);
      });
    } else if (_onlineState == _OnlineState.online) {
      setState(() => _onlineState = _OnlineState.offline);
      await _updateStatus(false);
    }
  }

  Future<bool> _updateStatus(bool online) async {
    try {
      await RiderService().updateStatus(online ? 'AVAILABLE' : 'OFFLINE');
      await RiderService().updateAvailability(online);

      if (online) {
        final profile = await RiderService().getProfile();
        await RiderService().updateCourierLocation(
          courierId: profile.id,
          latitude: 6.4281,
          longitude: 3.4219,
          vehicleType: profile.vehicleType,
        );
        await RiderService().updateCourierStatus(
          courierId: profile.id,
          status: 'AVAILABLE',
        );

        // Connect to real-time offers for this rider
        final realTime = RealTimeService.instance;
        await realTime.connect();
        realTime.joinRider(profile.id);
      } else {
        final profile = await RiderService().getProfile();
        await RiderService().updateCourierStatus(
          courierId: profile.id,
          status: 'OFFLINE',
        );
        RealTimeService.instance.leaveRider(profile.id);
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status update failed: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: AppColors.error),
        );
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final dashboardAsync = ref.watch(_dashboardProvider);
    final isOnline = _onlineState == _OnlineState.online;
    final isActivating = _onlineState == _OnlineState.activating;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.bgPrimary,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Good ${_greeting()},',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
                              Text(user?.firstName ?? 'Rider',
                                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_rounded, color: AppColors.textSecondary),
                          onPressed: () => context.push('/notifications'),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Online toggle hero
                        _OnlineToggleCard(
                          state: _onlineState,
                          sonarCtrl: _sonarCtrl,
                          onToggle: _toggleOnline,
                        ),
                        const SizedBox(height: 16),

                        // Stats strip
                        dashboardAsync.when(
                          loading: () => const _StatsShimmer(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (dash) => _StatsStrip(dashboard: dash),
                        ),
                        const SizedBox(height: 16),

                        // Quick actions when online
                        if (isOnline) ...[
                          GestureDetector(
                            onTap: () => context.go('/jobs'),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.accent, Color(0xFFFF9500)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.assignment_rounded, color: Colors.white, size: 28),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('View Available Jobs',
                                            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                                        Text('Jobs are waiting for you nearby',
                                            style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Earnings preview card
                        dashboardAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (dash) => _EarningsPreview(dashboard: dash),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Activating overlay
          if (isActivating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _sonarCtrl,
                        builder: (_, __) => Stack(
                          alignment: Alignment.center,
                          children: List.generate(3, (i) {
                            final scale = 1.0 + (i + 1) * 0.4 * _sonarCtrl.value;
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.success.withValues(alpha: (1 - _sonarCtrl.value) * 0.6),
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Icon(Icons.location_on_rounded, color: AppColors.success, size: 44),
                      const SizedBox(height: 20),
                      Text("Going Online...",
                          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _OnlineToggleCard extends StatelessWidget {
  final _OnlineState state;
  final AnimationController sonarCtrl;
  final VoidCallback onToggle;

  const _OnlineToggleCard({required this.state, required this.sonarCtrl, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isOnline = state == _OnlineState.online;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.textQuaternary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'You\'re Online' : 'You\'re Offline',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isOnline ? AppColors.success : AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.success.withValues(alpha: 0.1) : AppColors.accent,
                borderRadius: BorderRadius.circular(16),
                border: isOnline ? Border.all(color: AppColors.success, width: 1.5) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOnline ? Icons.power_settings_new_rounded : Icons.play_arrow_rounded,
                    color: isOnline ? AppColors.success : Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isOnline ? 'Go Offline' : 'Go Online',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isOnline ? AppColors.success : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isOnline) ...[
            const SizedBox(height: 12),
            Text('Toggle to start receiving jobs',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
          ],
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final RiderDashboardModel dashboard;
  const _StatsStrip({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatChip(label: 'Today', value: '${dashboard.activeDeliveries}', sub: 'deliveries')),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(label: 'Earned', value: '₦${(dashboard.todayEarnings).toStringAsFixed(0)}', sub: 'today')),
        const SizedBox(width: 10),
        Expanded(child: _StatChip(label: 'Rating', value: dashboard.rating.toStringAsFixed(1), sub: '★', valueColor: AppColors.warning)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value, sub;
  final Color? valueColor;
  const _StatChip({required this.label, required this.value, required this.sub, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: valueColor ?? AppColors.textPrimary)),
          Text(sub, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textQuaternary)),
        ],
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) => Expanded(
        child: Container(
          margin: EdgeInsets.only(left: i > 0 ? 10 : 0),
          height: 72,
          decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(14)),
        ),
      )),
    );
  }
}

class _EarningsPreview extends StatelessWidget {
  final RiderDashboardModel dashboard;
  const _EarningsPreview({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Earnings', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
                const SizedBox(height: 4),
                Text('₦${dashboard.totalEarnings.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Text('${dashboard.totalDeliveries} deliveries completed',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.go('/earnings'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('View', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent)),
            ),
          ),
        ],
      ),
    );
  }
}
