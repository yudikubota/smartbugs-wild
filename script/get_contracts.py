from etherscan import Etherscan
from ratelimit import limits, sleep_and_retry
import os
import json
import sys

# constants
SAVE_EACH = 50
ETHERSCAN_RATELIMIT_PER_SECOND = 5

# arguments
API_KEY = sys.argv[1]
proc_label = sys.argv[2]  # useful for parallel processing
start = int(sys.argv[3])  # useful for parallel processing
end = int(sys.argv[4])  # useful for parallel processing

# Etherscan client
eth_client = Etherscan(API_KEY)

# stats
stats = {
    "count": 0,  # general counting
    "source_code_not_available": 0,  # etherscan returns no code (not verified)
    "source_code_available": 0,  # etherscan returns the verified source code
    "unaccessible": 0,  # etherscan says the contract does not exists
    "no_tx": 0,  # contract has no transactions
    "no_balance": 0,  # contract has no balance
    "existent": 0,  # contract source code has already been download
    "existent_no_balance": 0,  # contract source code has already been download but was removed due to zero balance
    "not_valid": [],  # exception occured
    "original_start": 0,  # useful for parallel processing
    "original_end": 0,  # useful for parallel processing
}

# load last stats
stats_filename = f"stats_{proc_label}.json"
if os.path.exists(stats_filename):
    with open(stats_filename) as fd:
        stats = json.load(fd)

if (stats['count']):
    start = int(stats['count'])

if not stats["original_start"]:
    stats["original_start"] = start
if not stats["original_end"] and end:
    stats["original_end"] = end

nb_contracts = 6834430  # update with result of `wc -l all_contract.csv`


def remove_contract(address):
    contract_path = f"../contracts/{address}.sol"
    if (os.path.exists(contract_path)):
        stats['existent_no_balance'] += 1
        os.remove(contract_path)

def save_file():
    with open(stats_filename + '.tmp', "w") as fd:
        json.dump(stats, fd)

        if (os.path.exists(stats_filename)):
            os.rename(stats_filename, stats_filename + '.bak')
        if (os.path.exists(stats_filename + '.tmp')):
            os.rename(stats_filename + '.tmp', stats_filename)
        if (os.path.exists(stats_filename + '.bak')):
            os.remove(stats_filename + '.bak')


def should_process_line(block_timestamp, address, tx_count, eth_balance):
    if start > stats["count"]:
        return False
    if tx_count == "0":
        stats["no_tx"] += 1
        return False
    if eth_balance.strip() == "0":
        stats["no_balance"] += 1
        remove_contract(address)
        return False
    if address in stats["not_valid"]:
        return False

    contract_path = f"../contracts/{address}.sol"
    if os.path.exists(contract_path):
        stats["existent"] += 1
        return False

    return True

@sleep_and_retry
@limits(calls=ETHERSCAN_RATELIMIT_PER_SECOND, period=1)
def get_sourcecode(address):
    response = eth_client.get_contract_source_code(address)
    sourcecode = response[0]["SourceCode"]
    contract_path = f"../contracts/{address}.sol"
    if len(sourcecode) == 0:
        stats["source_code_not_available"] += 1
    else:
        stats["source_code_available"] += 1
        with open(contract_path, "w") as fd:
            fd.write(sourcecode)

def process_line(line):
    # checks if pass
    [block_timestamp, address, tx_count, eth_balance] = line.split(",")
    if not should_process_line(block_timestamp, address, tx_count, eth_balance):
        return

    try:
        get_sourcecode(address)
    except Exception as exp:
        stats["not_valid"].append(address)
        print(address, ': ', exp)

stats["count"] = 0
with open("all_contract.csv") as fp:
    line = fp.readline() # skip the first line
    line = fp.readline()
    while line:
        process_line(line)
        stats["count"] += 1

        # print progress
        if (stats["count"] % SAVE_EACH == 0):
            print(
                stats["count"],
                "/",
                nb_contracts,
                round(stats["count"] * 100 / nb_contracts, 2),
                "%",
            )

            save_file()

        if end != 0 and stats["count"] >= end:
            save_file()
            exit(0)

        line = fp.readline()
