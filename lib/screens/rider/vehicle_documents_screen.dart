import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../services/document_service.dart';

final _documentsProvider = FutureProvider.autoDispose<RiderDocumentsModel>((_) => DocumentService().getDocuments());

class VehicleDocumentsScreen extends ConsumerStatefulWidget {
  const VehicleDocumentsScreen({super.key});

  @override
  ConsumerState<VehicleDocumentsScreen> createState() => _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState extends ConsumerState<VehicleDocumentsScreen> {
  bool _uploading = false;

  Future<void> _uploadDocument(String docType) async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return;

    setState(() => _uploading = true);
    try {
      final file = File(files.first.path!);
      final docService = DocumentService();
      await docService.uploadDocument(file);
      ref.invalidate(_documentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$docType uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _updateProfile({
    required String licenseNumber,
    required String vehiclePlate,
  }) async {
    setState(() => _uploading = true);
    try {
      final docService = DocumentService();
      final current = await docService.getDocuments();
      await docService.updateDocuments(
        licenseNumber: licenseNumber,
        vehicleType: current.vehicleType,
        vehiclePlate: vehiclePlate,
        licensePhoto: current.licensePhoto,
        vehiclePhoto: current.vehiclePhoto,
      );
      ref.invalidate(_documentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showEditDialog(BuildContext context, RiderDocumentsModel docs) {
    if (docs.isBicycle) return; // nothing editable for bicycle riders
    final licenseCtrl = TextEditingController(text: docs.licenseNumber ?? '');
    final plateCtrl = TextEditingController(text: docs.vehiclePlate ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgPrimary,
        title: Text('Edit Vehicle Info', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: licenseCtrl,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: "License Number",
                labelStyle: GoogleFonts.inter(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.bgSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: plateCtrl,
              style: GoogleFonts.inter(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: "Vehicle Plate",
                labelStyle: GoogleFonts.inter(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.bgSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateProfile(
                licenseNumber: licenseCtrl.text.trim(),
                vehiclePlate: plateCtrl.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            child: Text('Save', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(_documentsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        title: Text('Vehicle & Documents', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.bgPrimary, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
        actions: [
          docsAsync.when(
            data: (docs) => docs.isBicycle ? const SizedBox.shrink() : IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 20),
              onPressed: () => _showEditDialog(context, docs),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: docsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
        error: (err, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textQuaternary),
            const SizedBox(height: 12),
            Text('Could not load documents', style: GoogleFonts.inter(fontSize: 15, color: AppColors.textTertiary)),
            TextButton(onPressed: () => ref.invalidate(_documentsProvider), child: const Text('Retry')),
          ]),
        ),
        data: (docs) => _buildContent(docs),
      ),
    );
  }

  Widget _buildContent(RiderDocumentsModel docs) {
    final expiringSoon = docs.documents.where((d) => d.required && d.status == 'expiring').length;

    return ListView(
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
              Icon(docs.vehicleType == 'BICYCLE' ? Icons.directions_bike_rounded : Icons.motorcycle_rounded,
                  color: AppColors.accent, size: 32),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(docs.vehicleType, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                if (!docs.isBicycle)
                  Text(docs.vehiclePlate ?? 'No plate', style: GoogleFonts.inter(fontSize: 14, color: Colors.white.withValues(alpha: 0.6))),
              ]),
            ]),
            const SizedBox(height: 16),
            Text('Rider ID: ${_getRiderId()}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
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

        ...docs.documents
            .where((doc) => doc.required)
            .map((doc) => _DocCard(
          doc: doc,
          isUploading: _uploading,
          onUpload: () => _uploadDocument(doc.label),
        )),

        const SizedBox(height: 32),
      ],
    );
  }

  String _getRiderId() {
    // This would come from auth state in a real app
    return 'TRK-R-00421';
  }
}

class _DocCard extends StatelessWidget {
  final RiderDocumentItem doc;
  final bool isUploading;
  final VoidCallback onUpload;

  const _DocCard({required this.doc, required this.isUploading, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (!doc.required) {
      statusColor = AppColors.textQuaternary; statusIcon = Icons.info_outline_rounded; statusText = 'Not required (Bicycle)';
    } else if (doc.status == 'uploaded') {
      statusColor = AppColors.success; statusIcon = Icons.check_circle_rounded;
      statusText = doc.photoUrl != null ? 'Uploaded' : 'Verified';
    } else if (doc.status == 'expiring') {
      statusColor = AppColors.warning; statusIcon = Icons.warning_rounded;
      statusText = 'Expiring soon';
    } else if (doc.status == 'expired') {
      statusColor = AppColors.error; statusIcon = Icons.error_rounded;
      statusText = 'Expired';
    } else {
      statusColor = AppColors.textQuaternary; statusIcon = Icons.upload_file_rounded; statusText = 'Not uploaded';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary, borderRadius: BorderRadius.circular(14),
        border: (doc.status == 'expired' || doc.status == 'expiring') ? Border.all(color: statusColor.withValues(alpha: 0.4)) : null,
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
          Text(doc.label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text(statusText, style: GoogleFonts.inter(fontSize: 12, color: statusColor)),
        ])),
        GestureDetector(
          onTap: doc.required && !isUploading ? onUpload : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: doc.required ? AppColors.accentLight : AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isUploading ? 'Uploading...' : (doc.status == 'uploaded' ? 'Update' : 'Upload'),
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                  color: doc.required ? AppColors.accent : AppColors.textQuaternary),
            ),
          ),
        ),
      ]),
    );
  }
}