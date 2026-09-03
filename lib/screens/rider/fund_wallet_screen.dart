import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/payment_webview_screen.dart';
import '../../services/wallet_service.dart';

final _riderFundProvider =
    StateNotifierProvider.autoDispose<_RiderFundNotifier, _RiderFundState>(
  (_) => _RiderFundNotifier(),
);

class _RiderFundState {
  final double amount;
  final bool loading;
  final String? error;

  const _RiderFundState({
    this.amount = 2000,
    this.loading = false,
    this.error,
  });

  _RiderFundState copyWith({double? amount, bool? loading, String? error}) =>
      _RiderFundState(
        amount: amount ?? this.amount,
        loading: loading ?? this.loading,
        error: error ?? this.error,
      );
}

class _RiderFundNotifier extends StateNotifier<_RiderFundState> {
  _RiderFundNotifier() : super(const _RiderFundState());

  void setAmount(double v) => state = state.copyWith(amount: v, error: null);

  Future<String?> getCheckoutUrl() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final result = await WalletService().initializeFunding(
        amount: state.amount,
        provider: 'paystack',
      );
      state = state.copyWith(loading: false);
      final payment = result['payment'] as Map<String, dynamic>?;
      return payment?['checkout_url'] as String? ??
          payment?['authorization_url'] as String?;
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }
}

class RiderFundWalletScreen extends ConsumerStatefulWidget {
  const RiderFundWalletScreen({super.key});

  @override
  ConsumerState<RiderFundWalletScreen> createState() =>
      _RiderFundWalletScreenState();
}

class _RiderFundWalletScreenState
    extends ConsumerState<RiderFundWalletScreen> {
  final _amountCtrl = TextEditingController(text: '2000');

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _proceed() async {
    final notifier = ref.read(_riderFundProvider.notifier);
    final url = await notifier.getCheckoutUrl();
    if (url == null || !mounted) return;

    final result = await PaymentWebViewScreen.show(
      context,
      checkoutUrl: url,
      callbackUrlPrefix: 'https://api.opright.org/api/wallet/fund/verify',
      title: 'Fund Wallet',
    );

    if (!mounted) return;

    switch (result) {
      case PaymentResult.success:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Your wallet will be credited shortly.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      case PaymentResult.failed:
        ref.read(_riderFundProvider.notifier).state =
            ref.read(_riderFundProvider).copyWith(
              error: 'Payment was not completed. Please try again.',
            );
      case PaymentResult.cancelled:
        break;
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_riderFundProvider);
    final notifier = ref.read(_riderFundProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Fund Wallet',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16, 24, 16, MediaQuery.of(context).padding.bottom + 120),
          child: Column(
            children: [
              // Amount input
              Text('Enter Amount',
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0x4DFF6B00), width: 2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('₦',
                        style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(width: 4),
                    IntrinsicWidth(
                      child: TextField(
                        autocorrect: false,
                        enableSuggestions: false,
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                        ),
                        onChanged: (v) =>
                            notifier.setAmount(double.tryParse(v) ?? 0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [500, 1000, 2000, 5000, 10000].map((amt) {
                    final isSelected = state.amount == amt.toDouble();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          _amountCtrl.text = amt.toString();
                          notifier.setAmount(amt.toDouble());
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentLight
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.separator,
                            ),
                          ),
                          child: Text(
                            '₦${_fmt(amt)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),

              // Payment method tile
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card_rounded,
                        color: AppColors.accent, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Card / Bank Transfer / USSD',
                              style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary)),
                          Text('Powered by Paystack · All methods accepted',
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textTertiary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (state.error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(state.error!,
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.error)),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary.withValues(alpha: 0.95),
          border: Border(
              top: BorderSide(
                  color: AppColors.separator.withValues(alpha: 0.4))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: state.loading ? null : _proceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: state.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        'Fund ₦${_fmt(state.amount.toInt())}',
                        style: GoogleFonts.inter(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_rounded,
                    size: 14, color: AppColors.textQuaternary),
                const SizedBox(width: 4),
                Text('Secured · CBN licensed',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textQuaternary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int amt) {
    if (amt < 1000) return amt.toString();
    final s = amt.toString();
    final buf = StringBuffer();
    var count = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(s[i]);
      count++;
    }
    return buf.toString().split('').reversed.join();
  }
}
