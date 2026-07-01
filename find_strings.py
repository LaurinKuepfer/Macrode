import os
import re

swift_dir = 'c:/Project/Macrode/Macrode'
strings_file = 'c:/Project/Macrode/Macrode/en.lproj/Localizable.strings'

with open(strings_file, 'r', encoding='utf-8') as f:
    strings_content = f.read()

existing_keys = set(re.findall(r'"(.*?)"\s*=', strings_content))

found_strings = set()
for root, dirs, files in os.walk(swift_dir):
    for file in files:
        if file.endswith('.swift'):
            with open(os.path.join(root, file), 'r', encoding='utf-8') as f:
                content = f.read()
                matches = re.findall(r'Text\("(.*?)"\)', content)
                for m in matches:
                    if '\\(' not in m: 
                        found_strings.add(m)
                matches = re.findall(r'\.navigationTitle\("(.*?)"\)', content)
                for m in matches:
                    if '\\(' not in m:
                        found_strings.add(m)
                matches = re.findall(r'Label\("(.*?)"', content)
                for m in matches:
                    if '\\(' not in m:
                        found_strings.add(m)
                matches = re.findall(r'Button\("(.*?)"', content)
                for m in matches:
                    if '\\(' not in m:
                        found_strings.add(m)

missing = found_strings - existing_keys
print('Missing Keys:')
for k in missing:
    print(k)
