import '../repositories/home_repository.dart';
import '../models/appointment_models.dart';

class GetAppointmentsUseCase {
  final HomeRepository repository;

  GetAppointmentsUseCase(this.repository);

  Future<AppointmentsResponse> call() async {
    return await repository.getCleanerAppointments();
  }
}
