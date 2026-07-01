import os, re

def update_strings(src_file, dst_file):
    with open(src_file, 'r', encoding='utf-8') as f:
        src = f.read()
    with open(dst_file, 'r', encoding='utf-8') as f:
        dst = f.read()

    src_keys = dict(re.findall(r'\"(.*?)\"\s*=\s*\"(.*?)\";', src))
    dst_keys_list = re.findall(r'\"(.*?)\"\s*=\s*\".*?\";', dst)
    dst_keys = set(dst_keys_list)

    missing = []
    for k, v in src_keys.items():
        if k not in dst_keys:
            missing.append(f'"{k}" = "{v}";\n')

    if missing:
        with open(dst_file, 'a', encoding='utf-8') as f:
            f.write('\n// Auto-added missing translations\n')
            f.writelines(missing)
        print(f'Added {len(missing)} keys to {dst_file}')
    else:
        print(f'No missing keys in {dst_file}')

base_dir = 'c:/Project/Macrode/Macrode'
en_file = os.path.join(base_dir, 'en.lproj', 'Localizable.strings')

for lang in ['de', 'es', 'fr']:
    tgt_file = os.path.join(base_dir, f'{lang}.lproj', 'Localizable.strings')
    if os.path.exists(tgt_file):
        update_strings(en_file, tgt_file)
