import '../core/api/api_client.dart';
import '../core/constants/api_endpoints.dart';

class VerificationService {
  final _api = ApiClient.instance;

  Future<void> verifyEmail(String email, String code) async {
    await _api.post(ApiEndpoints.verifyEmail, data: {'email': email, 'code': code});
  }

  Future<void> verifyPhone(String phone, String code) async {
    await _api.post(ApiEndpoints.verifyPhone, data: {'phone': phone, 'code': code});
  }

  Future<void> resendEmailVerification(String email) async {
    await _api.post(ApiEndpoints.resendEmailVerification, data: {'email': email});
  }

  Future<void> resendPhoneVerification(String phone) async {
    await _api.post(ApiEndpoints.resendPhoneVerification, data: {'phone': phone});
  }

  Future<void> triggerDeliveryCode(String packageId) async {
    await _api.post(ApiEndpoints.triggerDeliveryCode(packageId));
  }
}
