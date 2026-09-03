import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _expandedFaq = <int>{};

  static const _faqs = [
    _Faq('How do I get paid?', 'Earnings are added to your OPRIGHT wallet after each completed delivery. You can withdraw to your bank account anytime — processing takes 2–5 minutes.'),
    _Faq('What if the recipient is unavailable?', 'Wait at least 5 minutes, then call the recipient. If there\'s no response, contact OPRIGHT support before returning the package.'),
    _Faq('How are delivery fees calculated?', 'Fees are based on distance, package size, and delivery speed. Express and priority jobs pay a bonus on top of the base rate.'),
    _Faq('What happens if a package is damaged?', 'Report immediately through the app. Do not attempt to deliver a damaged package. OPRIGHT will guide you through the process.'),
    _Faq('How do I update my vehicle details?', 'Go to Profile → Vehicle & Documents to update your vehicle information and renew expired documents.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        title: Text('Help & Support', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bgPrimary, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 32),
        children: [
          // Emergency contacts first
          Text('Emergency Contacts', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _EmergencyCard('OPRIGHT Support', '24/7', Icons.headset_mic_rounded, AppColors.accent, () => launchUrl(Uri.parse('tel:+2349160714439')))),
            const SizedBox(width: 10),
            Expanded(child: _EmergencyCard('Emergency', '112', Icons.local_police_rounded, AppColors.error, () => launchUrl(Uri.parse('tel:112')))),
          ]),
          const SizedBox(height: 20),

          // Quick help
          Text('Quick Help', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.2,
            children: [
              _HelpTile(Icons.assignment_late_rounded, 'Report Issue', AppColors.warning, () {
                launchUrl(Uri.parse('mailto:support@opright.org?subject=Report%20Issue'));
              }),
              _HelpTile(Icons.route_rounded, 'Navigation Help', AppColors.iosBlue, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Use Google Maps or your preferred navigation app for directions.')));
              }),
              _HelpTile(Icons.account_balance_wallet_rounded, 'Payment Issue', AppColors.success, () {
                launchUrl(Uri.parse('mailto:support@opright.org?subject=Payment%20Issue'));
              }),
              _HelpTile(Icons.description_rounded, 'Document Help', AppColors.accent, () {
                launchUrl(Uri.parse('mailto:support@opright.org?subject=Document%20Help'));
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Live chat
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('https://wa.me/2349160714439?text=Hello%20OPRIGHT%20Support')),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFFFF9500)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Live Chat with Support', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('Average response: 2 min', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // FAQ
          Text('FAQs', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          ..._faqs.asMap().entries.map((e) {
            final expanded = _expandedFaq.contains(e.key);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))]),
              child: InkWell(
                onTap: () => setState(() { if (expanded) { _expandedFaq.remove(e.key); } else { _expandedFaq.add(e.key); } }),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(e.value.q, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                      AnimatedRotation(turns: expanded ? 0.5 : 0, duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.expand_more_rounded, color: AppColors.textTertiary)),
                    ]),
                    if (expanded) ...[
                      const SizedBox(height: 8),
                      Text(e.value.a, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                    ],
                  ]),
                ),
              ),
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Faq { final String q, a; const _Faq(this.q, this.a); }

Widget _EmergencyCard(String label, String sub, IconData icon, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        Text(sub, style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

Widget _HelpTile(IconData icon, String label, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))]),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
      ]),
    ),
  );
}
