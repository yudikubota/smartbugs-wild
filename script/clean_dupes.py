import json
import os

fp = open("dupes.json")

data = json.load(fp)

for k, v in data.items():
    for duplicated in v['duplicates']:
        # keep the original file
        if (k == duplicated):
            continue

        # delete duplicated file
        print(f'Contract {duplicated} is duplicated, deleting...')
        exists = os.path.isfile(f'../contracts/{duplicated}.sol')
        if (exists):
            os.remove(f'../contracts/{duplicated}.sol')