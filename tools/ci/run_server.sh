#!/bin/bash
set -euo pipefail

MAP=$1

echo Testing $MAP

tools/deploy.sh ci_test
mkdir ci_test/config
mkdir ci_test/data

#test config
cp tools/ci/ci_config.txt ci_test/config/config.txt

#set the map
cp _maps/$MAP.json ci_test/data/next_map.json

cd ci_test
DreamDaemon tgstation.dmb -close -trusted -verbose -params "log-directory=ci"

cd ..

mkdir -p data/screenshots_new
cp -r ci_test/data/screenshots_new data/screenshots_new

cat ci_test/data/logs/ci/clean_run.lk
if [[ ! -f ci_test/auxtools_coverage.xml ]] ; then
    echo 'File "auxtools_coverage.xml" is not there, aborting.'
    exit 1
fi

#unflatten
sed -i 's/!/new-text/g' input.txt
