#!/bin/bash

#
# Purpose:  To clean stray directories to provide a clean reference training
#            environment, starting at step-1
#
# Author:  Eric Broda, ericbroda@rogers.com
#
# Parameters:
#   None noted
#

# Create a list of directories to remove
# Note that this assumes that the previous state of the directories is
# is that from a cloned repository

xDIRECTORIES=("../myaccounts" "../customers" "../accounts" "../transacts" "../compose" "../etc" "../swagger")

for xDIRECTORY in "${xDIRECTORIES[@]}"; do
    echo Removing directory: $xDIRECTORY
    rm -r $xDIRECTORY
done
