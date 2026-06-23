import os
import re
import json

def get_all_keys(d, prefix=''):
    keys = set()
    for k, v in d.items():
        if isinstance(v, dict):
            keys.update(get_all_keys(v, prefix + k + '.'))
        else:
            keys.add(prefix + k)
    return keys

with open('assets/translations/en.json', 'r') as f:
    en_keys = get_all_keys(json.load(f))

used_keys = set()
pattern = re.compile(r'LocalizationService\(\)\.translate\([\'"]([a-zA-Z0-9_\.]+)[\'"]\)')
pattern2 = re.compile(r'translateWithParams\([\'"]([a-zA-Z0-9_\.]+)[\'"]')
pattern3 = re.compile(r'localization\.translate\([\'"]([a-zA-Z0-9_\.]+)[\'"]\)')

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            with open(os.path.join(root, file), 'r') as f:
                content = f.read()
                for match in pattern.findall(content):
                    used_keys.add(match)
                for match in pattern2.findall(content):
                    used_keys.add(match)
                for match in pattern3.findall(content):
                    used_keys.add(match)

missing_keys = used_keys - en_keys
print("Missing Keys:")
for key in sorted(missing_keys):
    print(key)
