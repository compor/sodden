# cmake file

macro(PollyWithIdOptPipelineSetupNames)
  set(PIPELINE_NAME "PollyWithIdOpt")
  set(PIPELINE_INSTALL_TARGET "${PIPELINE_NAME}-install")
endmacro()

macro(PollyWithIdOptPipelineSetup)
  PollyWithIdOptPipelineSetupNames()

  message(STATUS "setting up pipeline ${PIPELINE_NAME}")

  if(NOT DEFINED ENV{HARNESS_INPUT_DIR})
    message(WARNING
      "${PIPELINE_NAME} env variable HARNESS_INPUT_DIR is not defined. \
      Using ${CMAKE_BINARY_DIR}/inputs/")

      set(ENV{HARNESS_INPUT_DIR} "${CMAKE_BINARY_DIR}/inputs/")
  endif()

  if(NOT DEFINED ENV{HARNESS_REPORT_DIR})
    message(WARNING
      "${PIPELINE_NAME} env variable HARNESS_REPORT_DIR is not defined. \
      Using ${CMAKE_BINARY_DIR}/reports/")

      set(ENV{HARNESS_REPORT_DIR} "${CMAKE_BINARY_DIR}/reports/")
  endif()

  if(NOT DEFINED ENV{POLLY_BLACKLIST_FILE})
    message(WARNING
      "${PIPELINE_NAME} env variable POLLY_BLACKLIST_FILE is not defined")
  endif()

  file(TO_CMAKE_PATH $ENV{HARNESS_INPUT_DIR} HARNESS_INPUT_DIR)
  if(NOT EXISTS ${HARNESS_INPUT_DIR})
    file(MAKE_DIRECTORY ${HARNESS_INPUT_DIR})
  endif()

  file(TO_CMAKE_PATH $ENV{HARNESS_REPORT_DIR} HARNESS_REPORT_DIR)
  if(NOT EXISTS ${HARNESS_REPORT_DIR})
    file(MAKE_DIRECTORY ${HARNESS_REPORT_DIR})
  endif()

  message(STATUS
    "${PIPELINE_NAME} uses env variable: HARNESS_INPUT_DIR=$ENV{HARNESS_INPUT_DIR}")
  message(STATUS
    "${PIPELINE_NAME} uses env variable: HARNESS_REPORT_DIR=$ENV{HARNESS_REPORT_DIR}")
  message(STATUS
    "${PIPELINE_NAME} uses env variable: POLLY_BLACKLIST_FILE=$ENV{POLLY_BLACKLIST_FILE}")
  #

  find_package(LLVMPolly REQUIRED)
endmacro()

PollyWithIdOptPipelineSetup()

#

function(PollyWithIdOptPipeline trgt)
  PollyWithIdOptPipelineSetupNames()

  if(NOT TARGET ${PIPELINE_NAME})
    add_custom_target(${PIPELINE_NAME})
  endif()

  set(PIPELINE_SUBTARGET "${PIPELINE_NAME}_${trgt}")
  set(PIPELINE_PREFIX ${PIPELINE_SUBTARGET})

  set(DEPENDEE_TRGT "AnnotateLoops_${trgt}_opt2")

  ## pipeline targets and chaining

  file(TO_CMAKE_PATH "$ENV{HARNESS_REPORT_DIR}/${BMK_NAME}-${PIPELINE_NAME}.txt"
    REPORT_FILE)

  file(TO_CMAKE_PATH
    "${HARNESS_INPUT_DIR}/${BMK_NAME}/$ENV{POLLY_BLACKLIST_FILE}"
    PIPELINE_INPUT_FILE)

  if(EXISTS ${PIPELINE_INPUT_FILE})
    set(PIPELINE_CMDLINE_ARG "-polly-func-blacklist=${PIPELINE_INPUT_FILE}")
  endif()

  #llvmir_attach_opt_pass_target(
    #TARGET ${PIPELINE_PREFIX}_opt_level2
    #DEPENDS ${DEPENDEE_TRGT}
    #-O2)
  #add_dependencies(${PIPELINE_PREFIX}_opt_level2 ${DEPENDEE_TRGT})

  llvmir_attach_opt_pass_target(
    TARGET ${PIPELINE_PREFIX}_link
    DEPENDS ${DEPENDEE_TRGT}
    -load ${LLVMPOLLY_SHARED_LIBRARY}
    -polly-canonicalize
    -polly-scops
    -polly-export-jscop
    -polly-codegen
    -polly-parallel
    -polly-export-parallel-id-loops=${REPORT_FILE}
    ${PIPELINE_CMDLINE_ARG})
  add_dependencies(${PIPELINE_PREFIX}_link ${DEPENDEE_TRGT})

  llvmir_attach_opt_pass_target(
    TARGET ${PIPELINE_PREFIX}_opt_level2
    DEPENDS ${PIPELINE_PREFIX}_link
    -O2)
  add_dependencies(${PIPELINE_PREFIX}_opt_level2 ${PIPELINE_PREFIX}_link)

  # do not produce binary because we need to link against a parallel lib
  llvmir_attach_executable(
    TARGET ${PIPELINE_PREFIX}_bc_exe
    DEPENDS ${PIPELINE_PREFIX}_opt_level2)
    #DEPENDS ${PIPELINE_PREFIX}_link)
  #add_dependencies(${PIPELINE_PREFIX}_bc_exe ${PIPELINE_PREFIX}_link)
  add_dependencies(${PIPELINE_PREFIX}_bc_exe ${PIPELINE_PREFIX}_opt_level2)
  target_link_libraries(${PIPELINE_PREFIX}_bc_exe m gomp)

  ## pipeline aggregate targets
  add_custom_target(${PIPELINE_SUBTARGET} DEPENDS
    ${DEPENDEE_TRGT}
    ${PIPELINE_PREFIX}_opt_level2
    ${PIPELINE_PREFIX}_link
    ${PIPELINE_PREFIX}_bc_exe)

  add_dependencies(${PIPELINE_NAME} ${PIPELINE_SUBTARGET})


  # installation
  get_property(bmk_name TARGET ${trgt} PROPERTY BMK_NAME)
  set(DEST_DIR "${bmk_name}")

  install(TARGETS ${PIPELINE_PREFIX}_bc_exe
    DESTINATION ${DEST_DIR} OPTIONAL)

  set(BMK_BIN_NAME "${PIPELINE_PREFIX}_bc_exe")
  set(BMK_BIN_PREAMBLE "")
  set(PIPELINE_SCRIPT_PREFIX "${PIPELINE_NAME}")

  configure_file("scripts/_run.sh.in" "scripts/${PIPELINE_PREFIX}_run.sh" @ONLY)

  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/scripts/
    DESTINATION ${DEST_DIR}
    PATTERN "*.sh"
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)

  # IR installation
  if(NOT TARGET ${PIPELINE_INSTALL_TARGET})
    add_custom_target(${PIPELINE_INSTALL_TARGET})
  endif()

  InstallPipelineLLVMIR(DEPENDS ${PIPELINE_PREFIX}_link
    ATTACH_TO_TARGET ${PIPELINE_INSTALL_TARGET} BMK_NAME ${bmk_name})
endfunction()

