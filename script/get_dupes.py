import json

counter = 0
unique_counter = 0
current_dup = ''
current_counter = 0

output = {}

with open("../dupes.txt") as fp:
    line = fp.readline().replace('\n', '')

    while line:
        if (line == '\n'):
            unique_counter += 1
            current_dup = ''
        else:
            counter += 1
            current_counter += 1

            if (not current_dup):
                current_dup = line
                output[current_dup] = {
                    'counter': 1,
                    'duplicates': [current_dup],
                }
            else:
                output[current_dup]['duplicates'].append(line)
                output[current_dup]['counter'] += 1

        line = fp.readline()
        if (line != '\n'):
            line = line.replace('\n', '')

# dump output as json
json.dump(output, open('dupes.json', 'w'), indent=4)
