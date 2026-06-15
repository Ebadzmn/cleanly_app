import re
import sys

def modify_event_detail2(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    # EventDetailCustomer
    content = content.replace('final int id;', 'final String id;')
    content = content.replace('id: json["id"] as int? ?? 0,', 'id: json["id"]?.toString() ?? "",')

    # EventDetailData
    content = content.replace('final int occurrenceId;', 'final String occurrenceId;')
    content = content.replace('occurrenceId: json["occurrence_id"] as int? ?? 0,', 'occurrenceId: json["occurrence_id"]?.toString() ?? "",')
    content = content.replace('appointmentId: json["appointment_id"]?.toString() ?? json["id"]?.toString() ?? "0",', 'appointmentId: json["appointment_id"]?.toString() ?? json["id"]?.toString() ?? "",')
    
    with open(file_path, 'w') as f:
        f.write(content)

modify_event_detail2(sys.argv[1])
