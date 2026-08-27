import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_offer_model.dart';
import '../services/matching_service.dart';
import '../services/real_time_service.dart';

class JobOfferState {
  final JobOfferModel? offer;
  /// Set once the backend confirms the accepted delivery (race-free hand-off).
  final String? assignedPackageId;
  const JobOfferState({this.offer, this.assignedPackageId});
}

class JobOfferNotifier extends StateNotifier<JobOfferState> {
  String? _pendingPackageId;
  Timer? _fallbackTimer;

  JobOfferNotifier() : super(const JobOfferState()) {
    RealTimeService.instance.on('new-job-offer', _onNewOffer);
    RealTimeService.instance.on('delivery-assigned', _onDeliveryAssigned);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _onNewOffer(dynamic data) {
    if (data == null) return;
    final map = data is Map ? Map<String, dynamic>.from(data) : null;
    if (map == null) return;
    state = JobOfferState(offer: JobOfferModel.fromJson(map));
  }

  void _onDeliveryAssigned(dynamic data) {
    final map = data is Map ? Map<String, dynamic>.from(data) : null;
    final packageId = map?['packageId']?.toString() ?? map?['package_id']?.toString();
    if (packageId == null || packageId.isEmpty) return;
    // Only react to a delivery we actually accepted (race-free signal)
    if (_pendingPackageId != null && packageId != _pendingPackageId) return;
    _fallbackTimer?.cancel();
    _pendingPackageId = null;
    state = JobOfferState(assignedPackageId: packageId);
  }

  Future<bool> accept() async {
    final offer = state.offer;
    if (offer == null) return false;
    final target = offer.packageId ?? offer.requestId;
    try {
      await MatchingService().acceptOffer(
        courierId: offer.courierId,
        requestId: offer.requestId,
      );
      _pendingPackageId = target;
      state = const JobOfferState();
      // Fallback if the delivery-assigned socket event is missed
      _fallbackTimer?.cancel();
      _fallbackTimer = Timer(const Duration(seconds: 4), () {
        if (_pendingPackageId != null) {
          final pkg = _pendingPackageId;
          _pendingPackageId = null;
          state = JobOfferState(assignedPackageId: pkg);
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> ignore() async {
    final offer = state.offer;
    state = const JobOfferState();
    if (offer == null) return;
    try {
      await MatchingService().rejectOffer(
        courierId: offer.courierId,
        requestId: offer.requestId,
      );
    } catch (_) {}
  }

  void dismiss() => state = const JobOfferState();

  void clearAssigned() {
    if (state.assignedPackageId != null) {
      state = const JobOfferState();
    }
  }
}

final jobOfferProvider =
    StateNotifierProvider<JobOfferNotifier, JobOfferState>(
  (_) => JobOfferNotifier(),
);
