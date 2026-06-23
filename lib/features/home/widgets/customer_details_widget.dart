import 'package:flutter/material.dart';
import '../../../../services/localization_service.dart';
import '../domain/models/appointment_models.dart';

class CustomerDetailsWidget extends StatelessWidget {
  final Customer customer;

  const CustomerDetailsWidget({Key? key, required this.customer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buildRow(String label, String? value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$label: ",
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            Expanded(
              child: Text(
                value ?? (LocalizationService().translate("home.nullValue") ?? "null"),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E2638),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (customer.title != null && customer.title!.trim().isNotEmpty)
          buildRow(LocalizationService().translate("home.title") ?? "Title", customer.title),
        if (customer.name != null && customer.name!.trim().isNotEmpty)
          buildRow(LocalizationService().translate("home.name") ?? "Name", customer.name),
      ],
    );
  }
}
