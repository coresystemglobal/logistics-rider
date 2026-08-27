import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 48),
              ),
              const SizedBox(height: 28),
              Text(
                'Application Submitted!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                'Our team is reviewing your details. You\'ll get an email once approved — usually within 24–48 hours.',
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
                    const _CheckItem(label: 'Profile information', done: true),
                    const _CheckItem(label: 'Documents submitted', done: true),
                    const _CheckItem(label: 'Identity verification', done: false, inProgress: true),
                    const _CheckItem(label: 'Background check', done: false),
                    const _CheckItem(label: 'Account activation', done: false),
                  ],
                ),
              ),
              const Spacer(),

              // Expected timeline
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: AppColors.accent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Expected approval: 1–2 business days',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
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
          ),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final String label;
  final bool done;
  final bool inProgress;

  const _CheckItem({required this.label, required this.done, this.inProgress = false});

  @override
  Widget build(BuildContext context) {
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
}
