#/bin/bash

# get the current directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR

# iterate over all files in the contracts directory
for file in ../contracts/*.sol; do
    # check if the file is a valid contract

    # check if the file contains solidity version
    cat $file | grep "pragma solidity" > /dev/null
    if [[ "$?" -eq 1 ]]; then
        echo "Not found solidity version in $file | Removing..."
        rm $file

        # Get file name
        filename=$(basename -- "$file")
        # Append to list of invalid files
        echo $filename >> ../invalid.txt
    fi

done