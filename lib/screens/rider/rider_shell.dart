import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/new_job_offer_overlay.dart';
import '../../providers/job_offer_provider.dart';

class RiderShell extends ConsumerWidget {
  final Widget child;
  const RiderShell({super.key, required this.child});

  static const _tabs = [
    _Tab(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, route: '/home'),
    _Tab(label: 'Jobs', icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, route: '/jobs'),
    _Tab(label: 'Earnings', icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, route: '/earnings'),
    _Tab(label: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, route: '/profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final offer = ref.watch(jobOfferProvider).offer;
    final notifier = ref.read(jobOfferProvider.notifier);

    // Race-free hand-off: navigate to the active delivery once the backend confirms it
    ref.listen<String?>(
      jobOfferProvider.select((s) => s.assignedPackageId),
      (prev, next) {
        if (next == null || next.isEmpty) return;
        notifier.clearAssigned();
        context.push('/delivery/$next');
      },
    );

    return Scaffold(
      body: Stack(
        children: [
          child,
          if (offer != null)
            NewJobOfferOverlay(
              key: ValueKey(offer.requestId),
              offer: offer,
              onAccept: notifier.accept,
              onIgnore: notifier.ignore,
            ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80 + MediaQuery.of(context).padding.bottom,
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          border: Border(top: BorderSide(color: AppColors.separator.withValues(alpha: 0.5))),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            children: _tabs.map((tab) {
              final isActive = location.startsWith(tab.route);
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.go(tab.route),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? tab.activeIcon : tab.icon,
                        color: isActive ? AppColors.accent : AppColors.textQuaternary,
                        size: 26,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive ? AppColors.accent : AppColors.textQuaternary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _Tab({required this.label, required this.icon, required this.activeIcon, required this.route});
}
