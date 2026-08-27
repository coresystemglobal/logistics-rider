import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/matching_service.dart';
import '../../services/rider_service.dart';

class JobDetailScreen extends StatefulWidget {
  final String jobId;
  const JobDetailScreen({super.key, required this.jobId});
  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  int _secondsLeft = 30; // matches DISPATCH_TIMEOUT
  Timer? _timer;
  bool _loading = false;
  Map<String, dynamic>? _job;
  String? _courierId;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, 9999));
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        if (mounted) context.pop();
      }
    });
  }

  Future<void> _loadData() async {
    try {
      final profile = await RiderService().getProfile();
      // Fetch the offer details from available jobs
      final jobs = await RiderService().getAvailableJobs();
      final job = jobs.firstWhere(
        (j) => j['id'] == widget.jobId || j['package_id'] == widget.jobId,
        orElse: () => {},
      );
      if (mounted) setState(() { _courierId = profile.id; _job = job; });
    } catch (_) {}
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _accept() async {
    if (_courierId == null || _courierId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resolve rider ID. Try again.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await MatchingService().acceptOffer(
        courierId: _courierId!,
        requestId: widget.jobId,
      );
      if (mounted) context.go('/job/${widget.jobId}/accepted');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${e.toString().replaceAll('Exception: ', '')}')));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _decline() async {
    if (_courierId != null && _courierId!.isNotEmpty) {
      try {
        await MatchingService().rejectOffer(
          courierId: _courierId!,
          requestId: widget.jobId,
        );
      } catch (_) {}
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final fraction = (_secondsLeft / 30).clamp(0.0, 1.0);
    final urgent = _secondsLeft < 10;
    final job = _job ?? {};
    final pay = (job['pay'] ?? job['price'] ?? job['total_amount'] ?? 0) as num;
    final dist = (job['distance_km'] ?? job['distance'] ?? 0) as num;
    final pickup = (job['pickup_address'] ?? job['from'] ?? 'Pickup location').toString();
    final dropoff = (job['delivery_address'] ?? job['to'] ?? 'Delivery location').toString();
    final size = (job['package_size'] ?? job['type'] ?? 'Standard').toString();

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.bgPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.close_rounded, size: 22), onPressed: () => context.pop()),
                  Expanded(child: Text('Job Offer', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
                  Text(
                    '${_secondsLeft ~/ 60}:${(_secondsLeft % 60).toString().padLeft(2, '0')}',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: urgent ? AppColors.error : AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            // Countdown bar
            LinearProgressIndicator(
              value: fraction,
              backgroundColor: AppColors.bgSecondary,
              color: urgent ? AppColors.error : AppColors.accent,
              minHeight: 4,
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Earnings hero
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF2DA844)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        children: [
                          Text('You earn', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
                          const SizedBox(height: 4),
                          Text('₦${pay.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _BreakdownItem('Distance', '${dist.toStringAsFixed(1)} km'),
                              _BreakdownItem('Size', size),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Route map placeholder
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 160,
                        decoration: const BoxDecoration(color: Color(0xFFE8E8EE)),
                        child: CustomPaint(painter: _MiniMapPainter()),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Route details card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          _DetailRow(icon: Icons.location_on_rounded, color: AppColors.textPrimary, label: 'Pickup', value: pickup),
                          const Divider(height: 20, color: AppColors.separator),
                          _DetailRow(icon: Icons.flag_rounded, color: AppColors.accent, label: 'Drop-off', value: dropoff),
                          const Divider(height: 20, color: AppColors.separator),
                          Row(
                            children: [
                              _InfoPill(Icons.route_rounded, '${dist.toStringAsFixed(1)} km'),
                              const SizedBox(width: 10),
                              _InfoPill(Icons.inventory_2_rounded, size),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        color: AppColors.bgPrimary,
        child: Row(
          children: [
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _loading ? null : _decline,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text('Decline', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _accept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text('Accept Job', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _BreakdownItem(String label, String value) {
  return Column(
    children: [
      Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
      Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
    ],
  );
}

Widget _DetailRow({required IconData icon, required Color color, required String label, required String value}) {
  return Row(
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
            Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ],
        ),
      ),
    ],
  );
}

Widget _InfoPill(IconData icon, String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
      ],
    ),
  );
}

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF0EEF2);
    canvas.drawRect(Offset.zero & size, bg);
    final road = Paint()..color = Colors.white..strokeWidth = 8..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), road);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.35, size.height), road);
    final route = Paint()..color = AppColors.accent..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.75)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.4, size.width * 0.8, size.height * 0.25);
    canvas.drawPath(path, route);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.75), 8, Paint()..color = AppColors.textPrimary);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.25), 10, Paint()..color = AppColors.accent);
  }
  @override bool shouldRepaint(_) => false;
}
