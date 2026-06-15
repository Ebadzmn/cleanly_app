import re
import sys

def remove_first_last(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    # In _buildCustomerDetails
    content = content.replace('        buildRow("First", customer.firstName),\n', '')
    content = content.replace('        buildRow("Last", customer.lastName),\n', '')

    # Remove the unused customerName string in _buildUpNextCard
    unused_customer_name_up_next = r'''    final String customerName =
        "Title: \$\{appointment\.customer\.title \?\? 'null'\}\\n"
        "Name: \$\{appointment\.customer\.name \?\? 'null'\}\\n"
        "First Name: \$\{appointment\.customer\.firstName \?\? 'null'\}\\n"
        "Last Name: \$\{appointment\.customer\.lastName \?\? 'null'\};"'''
    # Use re.sub to remove the variable declaration if we can match it safely, or just ignore since we don't strictly have to fix unused variables right now if regex fails.
    
    with open(file_path, 'w') as f:
        f.write(content)

remove_first_last(sys.argv[1])
