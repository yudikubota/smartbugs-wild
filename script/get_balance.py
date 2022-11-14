import os
from etherscan import Etherscan
import json
import sys
import time
import atexit

# get api token from cli argument
API_KEY = sys.argv[1]
MAX_ADDRESSES_PER_CALL = 20
NUM_BACKUP_FILES = 3
SAVE_FILE_EACH = 1000

# create the Etherscan client
etherscan_client = Etherscan(API_KEY)

# load balances if file exists
balances = {}
if os.path.exists('balances.json'):
    with open('balances.json') as fd:
        balances = json.load(fd)

# vars
count = 0
backup_file_counter = 0
nb_contracts = 6826269 # note: update manually with the number of all_contract.csv lines

# gets the current block
print('Fetching current block number...')
current_block = etherscan_client.get_block_number_by_timestamp(int(time.time()), 'before')
print('Fetching balances from Etherscan at block at least:', current_block)

def save_file(bk=True):
    global backup_file_counter
    file_number = backup_file_counter % NUM_BACKUP_FILES
    filename = f'balances-{file_number}.json' if bk else 'balances.json'
    with open(filename, 'w') as fd:
        json.dump(balances, fd)
    backup_file_counter += 1

def exit_handler():
    print('Saving file before exit...')
    save_file(False)

atexit.register(exit_handler)

with open('all_contract.csv') as fp:
    line = fp.readline()
    addresses_to_call = []
    while line:
        address = line.split(',')[0]
        count += 1

        # checks if the balance was already fetched
        if address == 'address' or address in balances:
            line = fp.readline()
            continue

        if (count % SAVE_FILE_EACH == 0):
            save_file()

        # make the API call
        addresses_to_call.append(address)
        if (len(addresses_to_call) >= MAX_ADDRESSES_PER_CALL):
            # print progress
            print(count, '/', nb_contracts, round(count * 100 / nb_contracts, 2), '%')

            try:
                new_balances = etherscan_client.get_eth_balance_multiple(addresses_to_call)
                for new_balance in new_balances:
                    balances[new_balance['account']] = int(new_balance['balance'])

                addresses_to_call = []

            except Exception as identifier:
                print(identifier)
                continue

        line = fp.readline()

with open('balances.json', 'w') as fd:
    json.dump(balances, fd)

# print final result
print('Stored', len(balances), 'balances in total')

if (nb_contracts != len(balances)):
    print('Warning: some balances failed to be updated.')