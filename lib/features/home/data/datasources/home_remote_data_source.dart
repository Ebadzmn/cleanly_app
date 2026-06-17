import '../../domain/models/appointment_models.dart';
import '../../../../services/network_caller.dart';
import '../../../../config/api_config.dart';

class HomeRemoteDataSource {
  Future<AppointmentsResponse> fetchCleanerAppointments([DateTime? date]) async {
    Map<String, String> queryParams = {};
    if (date != null) {
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      queryParams["date"] = dateStr;
    }
    
    final Uri url = Uri.parse(
      ApiConfig.buildUrlWithParams("/api/appointments/cleaner", queryParams),
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
