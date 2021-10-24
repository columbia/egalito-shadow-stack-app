#!/bin/bash

set -e

echo
echo ========= Invoking shadow-stack app
../app/etapp -q vuln vuln.ss

echo
echo ========= Shadow-stack-hardened program
perl vuln.pl ./vuln.ss

echo "^^^ please make this die with status 4"
