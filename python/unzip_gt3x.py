import os
import glob
import zipfile

files = glob.iglob('**/*.gt3x', recursive=True)

for f in files:
    src_path = f.split('.')[0]
    if not os.path.exists(src_path):
        print('Unzipping %s' % f)
        os.makedirs(src_path)
        with zipfile.ZipFile(f, 'r') as myzip:
            myzip.extractall(src_path)
    # os.remove(f)
