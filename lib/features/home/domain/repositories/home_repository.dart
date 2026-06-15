import '../models/appointment_models.dart';

abstract class HomeRepository {
  Future<AppointmentsResponse> getCleanerAppointments();
}
