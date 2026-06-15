import re
import sys

def modify_customer(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    helper = '''  Widget _buildCustomerDetails(Customer customer) {
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
        buildRow("Title", customer.title),
        buildRow("Name", customer.name),
        buildRow("First", customer.firstName),
        buildRow("Last", customer.lastName),
      ],
    );
  }

  Widget _buildUpNextCard(Appointment appointment) {'''

    content = content.replace('  Widget _buildUpNextCard(Appointment appointment) {', helper)

    # _buildUpNextCard text replacement
    up_next_pattern = r'''                                Text\(
                                  customerName,
                                  style: const TextStyle\(
                                    fontSize: 14,
                                    fontWeight: FontWeight\.w500,
                                    color: Color\(0xFF1E2638\),
                                  \),
                                \),'''
    
    content = re.sub(up_next_pattern, '                                _buildCustomerDetails(appointment.customer),', content)

    # _buildAppointmentCard text replacement
    appt_pattern = r'''                        child: Text\(
                          customerName,
                          style: const TextStyle\(
                            fontSize: 12,
                            fontWeight: FontWeight\.w600,
                            color: Color\(0xFF1E2638\),
                          \),
                          maxLines: 5,
                          overflow: TextOverflow\.ellipsis,
                        \),'''
    content = re.sub(appt_pattern, '                        child: _buildCustomerDetails(appointment.customer),', content)

    with open(file_path, 'w') as f:
        f.write(content)

modify_customer(sys.argv[1])
