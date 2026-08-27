class JobOfferModel {
  final String requestId;
  final String? packageId;
  final String courierId;
  final double fee;
  final String pickupAddress;
  final String dropoffAddress;
  final double distanceKm;
  final int etaMinutes;
  final String packageType;
  final String packageSize;
  final double weightKg;
  final String vehicleType;
  final DateTime? expiresAt;

  const JobOfferModel({
    required this.requestId,
    this.packageId,
    required this.courierId,
    required this.fee,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.distanceKm,
    required this.etaMinutes,
    required this.packageType,
    required this.packageSize,
    required this.weightKg,
    required this.vehicleType,
    this.expiresAt,
  });

  factory JobOfferModel.fromJson(Map<String, dynamic> json) {
    final expiresAt = json['expires_at'] ?? json['expiresAt'];
    final packageId = json['packageId']?.toString() ?? json['package_id']?.toString();
    return JobOfferModel(
      requestId: json['requestId']?.toString() ?? json['request_id']?.toString() ?? '',
      packageId: (packageId != null && packageId.isNotEmpty) ? packageId : null,
      courierId: json['courierId']?.toString() ?? json['courier_id']?.toString() ?? '',
      fee: _num(json['fee'] ?? json['estimated_fee']),
      pickupAddress: (json['pickupAddress'] ?? json['pickup_address'] ?? '').toString(),
      dropoffAddress: (json['dropoffAddress'] ?? json['dropoff_address'] ?? json['delivery_address'] ?? '').toString(),
      distanceKm: _num(json['distanceKm'] ?? json['distance_km']),
      etaMinutes: _num(json['etaMinutes'] ?? json['eta_minutes']).toInt(),
      packageType: (json['packageType'] ?? json['package_type'] ?? 'Parcel').toString(),
      packageSize: (json['packageSize'] ?? json['package_size'] ?? 'SMALL').toString(),
      weightKg: _num(json['weightKg'] ?? json['weight_kg']),
      vehicleType: (json['vehicleType'] ?? json['vehicle_type'] ?? '').toString(),
      expiresAt: expiresAt != null ? DateTime.tryParse(expiresAt.toString()) : null,
    );
  }

  static double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
