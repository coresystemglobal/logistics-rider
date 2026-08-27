import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/wallet_service.dart';
import '../../models/wallet_model.dart';

final _walletProvider = FutureProvider.autoDispose<WalletModel>((_) => WalletService().getBalance());

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});
  @override ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  String _period = 'Week';

  static const _barData = [2800.0, 4200.0, 1500.0, 5600.0, 3200.0, 4800.0, 2100.0];
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(_walletProvider);
    final total = _barData.reduce((a, b) => a + b);

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

                    // Period selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: ['Today', 'Week', 'Month'].map((p) {
                          final active = _period == p;
                          return Expanded(child: GestureDetector(
                            onTap: () => setState(() => _period = p),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: active ? AppColors.accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(p, textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: active ? Colors.white : AppColors.textTertiary)),
                            ),
                          ));
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Earnings hero
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('This $_period', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
                          const SizedBox(height: 4),
                          Text('₦${total.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          const SizedBox(height: 20),
                          // Bar chart
                          SizedBox(
                            height: 120,
                            child: BarChart(BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _barData.reduce((a, b) => a > b ? a : b) * 1.2,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= _days.length) return const SizedBox.shrink();
                                  return Text(_days[i], style: GoogleFonts.inter(fontSize: 11, color: AppColors.textQuaternary));
                                })),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: List.generate(_barData.length, (i) => BarChartGroupData(
                                x: i,
                                barRods: [BarChartRodData(
                                  toY: _barData[i],
                                  color: i == 3 ? AppColors.accent : AppColors.accent.withValues(alpha: 0.35),
                                  width: 20, borderRadius: BorderRadius.circular(6),
                                )],
                              )),
                            )),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Stats strip
                    Row(children: [
                      Expanded(child: _Stat('Deliveries', '14', Icons.local_shipping_rounded, AppColors.iosBlue)),
                      const SizedBox(width: 10),
                      Expanded(child: _Stat('Avg / Job', '₦1,700', Icons.trending_up_rounded, AppColors.success)),
                      const SizedBox(width: 10),
                      Expanded(child: _Stat('Online Hrs', '6.5h', Icons.schedule_rounded, AppColors.warning)),
                    ]),
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
                    ..._sampleTransactions.map((t) => _TransactionRow(t: t)),
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

  static const _sampleTransactions = [
    _Txn('Delivery #TRK-8829', '+₦2,800', 'Today, 2:34 PM', true),
    _Txn('Delivery #TRK-7712', '+₦1,900', 'Today, 10:15 AM', true),
    _Txn('Withdrawal', '-₦5,000', 'Yesterday, 3:00 PM', false),
  ];
}

class _Txn {
  final String title, amount, date;
  final bool isCredit;
  const _Txn(this.title, this.amount, this.date, this.isCredit);
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
  final _Txn t;
  const _TransactionRow({required this.t});
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
          Text(t.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          Text(t.date, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
        ])),
        Text(t.amount, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
            color: t.isCredit ? AppColors.success : AppColors.textPrimary)),
      ]),
    );
  }
}
