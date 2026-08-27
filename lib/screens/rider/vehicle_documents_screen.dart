import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class VehicleDocumentsScreen extends StatefulWidget {
  const VehicleDocumentsScreen({super.key});
  @override State<VehicleDocumentsScreen> createState() => _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState extends State<VehicleDocumentsScreen> {
  final _docs = {
    "Driver's License": _DocStatus(expires: DateTime(2026, 3, 15), uploaded: true),
    'Vehicle Registration': _DocStatus(expires: DateTime(2025, 8, 1), uploaded: true),
    'Vehicle Insurance': _DocStatus(expires: DateTime(2024, 12, 31), uploaded: false),
    'Road Worthiness': _DocStatus(expires: DateTime(2026, 6, 10), uploaded: true),
  };

  Future<void> _upload(String docName) async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isNotEmpty && mounted) {
      setState(() => _docs[docName] = _DocStatus(expires: _docs[docName]!.expires, uploaded: true));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$docName uploaded')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final expiringSoon = _docs.values.where((d) => d.uploaded && d.daysUntilExpiry < 30).length;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        title: Text('Vehicle & Documents', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bgPrimary, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Vehicle card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1C1C1E), Color(0xFF2A1A10)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.motorcycle_rounded, color: AppColors.accent, size: 32),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Motorcycle', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('ABC-123-XY', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.6))),
                ]),
              ]),
              const SizedBox(height: 16),
              Text('Rider ID: TRK-R-00421', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
            ]),
          ),

          if (expiringSoon > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(children: [
                const Icon(Icons.warning_rounded, color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('$expiringSoon document${expiringSoon > 1 ? 's' : ''} expiring soon. Renew to avoid suspension.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary))),
              ]),
            ),
          ],

          const SizedBox(height: 16),
          Text('Documents', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 10),

          ..._docs.entries.map((e) => _DocCard(
            name: e.key, status: e.value, onUpload: () => _upload(e.key),
          )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DocStatus {
  final DateTime? expires;
  final bool uploaded;
  const _DocStatus({this.expires, required this.uploaded});
  int get daysUntilExpiry => expires != null ? expires!.difference(DateTime.now()).inDays : 9999;
  bool get isExpired => daysUntilExpiry < 0;
  bool get isExpiringSoon => daysUntilExpiry >= 0 && daysUntilExpiry < 30;
}

class _DocCard extends StatelessWidget {
  final String name;
  final _DocStatus status;
  final VoidCallback onUpload;
  const _DocCard({required this.name, required this.status, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!status.uploaded) {
      statusColor = AppColors.textQuaternary; statusIcon = Icons.upload_file_rounded; statusText = 'Not uploaded';
    } else if (status.isExpired) {
      statusColor = AppColors.error; statusIcon = Icons.error_rounded; statusText = 'Expired';
    } else if (status.isExpiringSoon) {
      statusColor = AppColors.warning; statusIcon = Icons.warning_rounded;
      statusText = 'Expires in ${status.daysUntilExpiry}d';
    } else {
      statusColor = AppColors.success; statusIcon = Icons.check_circle_rounded;
      final exp = status.expires;
      statusText = exp != null ? 'Valid until ${exp.day}/${exp.month}/${exp.year}' : 'Valid';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(14),
        border: status.isExpired || status.isExpiringSoon ? Border.all(color: statusColor.withValues(alpha: 0.4)) : null,
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(statusIcon, color: statusColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text(statusText, style: GoogleFonts.inter(fontSize: 12, color: statusColor)),
        ])),
        GestureDetector(
          onTap: onUpload,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(8)),
            child: Text(status.uploaded ? 'Update' : 'Upload',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
          ),
        ),
      ]),
    );
  }
}
