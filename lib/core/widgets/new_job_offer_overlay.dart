import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../models/job_offer_model.dart';

class NewJobOfferOverlay extends StatefulWidget {
  final JobOfferModel offer;
  final Future<bool> Function() onAccept;
  final VoidCallback onIgnore;

  const NewJobOfferOverlay({
    super.key,
    required this.offer,
    required this.onAccept,
    required this.onIgnore,
  });

  @override
  State<NewJobOfferOverlay> createState() => _NewJobOfferOverlayState();
}

class _NewJobOfferOverlayState extends State<NewJobOfferOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideCtrl;
  late Timer _timer;
  int _secondsLeft = 30;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();

    final exp = widget.offer.expiresAt;
    if (exp != null) {
      _secondsLeft = exp.difference(DateTime.now()).inSeconds.clamp(0, 3600);
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft = (_secondsLeft - 1).clamp(0, 9999));
      if (_secondsLeft <= 0) {
        _timer.cancel();
        widget.onIgnore();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _slideCtrl.dispose();
    super.dispose();
  }

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  Future<void> _accept() async {
    if (_accepting) return;
    setState(() => _accepting = true);
    final ok = await widget.onAccept();
    if (!mounted) return;
    if (!ok) {
      setState(() => _accepting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer already expired. Try another job.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final urgent = _secondsLeft < 10;
    final fraction = (_secondsLeft / 30).clamp(0.0, 1.0);

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.55),
            child: GestureDetector(
              onTap: widget.onIgnore,
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut),
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  decoration: BoxDecoration(
                    color: AppColors.bgPrimary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33000000), blurRadius: 32, offset: Offset(0, 12)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with countdown
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.notification_add_rounded,
                                    size: 15, color: AppColors.accent),
                                const SizedBox(width: 5),
                                Text('New Job',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accent)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(_fmt(_secondsLeft),
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: urgent ? AppColors.error : AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: fraction,
                        backgroundColor: AppColors.bgSecondary,
                        color: urgent ? AppColors.error : AppColors.accent,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      const SizedBox(height: 16),

                      // Fee hero
                      Text('You earn',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.textTertiary)),
                      const SizedBox(height: 2),
                      Text('₦${offer.fee.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: AppColors.success)),
                      const SizedBox(height: 14),

                      // Route
                      _RouteRow(from: offer.pickupAddress, to: offer.dropoffAddress),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.separator, height: 1),
                      const SizedBox(height: 12),

                      // Meta pills
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _MetaPill(Icons.route_rounded, '${offer.distanceKm.toStringAsFixed(1)} km'),
                          _MetaPill(Icons.timer_rounded, '${offer.etaMinutes} min'),
                          _MetaPill(Icons.inventory_2_rounded, offer.packageSize),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _accepting ? null : widget.onIgnore,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: const BorderSide(color: AppColors.separator),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text('Ignore',
                                    style: GoogleFonts.inter(
                                        fontSize: 15, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _accepting ? null : _accept,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: _accepting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2.5))
                                    : Text('Accept',
                                        style: GoogleFonts.inter(
                                            fontSize: 16, fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                border: Border.all(color: AppColors.textPrimary, width: 2),
                shape: BoxShape.circle),
          ),
          Container(width: 1.5, height: 26, color: AppColors.separator),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          ),
        ]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(from,
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 18),
              Text(to,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaPill(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
