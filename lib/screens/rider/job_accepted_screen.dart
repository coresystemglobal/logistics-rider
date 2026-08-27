import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/package_model.dart';
import '../../services/package_service.dart';

class JobAcceptedScreen extends StatefulWidget {
  final String jobId;
  const JobAcceptedScreen({super.key, required this.jobId});
  @override
  State<JobAcceptedScreen> createState() => _JobAcceptedScreenState();
}

class _JobAcceptedScreenState extends State<JobAcceptedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  PackageModel? _package;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
    _loadPackage();
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) context.go('/delivery/${widget.jobId}');
    });
  }

  Future<void> _loadPackage() async {
    try {
      final pkg = await PackageService().getPackageById(widget.jobId);
      if (mounted) setState(() => _package = pkg);
    } catch (_) {}
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, color: AppColors.success, size: 56),
                  ),
                ),
                const SizedBox(height: 28),
                Text('Job Accepted!', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                Text('Head to the pickup location', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textSecondary)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.bgPrimary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ]),
                  child: Row(
                    children: [
                      Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.textPrimary, width: 2),
                              shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(
                        _package?.pickupAddress ?? 'Loading pickup address…',
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppColors.textPrimary),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/delivery/${widget.jobId}'),
                    icon: const Icon(Icons.navigation_rounded),
                    label: Text('Start Navigation', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent, foregroundColor: Colors.white, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const LinearProgressIndicator(value: null, color: AppColors.accent, backgroundColor: AppColors.bgSecondary),
                const SizedBox(height: 8),
                Text('Loading delivery details...', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
