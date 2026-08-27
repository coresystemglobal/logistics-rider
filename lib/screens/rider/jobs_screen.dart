import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../services/rider_service.dart';

final _jobsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (_) => RiderService().getAvailableJobs(),
);
final _filterProvider = StateProvider.autoDispose<String>((_) => 'all');

class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(_jobsProvider);
    final filter = ref.watch(_filterProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppColors.bgPrimary,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Available Jobs', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary))),
                      IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.accent), onPressed: () => ref.invalidate(_jobsProvider)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Chip('All', 'all', filter, () => ref.read(_filterProvider.notifier).state = 'all'),
                        const SizedBox(width: 8),
                        _Chip('Nearest', 'nearest', filter, () => ref.read(_filterProvider.notifier).state = 'nearest'),
                        const SizedBox(width: 8),
                        _Chip('Highest Pay', 'highest', filter, () => ref.read(_filterProvider.notifier).state = 'highest'),
                        const SizedBox(width: 8),
                        _Chip('Expiring Soon', 'expiring', filter, () => ref.read(_filterProvider.notifier).state = 'expiring'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: jobsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
                error: (err, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textQuaternary),
                  const SizedBox(height: 12),
                  Text('Could not load jobs', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textTertiary)),
                  TextButton(onPressed: () => ref.invalidate(_jobsProvider), child: const Text('Retry')),
                ])),
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 80, height: 80, decoration: const BoxDecoration(color: AppColors.bgSecondary, shape: BoxShape.circle),
                          child: const Icon(Icons.assignment_outlined, size: 40, color: AppColors.textQuaternary)),
                      const SizedBox(height: 16),
                      Text('No jobs right now', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Text('Stay online — jobs appear here', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
                    ]));
                  }
                  var sorted = List<Map<String, dynamic>>.from(jobs);
                  if (filter == 'highest') {
                    sorted.sort((a, b) => ((b['pay'] ?? b['price'] ?? 0) as num).compareTo((a['pay'] ?? a['price'] ?? 0) as num));
                  } else if (filter == 'nearest') {
                    sorted.sort((a, b) => ((a['distance_km'] ?? 999) as num).compareTo((b['distance_km'] ?? 999) as num));
                  }
                  return RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: () async => ref.invalidate(_jobsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: sorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _JobCard(job: sorted[i], onTap: () => context.push('/job/${sorted[i]['id'] ?? i}')),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _Chip(String label, String value, String current, VoidCallback onTap) {
  final isActive = value == current;
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isActive ? AppColors.accent : AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? AppColors.accent : AppColors.separator),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: isActive ? FontWeight.w600 : FontWeight.w400, color: isActive ? Colors.white : AppColors.textSecondary)),
    ),
  );
}

class _JobCard extends StatefulWidget {
  final Map<String, dynamic> job;
  final VoidCallback onTap;
  const _JobCard({required this.job, required this.onTap});
  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  Timer? _timer;
  int _secondsLeft = 180;

  @override
  void initState() {
    super.initState();
    final exp = DateTime.tryParse((widget.job['expires_at'] ?? widget.job['expiresAt'] ?? '').toString());
    if (exp != null) _secondsLeft = exp.difference(DateTime.now()).inSeconds.clamp(0, 3600);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, 9999));
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final pay = (job['pay'] ?? job['price'] ?? job['total_price'] ?? 0) as num;
    final dist = (job['distance_km'] ?? job['distance'] ?? 0) as num;
    final pickup = (job['pickup_address'] ?? job['from'] ?? 'Pickup').toString();
    final dropoff = (job['delivery_address'] ?? job['to'] ?? 'Delivery').toString();
    final type = job['package_type'] ?? job['type'] ?? 'Standard';
    final urgent = _secondsLeft < 120;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(16),
          border: urgent ? Border.all(color: AppColors.error.withValues(alpha: 0.4)) : null,
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('₦${pay.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.success)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.toString(), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Row(children: [
                        const Icon(Icons.route_rounded, size: 14, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Text('${dist.toStringAsFixed(1)} km', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
                      ]),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: urgent ? AppColors.error.withValues(alpha: 0.1) : AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_fmt(_secondsLeft), style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: urgent ? AppColors.error : AppColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.separator, height: 1),
            const SizedBox(height: 10),
            _RouteRow(from: pickup, to: dropoff),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String from, to;
  const _RouteRow({required this.from, required this.to});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(border: Border.all(color: AppColors.textPrimary, width: 2), shape: BoxShape.circle)),
          Container(width: 1.5, height: 24, color: AppColors.separator),
          Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)),
        ]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(from, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              Text(to, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}
