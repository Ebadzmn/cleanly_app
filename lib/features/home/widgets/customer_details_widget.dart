import 'package:flutter/material.dart';
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
                value ?? "null",
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
          buildRow("Title", customer.title),
        if (customer.name != null && customer.name!.trim().isNotEmpty)
          buildRow("Name", customer.name),
      ],
    );
  }
}
