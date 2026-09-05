import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/document_service.dart';
import '../../core/constants/validation_rules.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _pageCtrl = PageController();
  int _step = 0;

  // Step 1 fields
  final _firstNameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();
  bool _showReferral = false;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;

  // Step 2 fields
  String _vehicleType = 'MOTORCYCLE';
  final _licenseCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  File? _licenseFile;
  File? _vehicleFile;
  String? _licenseFileName;
  String? _vehicleFileName;

  // Inline validation errors
  final Map<String, String?> _errors = {};

  @override
  void dispose() {
    _pageCtrl.dispose();
    _firstNameCtrl.dispose();
    _surnameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _referralCtrl.dispose();
    _licenseCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  bool _validateStep1() {
    final errs = <String, String?>{};
    if (_firstNameCtrl.text.trim().length < 2) errs['first_name'] = 'First name must be at least 2 characters';
    if (_surnameCtrl.text.trim().length < 2) errs['surname'] = 'Surname must be at least 2 characters';
    if (!RegExp(r'^(\+?[1-9]\d{1,14}|0\d{10})$').hasMatch(_phoneCtrl.text.trim())) errs['phone'] = 'Enter a valid phone number';
    if (!_emailCtrl.text.trim().contains('@')) errs['email'] = 'Enter a valid email address';
    if (_passwordCtrl.text.length < ValidationRules.minPasswordLength) errs['password'] = ValidationRules.passwordTooShort();
    if (!_agreedToTerms) errs['terms'] = 'You must agree to the terms to continue';
    setState(() { _errors.clear(); _errors.addAll(errs); });
    return errs.isEmpty;
  }

  bool _validateStep2() {
    final errs = <String, String?>{};
    if (_vehicleType != 'BICYCLE') {
      if (_licenseCtrl.text.trim().isEmpty) errs['license'] = 'License number is required';
      if (_plateCtrl.text.trim().isEmpty) errs['plate'] = 'Vehicle plate is required';
    }
    setState(() { _errors.clear(); _errors.addAll(errs); });
    return errs.isEmpty;
  }

  void _nextStep() {
    if (_step == 0) {
      if (!_validateStep1()) return;
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      if (!_validateStep2()) return;
      _submit();
    }
  }

  String _normalizePhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (phone.startsWith('+')) return phone;
    if (phone.startsWith('234')) return '+$phone';
    if (phone.startsWith('0')) return '+234${phone.substring(1)}';
    return '+234$phone';
  }

  Future<void> _submit() async {
    final notifier = ref.read(authProvider.notifier);
    final docService = DocumentService();

    String? licensePhotoUrl;
    String? vehiclePhotoUrl;

    // Upload license photo if provided
    if (_licenseFile != null) {
      try {
        final result = await docService.uploadDocument(_licenseFile!);
        licensePhotoUrl = result['url'];
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to upload license photo: $e'),
            backgroundColor: Colors.red.shade700,
          ));
        }
        return;
      }
    }

    // Upload vehicle photo if provided
    if (_vehicleFile != null) {
      try {
        final result = await docService.uploadDocument(_vehicleFile!);
        vehiclePhotoUrl = result['url'];
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to upload vehicle photo: $e'),
            backgroundColor: Colors.red.shade700,
          ));
        }
        return;
      }
    }

    await notifier.registerRider(
      firstName: _firstNameCtrl.text.trim(),
      surname: _surnameCtrl.text.trim(),
      phone: _normalizePhone(_phoneCtrl.text.trim()),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      vehicleType: _vehicleType,
      licenseNumber: _vehicleType != 'BICYCLE' ? _licenseCtrl.text.trim() : null,
      vehiclePlate: _vehicleType != 'BICYCLE' ? _plateCtrl.text.trim() : null,
      licensePhoto: licensePhotoUrl,
      vehiclePhoto: vehiclePhotoUrl,
      referralCode: _showReferral && _referralCtrl.text.isNotEmpty ? _referralCtrl.text.trim() : null,
    );
  }

  Future<void> _pickFile(bool isLicense) async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isNotEmpty) {
      final file = File(files.first.path!);
      setState(() {
        if (isLicense) {
          _licenseFile = file;
          _licenseFileName = files.first.name;
        } else {
          _vehicleFile = file;
          _vehicleFileName = files.first.name;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final loading = authState.status == AuthStatus.loading;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.status != AuthStatus.loading) return;
      if (next.status == AuthStatus.authenticated) {
        context.go('/verify-email');
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1C1C1E), Color(0xFF261812)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _step == 0 ? context.pop() : _pageCtrl.previousPage(
                        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Text('Become a Rider',
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _StepDot(active: _step >= 0, label: '1 Personal'),
                    Expanded(child: Container(height: 1.5, color: _step >= 1 ? AppColors.accent : Colors.white.withValues(alpha: 0.2))),
                    _StepDot(active: _step >= 1, label: '2 Vehicle & KYC'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _Step1(
                  firstNameCtrl: _firstNameCtrl,
                  surnameCtrl: _surnameCtrl,
                  phoneCtrl: _phoneCtrl,
                  emailCtrl: _emailCtrl,
                  passwordCtrl: _passwordCtrl,
                  referralCtrl: _referralCtrl,
                  showReferral: _showReferral,
                  agreedToTerms: _agreedToTerms,
                  obscurePassword: _obscurePassword,
                  errors: _errors,
                  onToggleReferral: () => setState(() => _showReferral = !_showReferral),
                  onToggleTerms: (v) => setState(() => _agreedToTerms = v),
                  onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                _Step2(
                  vehicleType: _vehicleType,
                  licenseCtrl: _licenseCtrl,
                  plateCtrl: _plateCtrl,
                  licenseFileName: _licenseFileName,
                  vehicleFileName: _vehicleFileName,
                  errors: _errors,
                  onVehicleType: (v) => setState(() => _vehicleType = v),
                  onPickLicense: () => _pickFile(true),
                  onPickVehicle: () => _pickFile(false),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 16),
            color: AppColors.bgPrimary,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: loading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(_step == 0 ? 'Continue' : 'Submit Application',
                        style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final String label;
  const _StepDot({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: GoogleFonts.inter(fontSize: 11,
                color: active ? AppColors.accent : Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }
}

class _Step1 extends StatelessWidget {
  final TextEditingController firstNameCtrl, surnameCtrl, phoneCtrl, emailCtrl, passwordCtrl, referralCtrl;
  final bool showReferral, agreedToTerms, obscurePassword;
  final Map<String, String?> errors;
  final VoidCallback onToggleReferral, onTogglePassword;
  final ValueChanged<bool> onToggleTerms;

  const _Step1({
    required this.firstNameCtrl, required this.surnameCtrl, required this.phoneCtrl,
    required this.emailCtrl, required this.passwordCtrl, required this.referralCtrl,
    required this.showReferral, required this.agreedToTerms, required this.obscurePassword,
    required this.errors,
    required this.onToggleReferral, required this.onToggleTerms, required this.onTogglePassword,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(child: _FieldBox(ctrl: firstNameCtrl, label: 'First Name', hint: 'John', error: errors['first_name'])),
                  const SizedBox(width: 12),
                  Expanded(child: _FieldBox(ctrl: surnameCtrl, label: 'Surname', hint: 'Doe', error: errors['surname'])),
                ],
              ),
              const SizedBox(height: 12),
              _FieldBox(ctrl: phoneCtrl, label: 'Phone Number', hint: '+234 800 000 0000', type: TextInputType.phone, error: errors['phone']),
              const SizedBox(height: 12),
              _FieldBox(ctrl: emailCtrl, label: 'Email', hint: 'your@email.com', type: TextInputType.emailAddress, error: errors['email']),
              const SizedBox(height: 12),
              TextField(
                autocorrect: false,
                enableSuggestions: false,
                controller: passwordCtrl,
                obscureText: obscurePassword,
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary),
                  filled: true, fillColor: AppColors.bgPrimary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: errors['password'] != null
                        ? BorderSide(color: Colors.red.shade400, width: 1.5)
                        : BorderSide.none,
                  ),
                  errorText: errors['password'],
                  errorStyle: GoogleFonts.inter(fontSize: 11, color: Colors.red.shade400),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: AppColors.textTertiary, size: 20),
                    onPressed: onTogglePassword,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: onToggleReferral,
                child: Row(
                  children: [
                    Icon(showReferral ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.accent, size: 20),
                    const SizedBox(width: 6),
                    Text('Have a referral code?',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (showReferral) ...[
                const SizedBox(height: 10),
                _FieldBox(ctrl: referralCtrl, label: 'Referral Code', hint: 'RIDER-XXXX'),
              ],
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: agreedToTerms,
                        onChanged: (v) => onToggleTerms(v ?? false),
                        activeColor: AppColors.accent,
                        side: errors['terms'] != null
                            ? BorderSide(color: Colors.red.shade400, width: 1.5)
                            : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text.rich(
                            TextSpan(
                              text: 'I agree to the ',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                              children: [
                                TextSpan(text: 'Terms of Service', style: GoogleFonts.inter(color: AppColors.accent, fontWeight: FontWeight.w500)),
                                const TextSpan(text: ' and '),
                                TextSpan(text: 'Privacy Policy', style: GoogleFonts.inter(color: AppColors.accent, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (errors['terms'] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 2),
                      child: Text(errors['terms']!,
                          style: GoogleFonts.inter(fontSize: 11, color: Colors.red.shade400)),
                    ),
                ],
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step2 extends StatelessWidget {
  final String vehicleType;
  final TextEditingController licenseCtrl, plateCtrl;
  final String? licenseFileName, vehicleFileName;
  final Map<String, String?> errors;
  final ValueChanged<String> onVehicleType;
  final VoidCallback onPickLicense, onPickVehicle;

  const _Step2({
    required this.vehicleType, required this.licenseCtrl, required this.plateCtrl,
    required this.licenseFileName, required this.vehicleFileName,
    required this.errors,
    required this.onVehicleType, required this.onPickLicense, required this.onPickVehicle,
  });

  bool get _isBicycle => vehicleType == 'BICYCLE';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('Vehicle Type', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _VehicleChip(
                    label: 'Motorcycle', icon: Icons.motorcycle_rounded,
                    selected: vehicleType == 'MOTORCYCLE', onTap: () => onVehicleType('MOTORCYCLE'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _VehicleChip(
                    label: 'Bicycle', icon: Icons.directions_bike_rounded,
                    selected: vehicleType == 'BICYCLE', onTap: () => onVehicleType('BICYCLE'),
                  )),
                ],
              ),
              if (!_isBicycle) ...[
                const SizedBox(height: 16),
                _FieldBox(ctrl: licenseCtrl, label: 'License Number', hint: 'e.g. LIC-2024-XXXXX', error: errors['license']),
                const SizedBox(height: 12),
                _FieldBox(ctrl: plateCtrl, label: 'Vehicle Plate', hint: 'e.g. ABC-123-XY', error: errors['plate']),
                const SizedBox(height: 24),
                Text('Documents', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text('Upload clear photos of your documents',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(height: 14),
                _UploadCard(label: "Driver's License", fileName: licenseFileName, onTap: onPickLicense),
                const SizedBox(height: 10),
                _UploadCard(label: 'Vehicle Registration', fileName: vehicleFileName, onTap: onPickVehicle),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldBox extends StatelessWidget {
  final TextEditingController ctrl;
  final String label, hint;
  final TextInputType type;
  final String? error;

  const _FieldBox({required this.ctrl, required this.label, required this.hint,
      this.type = TextInputType.text, this.error});

  @override
  Widget build(BuildContext context) {
    return TextField(
      autocorrect: false,
      enableSuggestions: false,
      controller: ctrl,
      keyboardType: type,
      style: GoogleFonts.inter(fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textQuaternary),
        filled: true, fillColor: AppColors.bgPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: error != null ? BorderSide(color: Colors.red.shade400, width: 1.5) : BorderSide.none,
        ),
        errorText: error,
        errorStyle: GoogleFonts.inter(fontSize: 11, color: Colors.red.shade400),
      ),
    );
  }
}

class _VehicleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _VehicleChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentLight : AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.accent : AppColors.separator, width: selected ? 1.5 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.accent : AppColors.textSecondary, size: 28),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                color: selected ? AppColors.accent : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  final String label;
  final String? fileName;
  final VoidCallback onTap;

  const _UploadCard({required this.label, required this.fileName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: fileName != null ? AppColors.success : AppColors.separator,
            width: fileName != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (fileName != null ? AppColors.success : AppColors.accent).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                fileName != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                color: fileName != null ? AppColors.success : AppColors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  Text(fileName ?? 'Tap to upload photo',
                      style: GoogleFonts.inter(fontSize: 12, color: fileName != null ? AppColors.success : AppColors.textTertiary),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
