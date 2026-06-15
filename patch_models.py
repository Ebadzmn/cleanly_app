import re
import sys

def modify_models(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    # Change int to String for Customer.id
    content = content.replace('final int id;', 'final String id;')
    content = content.replace('id: json["id"] as int? ?? 0,', 'id: json["id"]?.toString() ?? "",')
    content = content.replace('id: json["customer_id"] as int? ?? json["id"] as int? ?? 0,', 'id: json["customer_id"]?.toString() ?? json["id"]?.toString() ?? "",')

    # Change int to String for Occurrence.id
    # (The above replace might have changed it, but let's be safe)

    # Change int to String for Appointment.occurrenceId
    content = content.replace('final int occurrenceId;', 'final String occurrenceId;')
    content = content.replace('occurrenceId: json["occurrence_id"] as int? ?? 0,', 'occurrenceId: json["occurrence_id"]?.toString() ?? "",')
    
    # Restore AppointmentsResponse.fromJson to parse grouped structure
    response_pattern = r'factory AppointmentsResponse\.fromJson\(Map<String, dynamic> json\) \{[\s\S]*?^\}'
    
    new_response = '''factory AppointmentsResponse.fromJson(Map<String, dynamic> json) {
    return AppointmentsResponse(
      success: json["success"] as bool? ?? false,
      message: json["message"]?.toString() ?? "",
      upcoming: (json["data"]?["upcoming"] as List<dynamic>? ?? [])
          .map(
            (item) => UpcomingDate.fromJson(item as Map<String, dynamic>? ?? {}),
          )
          .toList(),
    );
  }'''
    
    content = re.sub(response_pattern, new_response, content, flags=re.MULTILINE)

    with open(file_path, 'w') as f:
        f.write(content)

modify_models(sys.argv[1])
