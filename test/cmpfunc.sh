#!/bin/bash

if [ -z "$3" ]; then
    echo "Usage: $0 function binary1 binary2"
    exit 1
fi

diff --color -y \
    <(objdump -d $2 | ./showfunc.pl $1 | ./stripaddr.pl) \
    <(objdump -d $3 | ./showfunc.pl $1 | ./stripaddr.pl)
