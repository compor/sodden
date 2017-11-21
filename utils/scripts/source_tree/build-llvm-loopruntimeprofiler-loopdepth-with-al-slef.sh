#!/usr/bin/env bash

PRJ_ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../" && pwd)"
SRC_DIR=${1:-$PRJ_ROOT_DIR}
INSTALL_PREFIX=${2:-../install/}

[[ -z $AnnotateLoops_DIR ]] && echo "error: AnnotateLoops_DIR is not set" && exit 2
[[ -z $LoopRuntimeProfiler_DIR ]] && echo "error: LoopRuntimeProfiler_DIR is not set" && exit 2

PIPELINE_CONFIG_FILE="${SRC_DIR}/config/pipelines/loopruntimeprofiler_loopdepth_with_al_slef.txt"
BMK_CONFIG_FILE="${SRC_DIR}/config/suite_all.txt"

#

C_FLAGS="-g -Wall -O0 -mcmodel=medium"
LINKER_FLAGS="-Wl,-L$(llvm-config --libdir) -Wl,-rpath=$(llvm-config --libdir)"
LINKER_FLAGS="${LINKER_FLAGS} -lc++ -lc++abi" 

CC=clang CXX=clang++ \
  cmake \
  -GNinja \
  -GNinja \
  -DCMAKE_POLICY_DEFAULT_CMP0056=NEW \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=On \
  -DLLVM_DIR=$(llvm-config --prefix)/share/llvm/cmake/ \
  -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_C_FLAGS="${C_FLAGS}" \
  -DCMAKE_CXX_FLAGS="-stdlib=libc++" \
  -DCMAKE_EXE_LINKER_FLAGS="${LINKER_FLAGS}" \
  -DCMAKE_SHARED_LINKER_FLAGS="${LINKER_FLAGS}" \
  -DCMAKE_MODULE_LINKER_FLAGS="${LINKER_FLAGS}" \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
  -DHARNESS_USE_LLVM=On \
  -DHARNESS_PIPELINE_CONFIG_FILE=${PIPELINE_CONFIG_FILE} \
  -DHARNESS_BMK_CONFIG_FILE=${BMK_CONFIG_FILE} \
  -DAnnotateLoops_DIR=${AnnotateLoops_DIR} \
  -DLoopRuntimeProfiler_DIR=${LoopRuntimeProfiler_DIR} \
  "${SRC_DIR}"

