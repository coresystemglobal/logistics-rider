import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../models/package_model.dart';
import '../../services/package_service.dart';
import '../../services/rider_service.dart';
import '../../services/verification_service.dart';

enum DeliveryState { pickupTransit, arrivedPickup, deliveryTransit, arrivedDelivery, cashCollection }

class ActiveDeliveryScreen extends ConsumerStatefulWidget {
  final String packageId;
  const ActiveDeliveryScreen({super.key, required this.packageId});
  @override
  ConsumerState<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends ConsumerState<ActiveDeliveryScreen>
    with SingleTickerProviderStateMixin {
  DeliveryState _state = DeliveryState.pickupTransit;
  bool _sheetExpanded = false;
  late final AnimationController _pulseCtrl;
  final List<TextEditingController> _otpControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(4, (_) => FocusNode());
  bool _loading = false;
  PackageModel? _package;
  LatLng _riderPosition = const LatLng(6.5244, 3.3792);
  String? _courierId;
  late final MapController _mapController;
  StreamSubscription<Position>? _locationSub;
  Timer? _locationUploadTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _loadPackage();
    _startTracking();
  }

  Future<void> _startTracking() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() => _riderPosition = LatLng(pos.latitude, pos.longitude));
      _mapController.move(_riderPosition, _mapController.camera.zoom);
    });
    // Upload location to server every 10 seconds
    _locationUploadTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_courierId == null) return;
      try {
        await RiderService().updateCourierLocation(
          courierId: _courierId!,
          latitude: _riderPosition.latitude,
          longitude: _riderPosition.longitude,
        );
      } catch (_) {}
    });
  }

  Future<void> _loadPackage() async {
    try {
      final pkg = await PackageService().getPackageById(widget.packageId);
      final profile = await RiderService().getProfile();
      if (mounted) setState(() { _package = pkg; _courierId = profile.id; });
    } catch (_) {}
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _locationUploadTimer?.cancel();
    _pulseCtrl.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _advance() async {
    setState(() => _loading = true);
    try {
      switch (_state) {
        case DeliveryState.pickupTransit:
          // Rider arrived at pickup — no API call needed, just advance UI
          setState(() { _state = DeliveryState.arrivedPickup; _loading = false; });
          break;
        case DeliveryState.arrivedPickup:
          // Confirm pickup with the pickup PIN from the package
          final pickupPin = _package?.pickupPin ?? '';
          await PackageService().confirmPickup(widget.packageId, pickupPin);
          setState(() { _state = DeliveryState.deliveryTransit; _loading = false; });
          break;
        case DeliveryState.deliveryTransit:
          await VerificationService().triggerDeliveryCode(widget.packageId);
          setState(() { _state = DeliveryState.arrivedDelivery; _loading = false; });
          break;
        case DeliveryState.arrivedDelivery:
          final code = _otpControllers.map((c) => c.text).join();
          if (code.length < 4) { setState(() => _loading = false); return; }
          await PackageService().confirmDelivery(widget.packageId, code);
          final paymentMethod = _package?.paymentMethod ?? '';
          if (paymentMethod == 'CASH') {
            setState(() { _state = DeliveryState.cashCollection; _loading = false; });
          } else {
            final earnings = _package?.estimatedCost?.toStringAsFixed(0) ?? '0';
            if (mounted) context.go('/delivery/${widget.packageId}/complete?earnings=$earnings');
          }
          break;
        case DeliveryState.cashCollection:
          final earnings = _package?.estimatedCost?.toStringAsFixed(0) ?? '0';
          if (mounted) context.go('/delivery/${widget.packageId}/complete?earnings=$earnings');
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen OSM map
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _riderPosition,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.opright.rider',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _riderPosition,
                      width: 44,
                      height: 44,
                      child: AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Container(
                          decoration: BoxDecoration(
                            color: AppColors.iosBlue.withValues(alpha: 0.15 + 0.1 * _pulseCtrl.value),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: AppColors.iosBlue, shape: BoxShape.circle),
                            child: const Icon(Icons.motorcycle_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Floating top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16, right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 60,
                color: Colors.white.withValues(alpha: 0.9),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      color: AppColors.textPrimary,
                      onPressed: () => context.pop(),
                    ),
                    Expanded(child: Text(_stateLabel(), textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                    IconButton(
                      icon: const Icon(Icons.call_rounded, color: AppColors.accent, size: 22),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom sheet
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 30, offset: Offset(0, -8))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _sheetExpanded = !_sheetExpanded),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(width: 36, height: 5, decoration: BoxDecoration(color: AppColors.separator, borderRadius: BorderRadius.circular(3))),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
                    child: _buildSheetContent(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetContent() {
    final pickup = _package?.pickupAddress ?? 'Loading…';
    final delivery = _package?.deliveryAddress ?? 'Loading…';
    final amount = _package?.estimatedCost?.toStringAsFixed(0) ?? '—';
    switch (_state) {
      case DeliveryState.pickupTransit:
        return _TransitSheet(
          title: 'En route to pickup',
          subtitle: 'Head to pickup location',
          address: pickup,
          isPickup: true,
          onArrive: _advance,
          loading: _loading,
        );
      case DeliveryState.arrivedPickup:
        return _ArrivedPickupSheet(
            pickupPin: _package?.pickupPin,
            onPickedUp: _advance, loading: _loading);
      case DeliveryState.deliveryTransit:
        return _TransitSheet(
          title: 'En route to delivery',
          subtitle: 'Head to delivery location',
          address: delivery,
          isPickup: false,
          onArrive: _advance,
          loading: _loading,
        );
      case DeliveryState.arrivedDelivery:
        return _OtpSheet(
            controllers: _otpControllers,
            focusNodes: _otpFocusNodes,
            onConfirm: _advance,
            loading: _loading);
      case DeliveryState.cashCollection:
        return _CashSheet(
            amount: amount, onConfirm: _advance, loading: _loading);
    }
  }

  String _stateLabel() {
    switch (_state) {
      case DeliveryState.pickupTransit: return 'En Route to Pickup';
      case DeliveryState.arrivedPickup: return 'Arrived at Pickup';
      case DeliveryState.deliveryTransit: return 'En Route to Delivery';
      case DeliveryState.arrivedDelivery: return 'Enter Delivery Code';
      case DeliveryState.cashCollection: return 'Collect Cash Payment';
    }
  }
}

class _TransitSheet extends StatelessWidget {
  final String title, subtitle, address;
  final bool isPickup, loading;
  final VoidCallback onArrive;
  const _TransitSheet({required this.title, required this.subtitle, required this.address, required this.isPickup, required this.onArrive, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
            child: Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Row(children: [
          Icon(isPickup ? Icons.location_on_rounded : Icons.flag_rounded, size: 16, color: AppColors.accent),
          const SizedBox(width: 6),
          Expanded(child: Text(address, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: loading ? null : onArrive,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(isPickup ? "I've Arrived at Pickup" : "I've Arrived at Delivery", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _ArrivedPickupSheet extends StatefulWidget {
  final VoidCallback onPickedUp;
  final bool loading;
  final String? pickupPin;
  const _ArrivedPickupSheet({required this.onPickedUp, required this.loading, this.pickupPin});
  @override State<_ArrivedPickupSheet> createState() => _ArrivedPickupSheetState();
}

class _ArrivedPickupSheetState extends State<_ArrivedPickupSheet> {
  bool _packageVerified = false, _photoTaken = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Before picking up', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        if (widget.pickupPin != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.pin_rounded, size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('Pickup PIN: ', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              Text(widget.pickupPin!, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.accent, letterSpacing: 4)),
            ]),
          ),
        ],
        const SizedBox(height: 14),
        _ChecklistItem('Verify package with sender', _packageVerified, () => setState(() => _packageVerified = !_packageVerified)),
        const SizedBox(height: 8),
        _ChecklistItem('Take photo of package', _photoTaken, () => setState(() => _photoTaken = !_photoTaken)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: (_packageVerified && !widget.loading) ? widget.onPickedUp : null,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: widget.loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('Package Picked Up ✓', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

Widget _ChecklistItem(String label, bool checked, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Row(children: [
      AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: checked ? AppColors.success : Colors.transparent,
          border: Border.all(color: checked ? AppColors.success : AppColors.separator, width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: checked ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
      ),
      const SizedBox(width: 12),
      Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary)),
    ]),
  );
}

class _OtpSheet extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final VoidCallback onConfirm;
  final bool loading;
  const _OtpSheet({required this.controllers, required this.focusNodes, required this.onConfirm, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Enter delivery code', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text('Ask the recipient for their 4-digit code', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textTertiary)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (i) => SizedBox(
            width: 64, height: 72,
            child: TextField(autocorrect: false, enableSuggestions: false, 
              controller: controllers[i],
              focusNode: focusNodes[i],
              textAlign: TextAlign.center,
              maxLength: 1,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              decoration: InputDecoration(
                counterText: '',
                filled: true, fillColor: AppColors.bgSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
              ),
              onChanged: (v) {
                if (v.isNotEmpty && i < 3) focusNodes[i + 1].requestFocus();
              },
            ),
          )),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: loading ? null : onConfirm,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('Confirm Delivery', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _CashSheet extends StatefulWidget {
  final String amount;
  final VoidCallback onConfirm;
  final bool loading;
  const _CashSheet(
      {required this.amount, required this.onConfirm, required this.loading});
  @override
  State<_CashSheet> createState() => _CashSheetState();
}

class _CashSheetState extends State<_CashSheet> {
  bool _cashReceived = false, _changeGiven = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Collect cash payment', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Text('₦${widget.amount}',
              style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary)),
        ),
        const SizedBox(height: 16),
        _ChecklistItem('Cash received from recipient', _cashReceived, () => setState(() => _cashReceived = !_cashReceived)),
        const SizedBox(height: 8),
        _ChecklistItem('Change given (if applicable)', _changeGiven, () => setState(() => _changeGiven = !_changeGiven)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: (_cashReceived && !widget.loading) ? widget.onConfirm : null,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: widget.loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('Complete Delivery', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}


