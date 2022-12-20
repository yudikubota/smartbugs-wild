import os

fp = open('all_contract.csv')

fp.readline() # skip header
line = fp.readline()

REPORT_EACH = 10000
SPLIT_SIZE = 10000
DATE_FROM = '2020-07-01'
DATE_TO = '2022-12-31'

group = []
file_counter = 0
line_counter = 0

def write_group():
    file_counter += 1

    # write group to file
    filename = f'split_{file_counter}.txt'
    with open(filename, 'w') as f:
        for item in group:
            f.write(item)

    group = []

while (line):
    line_counter += 1

    # split fields
    fields = line.split(',')
    block_timestamp = fields[0]
    address = fields[1]

    # parse timestamp
    block_timestamp = block_timestamp[:10]

    # print(line)
    if (line_counter % REPORT_EACH == 0):
        print(f'Processed {line_counter} lines.')

    # filter by date
    if (not (block_timestamp >= DATE_FROM and block_timestamp <= DATE_TO)):
        # print('Rejected by date.')
        continue

    # filter out addresses not present in the dataset
    exists = os.path.isfile(f'../contracts/{address}.sol')
    if (not exists):
        # print('Rejected by not in dataset.')
        continue

    group.append(address)

    if (len(group) >= SPLIT_SIZE):
        write_group()

    line = fp.readline()

if (len(group) > 0):
    write_group()

print('')
print(f'Processed {line_counter} lines.')
print(f'Dataset was divided into {file_counter} files.')
print('')