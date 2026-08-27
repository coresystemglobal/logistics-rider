import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  static const _groups = [
    _Group('Today', [
      _Txn('Delivery #TRK-8829', '+₦2,800', '2:34 PM', 'earning'),
      _Txn('Delivery #TRK-7712', '+₦1,900', '10:15 AM', 'earning'),
    ]),
    _Group('Yesterday', [
      _Txn('Withdrawal', '-₦5,000', '3:00 PM', 'withdrawal'),
      _Txn('Delivery #TRK-6621', '+₦3,500', '11:00 AM', 'earning'),
      _Txn('Express Bonus', '+₦500', '8:30 AM', 'bonus'),
    ]),
    _Group('Jun 1', [
      _Txn('Delivery #TRK-5510', '+₦2,100', '6:00 PM', 'earning'),
      _Txn('Withdrawal', '-₦10,000', '9:00 AM', 'withdrawal'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        title: Text('Transactions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bgPrimary, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _groups.map((g) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(g.label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textTertiary)),
            ),
            ...g.items.map((t) => _TxnRow(t: t)),
          ],
        )).toList(),
      ),
    );
  }
}

class _Group { final String label; final List<_Txn> items; const _Group(this.label, this.items); }
class _Txn { final String title, amount, time, type; const _Txn(this.title, this.amount, this.time, this.type); }

class _TxnRow extends StatelessWidget {
  final _Txn t;
  const _TxnRow({required this.t});

  Color get _iconColor => t.type == 'earning' ? AppColors.success : t.type == 'bonus' ? const Color(0xFFFFCC00) : AppColors.warning;
  IconData get _icon => t.type == 'earning' ? Icons.local_shipping_rounded : t.type == 'bonus' ? Icons.star_rounded : Icons.account_balance_rounded;

  @override
  Widget build(BuildContext context) {
    final isCredit = t.amount.startsWith('+');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))]),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: _iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(_icon, color: _iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          Text(t.time, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
        ])),
        Text(t.amount, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
            color: isCredit ? AppColors.success : AppColors.textPrimary)),
      ]),
    );
  }
}
