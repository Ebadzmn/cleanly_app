import 'package:get/get.dart';
import '../../domain/models/appointment_models.dart';
import '../../domain/usecases/get_appointments_use_case.dart';
import '../../data/datasources/home_remote_data_source.dart';
import '../../data/repositories/home_repository_impl.dart';

class HomeController extends GetxController {
  final GetAppointmentsUseCase getAppointmentsUseCase;

  HomeController({GetAppointmentsUseCase? useCase})
      : getAppointmentsUseCase = useCase ??
            GetAppointmentsUseCase(
              HomeRepositoryImpl(HomeRemoteDataSource()),
            );

  final Rx<DateTime?> selectedDate = Rx<DateTime?>(null);
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isError = false.obs;
  final RxString errorMessage = ''.obs;

  final Rx<AppointmentsResponse?> appointmentsData = Rx<AppointmentsResponse?>(null);
  final RxList<UpcomingDate> filteredUpcoming = <UpcomingDate>[].obs;
  final RxList<Appointment> todayAppointments = <Appointment>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAppointments();
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    _applyFilter();
  }

  void clearDateSelection() {
    selectedDate.value = null;
    _applyFilter();
  }

  Future<void> fetchAppointments({bool isRefresh = false}) async {
    if (isRefresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    isError.value = false;

    try {
      final response = await getAppointmentsUseCase.call();
      appointmentsData.value = response;

      // Extract today's appointments if needed by UI
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      List<Appointment> todayList = [];
      for (var group in response.upcoming) {
        if (group.date == todayStr) {
          todayList.addAll(group.data);
        }
      }
      todayAppointments.value = todayList;

      _applyFilter();
    } catch (e) {
      print("--- ERROR FETCHING APPOINTMENTS ---");
      print(e);
      isError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  void _applyFilter() {
    if (appointmentsData.value == null) return;

    if (selectedDate.value == null) {
      // Display all upcoming appointments
      filteredUpcoming.value = appointmentsData.value!.upcoming;
    } else {
      // Filter by selected date
      final selectedDateStr = "${selectedDate.value!.year}-${selectedDate.value!.month.toString().padLeft(2, '0')}-${selectedDate.value!.day.toString().padLeft(2, '0')}";
      
      final matchingGroup = appointmentsData.value!.upcoming.firstWhere(
        (group) => group.date == selectedDateStr,
        orElse: () => UpcomingDate(date: selectedDateStr, data: []),
      );
      
      filteredUpcoming.value = [matchingGroup];
    }
  }
}
