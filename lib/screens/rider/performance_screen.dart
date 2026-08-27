import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const score = 94.0;
    final metrics = [
      const _Metric('Completion Rate', '97%', Icons.check_circle_outline_rounded, AppColors.success, 'Excellent'),
      const _Metric('Avg Rating', '4.9★', Icons.star_outline_rounded, AppColors.warning, 'Top 5%'),
      const _Metric('On-Time', '93%', Icons.schedule_rounded, AppColors.iosBlue, 'Good'),
      const _Metric('Acceptance', '88%', Icons.assignment_turned_in_rounded, AppColors.accent, 'Good'),
    ];
    final insights = [
      'Accept more jobs during peak hours (6–8 PM) to boost income',
      'Your on-time rate improved 4% this week — keep it up!',
      'Activate express delivery mode on Fridays for higher pay',
    ];

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        title: Text('Performance', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bgPrimary, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Score arc card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))]),
            child: Column(children: [
              const SizedBox(
                width: 180, height: 120,
                child: CustomPaint(painter: _ArcPainter(score: score)),
              ),
              const SizedBox(height: 8),
              Text('$score/100', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
              Text('Performance Score', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('Top Performer 🏆', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
              ),
            ]),
          ),
          const SizedBox(height: 14),

          // Metrics grid
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.4,
            children: metrics.map((m) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  Icon(m.icon, color: m.color, size: 18),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: m.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(m.badge, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: m.color)),
                  ),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  Text(m.label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textTertiary)),
                ]),
              ]),
            )).toList(),
          ),
          const SizedBox(height: 14),

          // Insights
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Insights', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 12),
                ...insights.map((insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(width: 6, height: 6, margin: const EdgeInsets.only(top: 6, right: 10),
                        decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
                    Expanded(child: Text(insight, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4))),
                  ]),
                )),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Metric { final String label, value, badge; final IconData icon; final Color color;
  const _Metric(this.label, this.value, this.icon, this.color, this.badge); }

class _ArcPainter extends CustomPainter {
  final double score;
  const _ArcPainter({required this.score});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.9);
    const radius = 80.0;
    final bgPaint = Paint()..color = AppColors.bgSecondary..strokeWidth = 14..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, math.pi, false, bgPaint);
    final fgPaint = Paint()
      ..shader = const LinearGradient(colors: [AppColors.success, AppColors.accent]).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 14..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, math.pi * (score / 100), false, fgPaint);
  }
  @override bool shouldRepaint(_ArcPainter old) => old.score != score;
}
