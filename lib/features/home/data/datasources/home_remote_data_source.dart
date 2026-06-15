import '../../domain/models/appointment_models.dart';
import '../../../../services/network_caller.dart';
import '../../../../config/api_config.dart';

class HomeRemoteDataSource {
  Future<AppointmentsResponse> fetchCleanerAppointments() async {
    final Uri url = Uri.parse(
      ApiConfig.buildUrlWithParams("/api/appointments/cleaner", {}),
    );

    final response = await NetworkCaller.get(url);

    print("--- API RESPONSE DATA ---");
    print(response.data);

    if (response.isSuccess) {
      if (response.data != null) {
        return AppointmentsResponse.fromJson(response.data!);
      } else {
        throw Exception("No data received");
      }
    } else {
      throw Exception(response.message ?? "Failed to fetch appointments");
    }
  }
}
