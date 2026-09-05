import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/wallet_service.dart';
import '../../services/dashboard_service.dart';
import '../../models/wallet_model.dart';
import '../../models/dashboard_model.dart';

final _walletProvider = FutureProvider.autoDispose<WalletModel>((_) => WalletService().getBalance());
final _dashboardProvider = FutureProvider.autoDispose<RiderDashboardModel>((_) => DashboardService().getRiderDashboard());
final _transactionsProvider = FutureProvider.autoDispose<List<WalletTransactionModel>>((_) => WalletService().getTransactions(limit: 5));

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(_walletProvider);
    final dashboardAsync = ref.watch(_dashboardProvider);
    final transactionsAsync = ref.watch(_transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true, backgroundColor: AppColors.bgPrimary, elevation: 0,
              scrolledUnderElevation: 0, automaticallyImplyLeading: false,
              title: Text('Earnings', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              actions: [
                TextButton(
                  onPressed: () => context.push('/withdrawal'),
                  child: Text('Withdraw', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.accent)),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Wallet balance
                    walletAsync.when(
                      loading: () => Container(height: 100, decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(16))),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (wallet) => Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFFF9500)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Available Balance', style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                            const SizedBox(height: 4),
                            Text('₦${wallet.balance.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                          ])),
                          GestureDetector(
                            onTap: () => context.push('/withdrawal'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                              child: Text('Withdraw', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats strip
                    dashboardAsync.when(
                      loading: () => Container(height: 80, decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(14))),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (dashboard) {
                        final avgPerJob = dashboard.totalDeliveries > 0
                            ? dashboard.totalEarnings / dashboard.totalDeliveries
                            : 0.0;
                        return Row(children: [
                          Expanded(child: _Stat('Deliveries', '${dashboard.totalDeliveries}', Icons.local_shipping_rounded, AppColors.iosBlue)),
                          const SizedBox(width: 10),
                          Expanded(child: _Stat('Avg / Job', '₦${avgPerJob.toStringAsFixed(0)}', Icons.trending_up_rounded, AppColors.success)),
                          const SizedBox(width: 10),
                          Expanded(child: _Stat('Today', '₦${dashboard.todayEarnings.toStringAsFixed(0)}', Icons.today_rounded, AppColors.warning)),
                        ]);
                      },
                    ),
                    const SizedBox(height: 20),

                    // Recent transactions header
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Recent', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      GestureDetector(
                        onTap: () => context.push('/transactions'),
                        child: Text('See all', style: GoogleFonts.inter(fontSize: 14, color: AppColors.iosBlue)),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    transactionsAsync.when(
                      loading: () => Column(children: List.generate(3, (_) => Container(
                        height: 64, margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(12)),
                      ))),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (txns) => txns.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text('No transactions yet', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary)),
                            )
                          : Column(children: txns.map((t) => _TransactionRow(t: t)).toList()),
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
}

Widget _Stat(String label, String value, IconData icon, Color color) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 6),
      Text(value, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
    ]),
  );
}

class _TransactionRow extends StatelessWidget {
  final WalletTransactionModel t;
  const _TransactionRow({required this.t});

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return 'Yesterday, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))]),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: (t.isCredit ? AppColors.success : AppColors.error).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(t.isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: t.isCredit ? AppColors.success : AppColors.error, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.description ?? (t.isCredit ? 'Delivery Earnings' : 'Withdrawal'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          Text(_formatDate(t.createdAt), style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
        ])),
        Text('${t.isCredit ? '+' : '-'}₦${t.amount.toStringAsFixed(0)}',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
                color: t.isCredit ? AppColors.success : AppColors.textPrimary)),
      ]),
    );
  }
}
