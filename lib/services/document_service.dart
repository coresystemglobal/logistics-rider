import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../../core/api/api_client.dart';
import '../../core/constants/api_endpoints.dart';

class DocumentService {
  final _client = ApiClient.instance;

  Future<Map<String, dynamic>> uploadProfile(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: path.basename(file.path)),
    });
    return _client.postFormData(ApiEndpoints.uploadProfile, formData);
  }

  Future<Map<String, dynamic>> uploadVehicle(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: path.basename(file.path)),
    });
    return _client.postFormData(ApiEndpoints.uploadVehicle, formData);
  }

  Future<Map<String, dynamic>> uploadPackage(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: path.basename(file.path)),
    });
    return _client.postFormData(ApiEndpoints.uploadPackage, formData);
  }

  Future<Map<String, dynamic>> uploadDocument(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: path.basename(file.path)),
    });
    return _client.postFormData(ApiEndpoints.uploadDocument, formData);
  }

  Future<RiderDocumentsModel> getDocuments() async {
    final response = await _client.get(ApiEndpoints.riderDocuments);
    return RiderDocumentsModel.fromJson(response);
  }

  Future<RiderDocumentsModel> updateDocuments({
    required String licenseNumber,
    required String vehicleType,
    required String vehiclePlate,
    String? licensePhoto,
    String? vehiclePhoto,
  }) async {
    final response = await _client.put(ApiEndpoints.riderDocuments, data: {
      'license_number': licenseNumber,
      'vehicle_type': vehicleType,
      'vehicle_plate': vehiclePlate,
      'license_photo': licensePhoto,
      'vehicle_photo': vehiclePhoto,
    });
    return RiderDocumentsModel.fromJson(response);
  }
}

class RiderDocumentsModel {
  final String? licenseNumber;
  final String vehicleType;
  final String? vehiclePlate;
  final String? licensePhoto;
  final String? vehiclePhoto;
  final String verificationStatus;
  final bool isBicycle;
  final List<RiderDocumentItem> documents;

  RiderDocumentsModel({
    this.licenseNumber,
    required this.vehicleType,
    this.vehiclePlate,
    this.licensePhoto,
    this.vehiclePhoto,
    required this.verificationStatus,
    required this.isBicycle,
    required this.documents,
  });

  factory RiderDocumentsModel.fromJson(Map<String, dynamic> json) {
    return RiderDocumentsModel(
      licenseNumber: json['license_number'],
      vehicleType: json['vehicle_type'],
      vehiclePlate: json['vehicle_plate'],
      licensePhoto: json['license_photo'],
      vehiclePhoto: json['vehicle_photo'],
      verificationStatus: json['verification_status'],
      isBicycle: json['is_bicycle'] ?? false,
      documents: (json['documents'] as List<dynamic>?)
          ?.map((e) => RiderDocumentItem.fromJson(e))
          .toList() ?? [],
    );
  }
}

class RiderDocumentItem {
  final String type;
  final String label;
  final String? value;
  final String? photoUrl;
  final bool required;
  final String status;

  RiderDocumentItem({
    required this.type,
    required this.label,
    this.value,
    this.photoUrl,
    required this.required,
    required this.status,
  });

  factory RiderDocumentItem.fromJson(Map<String, dynamic> json) {
    return RiderDocumentItem(
      type: json['type'],
      label: json['label'],
      value: json['value'],
      photoUrl: json['photo_url'],
      required: json['required'],
      status: json['status'],
    );
  }
}