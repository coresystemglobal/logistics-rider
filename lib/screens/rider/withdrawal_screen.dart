import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/wallet_service.dart';
import '../../models/wallet_model.dart';

final _balanceProvider = FutureProvider.autoDispose<WalletModel>((_) => WalletService().getBalance());
final _bankAccountProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (_) => WalletService().getBankAccount(),
);

class WithdrawalScreen extends ConsumerStatefulWidget {
  const WithdrawalScreen({super.key});
  @override ConsumerState<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends ConsumerState<WithdrawalScreen> {
  final _amountCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() { _amountCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await WalletService().requestPayout(amount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal initiated successfully'), backgroundColor: AppColors.success),
        );
        ref.invalidate(_balanceProvider);
        context.pop();
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(_balanceProvider);
    final bankAsync = ref.watch(_bankAccountProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        title: Text('Withdraw Earnings', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bgPrimary, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance card
            balanceAsync.when(
              loading: () => Container(height: 80, decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(16))),
              error: (_, __) => const SizedBox.shrink(),
              data: (w) => Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.separator.withValues(alpha: 0.5)),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Available to withdraw', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
                    Text('₦${w.balance.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ])),
                  const Icon(Icons.account_balance_wallet_rounded, color: AppColors.accent, size: 32),
                ]),
              ),
            ),
            const SizedBox(height: 20),

            // Amount input
            Text('Amount to withdraw', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.separator.withValues(alpha: 0.5)),
              ),
              child: Row(children: [
                Text('₦', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(width: 4),
                Expanded(child: TextField(
                  autocorrect: false, enableSuggestions: false,
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero, hintText: '0'),
                  onChanged: (_) => setState(() => _error = null),
                )),
              ]),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [5000, 10000, 20000, 50000].map((amt) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() { _amountCtrl.text = amt.toString(); _error = null; }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.separator)),
                      child: Text('₦${amt ~/ 1000}k', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Bank account
            Text('Withdraw to', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            bankAsync.when(
              loading: () => Container(height: 64, decoration: BoxDecoration(color: AppColors.bgTertiary, borderRadius: BorderRadius.circular(12))),
              error: (_, __) => _NoBankCard(onTap: () => context.push('/payout-settings')),
              data: (bank) {
                final hasBank = bank['account_number'] != null && (bank['account_number'] as String).isNotEmpty;
                if (!hasBank) return _NoBankCard(onTap: () => context.push('/payout-settings'));
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent, width: 1.5),
                  ),
                  child: Row(children: [
                    const Icon(Icons.account_balance_rounded, color: AppColors.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(bank['bank_name'] ?? '', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('${bank['account_name'] ?? ''} · ${bank['account_number'] ?? ''}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    ])),
                    GestureDetector(
                      onTap: () => context.push('/payout-settings'),
                      child: Text('Change', style: GoogleFonts.inter(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                );
              },
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Text(_error!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.error)),
              ),
            ],
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text('Processing time: 2–5 minutes', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
            ]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        color: AppColors.bgPrimary,
        child: SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent, foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('Withdraw', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

class _NoBankCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NoBankCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.separator),
        ),
        child: Row(children: [
          const Icon(Icons.account_balance_rounded, color: AppColors.textQuaternary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text('No bank account saved', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary))),
          Text('Add now', style: GoogleFonts.inter(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
