#!/usr/bin/env bash

PRJ_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
SRC_DIR=${1:-$PRJ_ROOT_DIR}
INSTALL_PREFIX=${2:-../install/}

BMK_CONFIG_FILE="${SRC_DIR}/config/suite_all.txt"

#

C_FLAGS="-g -Wall"
C_FLAGS="${C_FLAGS} -O2"
C_FLAGS="${C_FLAGS} -D__STRICT_ANSI__"

# required when using opts to avoid crashes when crawling up the call stack
C_FLAGS="${C_FLAGS} -fno-omit-frame-pointer"
C_FLAGS="${C_FLAGS} -pg"

CXX_FLAGS="${C_FLAGS}"

#LINKER_FLAGS="-Wl,-L$(llvm-config --libdir) -Wl,-rpath=$(llvm-config --libdir)"
#LINKER_FLAGS="${LINKER_FLAGS} -lc++ -lc++abi" 

CC=clang CXX=clang++ \
cmake \
  -GNinja \
  -DCMAKE_POLICY_DEFAULT_CMP0056=NEW \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=On \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_C_FLAGS="${C_FLAGS}" \
  -DCMAKE_CXX_FLAGS="${CXX_FLAGS}" \
  -DCMAKE_EXE_LINKER_FLAGS="${LINKER_FLAGS}" \
  -DCMAKE_SHARED_LINKER_FLAGS="${LINKER_FLAGS}" \
  -DCMAKE_MODULE_LINKER_FLAGS="${LINKER_FLAGS}" \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
  -DHARNESS_BMK_CONFIG_FILE=${BMK_CONFIG_FILE} \
  "${SRC_DIR}"

