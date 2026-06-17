import '../../domain/repositories/home_repository.dart';
import '../../domain/models/appointment_models.dart';
import '../datasources/home_remote_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl(this.remoteDataSource);

  @override
  Future<AppointmentsResponse> getCleanerAppointments([DateTime? date]) async {
    return await remoteDataSource.fetchCleanerAppointments(date);
  }
}
