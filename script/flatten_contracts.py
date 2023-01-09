import os
import json

counter = 0
json_counter = 0

# read all file in contracts diretory
path = '../contracts'
for filename in os.listdir(path):
    print(filename)

    fp = open(path + '/' + filename)
    file_content = fp.read()
    is_json = file_content.startswith('{')
    # tem alguns que começam com {{
    concat = ''

    if (is_json):
        # parse json
        json_content = json.loads(file_content)

        # for each file
        for key in json_content:
            contract_content = json_content[key]['content']
            concat += contract_content


        json_counter += 1

        print(concat)
        exit()

    counter += 1

print('counter:', counter)
print('json_counter:', json_counter)