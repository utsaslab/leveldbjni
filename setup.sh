#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
#set -o xtrace

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"

# Check existance of pebblesdb includes
INCLUDE_PEBBLESDB="${PEBBLESDB_HOME}/src/include"
if [ ! -e "$INCLUDE_PEBBLESDB" ]; then
    echo "${PEBBLESDB_HOME}/src/include does not exist"
    exit 1
fi

# Check existance of pebblesdb library 
LIB_PEBBLESDB="${PEBBLESDB_HOME}/build/libpebblesdb.a"
if [ ! -e "$LIB_PEBBLESDB" ]; then
    echo "${PEBBLESDB_HOME}/build/libpebblesdb.a does not exist"
    exit 2
fi

# Create a local pebblesdb directory to store includes and library.
PEBBLESDB_LOCAL_DIR="${__dir}/pebblesdb"
if [ -e ${PEBBLESDB_LOCAL_DIR} ]; then
    cd ${PEBBLESDB_LOCAL_DIR?} && rm -rf --preserve-root *
fi

[[ -d ${PEBBLESDB_LOCAL_DIR} ]] || mkdir ${PEBBLESDB_LOCAL_DIR}

cp ${LIB_PEBBLESDB} ${PEBBLESDB_LOCAL_DIR}
cp -r ${INCLUDE_PEBBLESDB} ${PEBBLESDB_LOCAL_DIR}

if [ -e "${PEBBLESDB_LOCAL_DIR}/include/pebblesdb" ]; then
    mv "${PEBBLESDB_LOCAL_DIR}/include/pebblesdb" "${PEBBLESDB_LOCAL_DIR}/include/leveldb"
else
    echo "${PEBBLESDB_LOCAL_DIR}/include/pebblesdb does not exist"
    exit 3
fi

if [ -e "${PEBBLESDB_LOCAL_DIR}/libpebblesdb.a" ]; then
    mv "${PEBBLESDB_LOCAL_DIR}/libpebblesdb.a" "${PEBBLESDB_LOCAL_DIR}/libleveldb.a"
else
    echo "${PEBBLESDB_LOCAL_DIR}/include/pebblesdb does not exist"
    exit 4
fi

echo "DONE"
exit 0
