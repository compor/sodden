# cmake file

set(BMK_NAME "mst")
string(TOLOWER ${BMK_NAME} BMK_NAME_LOWER)
set(BMK_PROJECT_NAME ${BMK_NAME_LOWER})

check_bmk_processing(hasSrcDir)

if(NOT ${hasSrcDir})
  message(STATUS "skipping project: ${BMK_PROJECT_NAME}") 
  return()
endif()

set(BMK_LANG "C")

#set(SOURCES
  #args.c                                       
  #hash.c
  #main.c
  #makegraph.c)

file(GLOB CXXSOURCES 
  RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/${HARNESS_BMK_SOURCE_SUBDIR} 
  ${HARNESS_BMK_SOURCE_SUBDIR}/*.cpp)
file(GLOB CSOURCES 
  RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/${HARNESS_BMK_SOURCE_SUBDIR}
  ${HARNESS_BMK_SOURCE_SUBDIR}/*.c)

if(CXXSOURCES)
  set(BMK_LANG "CXX")
endif()

list(APPEND SOURCES ${CSOURCES} ${CXXSOURCES})
add_prefix(SOURCES "${HARNESS_BMK_SOURCE_SUBDIR}/" "${SOURCES}")

message(STATUS "${BMK_NAME} source language: ${BMK_LANG}")
set_source_files_properties(${SOURCES} PROPERTIES LANGUAGE ${BMK_LANG})

add_executable(${BMK_PROJECT_NAME} ${SOURCES})

target_include_directories(${BMK_PROJECT_NAME} PUBLIC
  "${CMAKE_CURRENT_BINARY_DIR}")

target_include_directories(${BMK_PROJECT_NAME} PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}/${HARNESS_BMK_SOURCE_SUBDIR}/")

target_link_libraries(${BMK_PROJECT_NAME} m)


# this property is required by our parasitic targets
set_target_properties(${BMK_PROJECT_NAME} PROPERTIES 
  LINKER_LANGUAGE ${BMK_LANG})

# this property is used internally by our harness 
# because benchmark names and their main targets have different names
set_target_properties(${BMK_PROJECT_NAME} PROPERTIES BMK_NAME ${BMK_NAME})

#

if(LLVM_IR_UTIL_FOUND)
  foreach(FRAGMENT ${HARNESS_CMAKE_FRAGMENT_FILES})
    include(${FRAGMENT})
  endforeach()
endif()

