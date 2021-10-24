#!/bin/bash

set -e

echo
echo ========= Invoking 1-1 Egalito transformation
../egalito/app/etelf vuln vuln.m

echo
echo ========= Invoking shadow-stack app
../app/etapp -q vuln vuln.ss

echo
echo ========= Original program
perl vuln.pl ./vuln
echo "^^^ should have been successfully exploited (status 1)"

echo
echo ========= Egalito-hardened program
perl vuln.pl ./vuln.m
echo "^^^ should have been successfully exploited (status 1)"

echo
echo ========= Shadow-stack-hardened program
perl vuln.pl ./vuln.ss

echo "^^^ please make this die with status 4"
