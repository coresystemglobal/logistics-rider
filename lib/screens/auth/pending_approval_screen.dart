import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../services/rider_service.dart';
import '../../models/rider_model.dart';

final _pendingStatusProvider = StreamProvider.autoDispose<RiderModel?>((ref) async* {
  final riderService = RiderService();
  while (true) {
    try {
      final profile = await riderService.getProfile();
      yield profile;
    } catch (_) {
      yield null;
    }
    await Future.delayed(const Duration(seconds: 30));
  }
});

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen> {
  Timer? _redirectTimer;

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(_pendingStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: statusAsync.when(
            loading: () => _buildLoadingState(),
            error: (_, __) => _buildErrorState(),
            data: (profile) => profile != null ? _buildContent(profile) : _buildLoadingState(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.accent),
          const SizedBox(height: 16),
          Text('Loading status...', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textQuaternary),
          const SizedBox(height: 12),
          Text('Could not load status', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textTertiary)),
          TextButton(onPressed: () => ref.invalidate(_pendingStatusProvider), child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(RiderModel profile) {
    final status = profile.verificationStatus;
    final isVerified = status == 'VERIFIED';
    final isRejected = status == 'REJECTED';

    // Auto-redirect when verified
    if (isVerified) {
      _redirectTimer?.cancel();
      _redirectTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) context.go('/home');
      });
    }

    return Column(
      children: [
        const SizedBox(height: 48),
        // Icon
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: _getStatusColor(status).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 48),
        ),
        const SizedBox(height: 28),
        Text(
          _getTitle(status),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          _getMessage(status, profile),
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary, height: 1.6),
        ),
        const SizedBox(height: 40),

        // Checklist card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verification Steps',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              _buildCheckItem('Profile information', true, false),
              _buildCheckItem('Documents submitted', profile.licensePhoto != null || profile.vehiclePhoto != null, false),
              _buildCheckItem('Identity verification', status == 'VERIFIED', status == 'PENDING'),
              _buildCheckItem('Background check', status == 'VERIFIED', status == 'PENDING'),
              _buildCheckItem('Account activation', isVerified, false),
            ],
          ),
        ),
        const Spacer(),

        // Expected timeline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(_getStatusIcon(status), color: _getStatusColor(status), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _getTimelineMessage(status),
                  style: GoogleFonts.inter(fontSize: 13, color: _getStatusColor(status), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: isVerified
              ? ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Go to Home', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                )
              : OutlinedButton(
                  onPressed: () => context.go('/login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Back to Login', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCheckItem(String label, bool done, bool inProgress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.success.withValues(alpha: 0.12)
                  : inProgress
                      ? AppColors.warning.withValues(alpha: 0.12)
                      : AppColors.bgSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_rounded : inProgress ? Icons.hourglass_empty_rounded : Icons.radio_button_unchecked_rounded,
              color: done ? AppColors.success : inProgress ? AppColors.warning : AppColors.textQuaternary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: done ? AppColors.textPrimary : inProgress ? AppColors.warning : AppColors.textTertiary,
              fontWeight: done || inProgress ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
          if (inProgress) ...[
            const Spacer(),
            Text('In review', style: GoogleFonts.inter(fontSize: 11, color: AppColors.warning)),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'VERIFIED': return AppColors.success;
      case 'REJECTED': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'VERIFIED': return Icons.check_circle_rounded;
      case 'REJECTED': return Icons.cancel_rounded;
      default: return Icons.hourglass_top_rounded;
    }
  }

  String _getTitle(String status) {
    switch (status) {
      case 'VERIFIED': return 'Approved! 🎉';
      case 'REJECTED': return 'Application Declined';
      default: return 'Application Submitted!';
    }
  }

  String _getMessage(String status, RiderModel profile) {
    switch (status) {
      case 'VERIFIED':
        return 'Your rider account has been approved. You can now go online and start accepting jobs.';
      case 'REJECTED':
        return 'Unfortunately, your application was not approved. Please contact support for more details.';
      default:
        return 'Our team is reviewing your details. You\'ll get notified once approved — usually within 24–48 hours.';
    }
  }

  String _getTimelineMessage(String status) {
    switch (status) {
      case 'VERIFIED': return 'Approved — welcome to OPRIGHT!';
      case 'REJECTED': return 'Contact support to re-apply';
      default: return 'Expected approval: 1–2 business days';
    }
  }
}