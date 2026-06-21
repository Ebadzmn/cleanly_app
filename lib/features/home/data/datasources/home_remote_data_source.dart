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
    
    queryParams["status"] = "scheduled";
    
    final Uri url = Uri.parse(
      ApiConfig.buildUrlWithParams("/api/appointments/cleaner", queryParams),
    );

    final response = await NetworkCaller.get(url);

    if (response.isSuccess) {
      if (response.data != null && response.data!["data"] is List) {
        final List<dynamic> dataList = response.data!["data"];
        final List<Appointment> appointments = dataList
            .map((item) => Appointment.fromJson(item as Map<String, dynamic>))
            .toList();

        // Group by date
        Map<String, List<Appointment>> grouped = {};
        for (var appt in appointments) {
          String dateKey = appt.date; 
          // normalize date format if it has time
          if (dateKey.contains("T")) {
            dateKey = dateKey.split("T")[0];
          }
          if (!grouped.containsKey(dateKey)) {
            grouped[dateKey] = [];
          }
          grouped[dateKey]!.add(appt);
        }

        List<UpcomingDate> upcomingList = grouped.entries.map((entry) {
          return UpcomingDate(date: entry.key, data: entry.value);
        }).toList();

        // Sort upcoming list by date
        upcomingList.sort((a, b) => a.date.compareTo(b.date));

        return AppointmentsResponse(
          success: response.data!["success"] as bool? ?? true,
          message: response.data!["message"]?.toString() ?? "",
          upcoming: upcomingList,
          todayAppointments: appointments,
          selectedDate: queryParams["date"],
        );
      } else {
        throw Exception("No data received");
      }
    } else {
      throw Exception(response.message ?? "Failed to fetch appointments");
    }
  }
}
