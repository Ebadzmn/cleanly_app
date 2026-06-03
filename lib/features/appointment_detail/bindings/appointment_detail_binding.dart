import 'package:get/get.dart';
import '../controllers/appointment_detail_controller.dart';

class AppointmentDetailBinding extends Bindings {
  final int appointmentId;
  final Map<String, dynamic> appointmentData;

  AppointmentDetailBinding({required this.appointmentId, required this.appointmentData});

  @override
  void dependencies() {
    Get.lazyPut<AppointmentDetailController>(
      () => AppointmentDetailController(appointmentId: appointmentId, appointmentData: appointmentData),
    );
  }
}
