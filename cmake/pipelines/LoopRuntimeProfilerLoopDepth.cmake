# cmake file

macro(LoopRuntimeProfilerLoopDepthPipelineSetupNames)
  set(PIPELINE_NAME "LoopRuntimeProfilerLoopDepth")
  set(PIPELINE_INSTALL_TARGET "${PIPELINE_NAME}-install")
endmacro()

macro(LoopRuntimeProfilerLoopDepthPipelineSetup)
  LoopRuntimeProfilerLoopDepthPipelineSetupNames()

  message(STATUS "setting up pipeline ${PIPELINE_NAME}")

  if(NOT DEFINED ENV{HARNESS_INPUT_DIR})
    message(FATAL_ERROR
      "${PIPELINE_NAME} env variable HARNESS_INPUT_DIR is not defined")
  endif()

  if(NOT DEFINED ENV{HARNESS_REPORT_DIR})
    message(FATAL_ERROR
      "${PIPELINE_NAME} env variable HARNESS_REPORT_DIR is not defined")
  endif()

  file(TO_CMAKE_PATH $ENV{HARNESS_INPUT_DIR} HARNESS_INPUT_DIR)
  if(NOT IS_DIRECTORY ${HARNESS_INPUT_DIR})
    message(FATAL_ERROR "${PIPELINE_NAME} HARNESS_INPUT_DIR does not exist")
  endif()

  file(TO_CMAKE_PATH $ENV{HARNESS_REPORT_DIR} HARNESS_REPORT_DIR)
  if(NOT EXISTS ${HARNESS_REPORT_DIR})
    file(MAKE_DIRECTORY ${HARNESS_REPORT_DIR})
  endif()

  message(STATUS
    "${PIPELINE_NAME} uses env variable: HARNESS_INPUT_DIR=${HARNESS_INPUT_DIR}")
  message(STATUS
    "${PIPELINE_NAME} uses env variable: HARNESS_REPORT_DIR=${HARNESS_REPORT_DIR}")

  #

  find_package(LoopRuntimeProfiler CONFIG)

  if(NOT LoopRuntimeProfiler_FOUND)
    message(WARNING "package LoopRuntimeProfiler was not found; skipping.")

    return()
  endif()

  get_target_property(LRP_LIB_LOCATION LLVMLoopRuntimeProfilerPass LOCATION)

  configure_file("${CMAKE_SOURCE_DIR}/scripts/preamble/preamble.sh.in"
    "preamble/${PIPELINE_NAME}_preamble.sh" @ONLY)
endmacro()

LoopRuntimeProfilerLoopDepthPipelineSetup()

#

function(LoopRuntimeProfilerLoopDepthPipeline trgt)
  LoopRuntimeProfilerLoopDepthPipelineSetupNames()

  if(NOT TARGET ${PIPELINE_NAME})
    add_custom_target(${PIPELINE_NAME})
  endif()

  set(PIPELINE_SUBTARGET "${PIPELINE_NAME}_${trgt}")
  set(PIPELINE_PREFIX ${PIPELINE_SUBTARGET})

  set(DEPENDEE_TRGT "SimplifyLoopExitsFront_${trgt}_link")

  ## pipeline targets and chaining

  file(TO_CMAKE_PATH
    "$ENV{HARNESS_INPUT_DIR}/${BMK_NAME}/$ENV{LRP_LOOP_ID_WHITELIST_FILE}"
    PIPELINE_INPUT_FILE)

  if(EXISTS ${PIPELINE_INPUT_FILE})
    set(PIPELINE_CMDLINE_ARG "-lrp-loop-id-whitelist=${PIPELINE_INPUT_FILE}")
  else()
    message(STATUS "could not find file: ${PIPELINE_INPUT_FILE}")
  endif()

  file(TO_CMAKE_PATH "$ENV{HARNESS_REPORT_DIR}/${BMK_NAME}-${PIPELINE_NAME}"
    REPORT_FILE_PREFIX)

  llvmir_attach_opt_pass_target(${PIPELINE_PREFIX}_link
    ${DEPENDEE_TRGT}
    -load ${LRP_LIB_LOCATION}
    -loop-runtime-profiler
    -lrp-mode=module
    -lrp-loop-depth-ub=1
    -lrp-report=${REPORT_FILE_PREFIX})

  llvmir_attach_executable(${PIPELINE_PREFIX}_bc_exe ${PIPELINE_PREFIX}_link)
  add_dependencies(${PIPELINE_PREFIX}_bc_exe ${PIPELINE_PREFIX}_link)

  target_link_libraries(${PIPELINE_PREFIX}_bc_exe lrp_loopdepth_rt m)

  ## pipeline aggregate targets
  add_custom_target(${PIPELINE_SUBTARGET} DEPENDS
    ${DEPENDEE_TRGT}
    ${PIPELINE_PREFIX}_link
    ${PIPELINE_PREFIX}_bc_exe)

  add_dependencies(${PIPELINE_NAME} ${PIPELINE_SUBTARGET})


  # installation
  get_property(bmk_name TARGET ${trgt} PROPERTY BMK_NAME)
  set(DEST_DIR "CPU2006/${bmk_name}")

  install(TARGETS ${PIPELINE_PREFIX}_bc_exe
    DESTINATION ${DEST_DIR} OPTIONAL)

  set(BMK_BIN_NAME "${PIPELINE_PREFIX}_bc_exe")

  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/scripts/
    DESTINATION ${DEST_DIR}
    PATTERN "*.sh"
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)


  # installation
  get_property(bmk_name TARGET ${trgt} PROPERTY BMK_NAME)
  set(DEST_DIR "${bmk_name}")

  install(TARGETS ${PIPELINE_PREFIX}_bc_exe
    DESTINATION ${DEST_DIR} OPTIONAL)

  set(BMK_BIN_NAME "${PIPELINE_PREFIX}_bc_exe")

  set(BMK_BIN_PREAMBLE "\"\"")

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

