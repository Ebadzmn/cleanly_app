import re
import sys

def modify_arrival(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    content = content.replace('final int occurrenceId;', 'final String occurrenceId;')

    with open(file_path, 'w') as f:
        f.write(content)

modify_arrival(sys.argv[1])
