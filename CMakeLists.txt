# cmake file

cmake_minimum_required(VERSION 3.0)

project(olden-1.0.0 C CXX)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/")
include(Harness-Utils)
include(Harness-Setparams)
include(Harness-Version)
include(InstallPipelineLLVMIR)

get_version(SODDEN_VERSION)
message(STATUS "Nauseous harness version: ${SODDEN_VERSION}")

message(STATUS "C compiler: ${CMAKE_C_COMPILER}")
message(STATUS "CXX compiler: ${CMAKE_CXX_COMPILER}")


#
# project options
#

option(HARNESS_USE_LLVM "use LLVM bitcode processing tools" OFF)

set(CMAKE_SKIP_INSTALL_ALL_DEPENDENCY TRUE)

set(HARNESS_INPUT_DIR $ENV{HARNESS_INPUT_DIR})

set(HARNESS_REPORT_DIR $ENV{HARNESS_REPORT_DIR})

if(NOT HARNESS_REPORT_DIR)
  set(HARNESS_REPORT_DIR "${CMAKE_BINARY_DIR}/reports/")
  file(MAKE_DIRECTORY ${HARNESS_REPORT_DIR})
endif()
  
set(HARNESS_BMK_SOURCE_SUBDIR "src")

set(HARNESS_CMAKE_PIPELINE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/cmake/pipelines/")

# aggregate list variables for appending commands 
# per each benchmark without editing each cmake file separately
set(HARNESS_CMAKE_FRAGMENT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/cmake/fragments/")
set(HARNESS_CMAKE_BINARY_FRAGMENT_DIR "${CMAKE_CURRENT_BINARY_DIR}/cmake/fragments/")
set(HARNESS_CMAKE_FRAGMENT_FILES "")

set(HARNESS_LLVMIR_CMAKE_FRAGMENT_FILES "")
set(HARNESS_END_CMAKE_FRAGMENT_FILES "")

set(HARNESS_BUILD_TREE_SCRIPTS_SRC_DIR
  "${CMAKE_CURRENT_SOURCE_DIR}/utils/scripts/build_tree/")

set(HARNESS_BUILD_TREE_SCRIPTS_DEST_DIR
  "${CMAKE_CURRENT_BINARY_DIR}/scripts/")

set(HARNESS_INSTALL_TREE_SCRIPTS_DIR
  "${CMAKE_CURRENT_SOURCE_DIR}/utils/scripts/install_tree/")

set(HARNESS_CONFIG_DIR "${CMAKE_CURRENT_SOURCE_DIR}/config")


add_definitions(-DTORONTO)

# project options checks and processing

configure_file("${CMAKE_SOURCE_DIR}/scripts/preamble/preamble.sh.in"
  "preamble/preamble.sh" @ONLY)

if(HARNESS_USE_LLVM)
  find_package(LLVM REQUIRED CONFIG)

  if(LLVM_FOUND)
    set(LLVM_LIB_DIR ${LLVM_TOOLS_BINARY_DIR}/../lib/)

    list(APPEND CMAKE_MODULE_PATH 
      "${CMAKE_CURRENT_SOURCE_DIR}/cmake/llvm-ir-cmake-utils/cmake/")

    include(LLVMIRUtil RESULT_VARIABLE LLVM_IR_UTIL_FOUND)
  endif()
endif()

list(APPEND CMAKE_MODULE_PATH "${HARNESS_CMAKE_PIPELINE_DIR}")
list(APPEND CMAKE_MODULE_PATH "${HARNESS_CMAKE_FRAGMENT_DIR}")
list(APPEND CMAKE_MODULE_PATH "${HARNESS_CMAKE_BINARY_FRAGMENT_DIR}")

if(LLVM_IR_UTIL_FOUND)
  if(NOT HARNESS_PIPELINE_CONFIG_FILE)
    message(WARNING "Benchmark config file is not set")
  elseif(NOT EXISTS ${HARNESS_PIPELINE_CONFIG_FILE})
    message(WARNING "Benchmark config file does not exist: ${HARNESS_PIPELINE_CONFIG_FILE}")
  else()
    file(STRINGS ${HARNESS_PIPELINE_CONFIG_FILE} PIPELINES)
  endif()

  foreach(PLINE ${PIPELINES})
    message(STATUS "including pipeline: ${PLINE}")
    include(${PLINE})
  endforeach()

  create_file_fragment(FILENAME 
    ${HARNESS_CMAKE_BINARY_FRAGMENT_DIR}/BasicFragment.cmake 
    PIPELINES ${PIPELINES})
endif()

#
# project user options
#

# project user options checks and processing

if(NOT HARNESS_BMK_CONFIG_FILE)
  message(FATAL_ERROR "Benchmark config file HARNESS_BMK_CONFIG_FILE is not set")
elseif(NOT EXISTS ${HARNESS_BMK_CONFIG_FILE})
  message(FATAL_ERROR "Benchmark config file does not exist: ${HARNESS_BMK_CONFIG_FILE}")
endif()


#
# configuration
#

# set options for make.def file
set(HARNESS_CC ${CMAKE_C_COMPILER})
set(HARNESS_CFLAGS ${CMAKE_C_FLAGS})
set(HARNESS_CLINKFLAGS ${CMAKE_EXE_LINKER_FLAGS})



set(CMAKE_INSTALL_MESSAGE "LAZY")

# concatenate fragment lists
set(HARNESS_CMAKE_FRAGMENT_FILES BasicFragment)

file(STRINGS ${HARNESS_BMK_CONFIG_FILE} BENCHMARKS)

foreach(BMK ${BENCHMARKS})
  message(STATUS "adding subdir: ${BMK}")
  add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/olden/${BMK}/)
endforeach()


# installation

install(DIRECTORY ${HARNESS_CONFIG_DIR} DESTINATION .)
install(DIRECTORY ${HARNESS_INSTALL_TREE_SCRIPTS_DIR} DESTINATION scripts)
install(DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/preamble/" 
  DESTINATION "preamble/")

add_custom_target(install-build-scripts 
  ALL
  COMMAND ${CMAKE_COMMAND} -E copy_directory 
  ${HARNESS_BUILD_TREE_SCRIPTS_SRC_DIR}
  ${HARNESS_BUILD_TREE_SCRIPTS_DEST_DIR}
  COMMENT "copying build-tree related scripts")

