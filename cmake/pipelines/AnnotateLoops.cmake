# cmake file

macro(AnnotateLoopsPipelineSetupNames)
  set(PIPELINE_NAME "AnnotateLoops")
  set(PIPELINE_INSTALL_TARGET "${PIPELINE_NAME}-install")
endmacro()

macro(AnnotateLoopsPipelineSetup)
  AnnotateLoopsPipelineSetupNames()

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

  if(NOT DEFINED ENV{ANNOTATELOOPS_WHITELIST_FILE})
    message(WARNING
      "${PIPELINE_NAME} env variable ANNOTATELOOPS_WHITELIST_FILE is not defined")
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
    "${PIPELINE_NAME} uses env variable: ANNOTATELOOPS_WHITELIST_FILE=$ENV{ANNOTATELOOPS_WHITELIST_FILE}")

  #

  find_package(AnnotateLoops CONFIG REQUIRED)

  get_target_property(ANNOTATELOOPS_LIB_LOCATION LLVMAnnotateLoopsPass LOCATION)

  set(PREAMBLE_SCRIPT "preamble.sh")
  set(PREAMBLE_SCRIPT_INPUT "${CMAKE_SOURCE_DIR}/scripts/preamble/${PREAMBLE_SCRIPT}.in")

  if(EXISTS ${PREAMBLE_SCRIPT_INPUT})
    configure_file(${PREAMBLE_SCRIPT_INPUT} "preamble/${PIPELINE_NAME}_${PREAMBLE_SCRIPT}" @ONLY)
  endif()
endmacro()

AnnotateLoopsPipelineSetup()

#

function(AnnotateLoopsPipeline trgt)
  AnnotateLoopsPipelineSetupNames()

  if(NOT TARGET ${PIPELINE_NAME})
    add_custom_target(${PIPELINE_NAME})
  endif()

  set(PIPELINE_SUBTARGET "${PIPELINE_NAME}_${trgt}")
  set(PIPELINE_PREFIX ${PIPELINE_SUBTARGET})

  ## pipeline targets and chaining

  file(TO_CMAKE_PATH "${HARNESS_REPORT_DIR}/${BMK_NAME}-${PIPELINE_NAME}.txt"
    REPORT_FILE)

  llvmir_attach_bc_target(
    TARGET ${PIPELINE_PREFIX}_bc
    DEPENDS ${trgt})
  add_dependencies(${PIPELINE_PREFIX}_bc ${trgt})

  llvmir_attach_opt_pass_target(
    TARGET ${PIPELINE_PREFIX}_opt1
    DEPENDS ${PIPELINE_PREFIX}_bc
    -mem2reg
    -mergereturn
    -simplifycfg
    -loop-simplify)
  add_dependencies(${PIPELINE_PREFIX}_opt1 ${PIPELINE_PREFIX}_bc)

  llvmir_attach_link_target(
    TARGET ${PIPELINE_PREFIX}_link
    DEPENDS ${PIPELINE_PREFIX}_opt1)
  add_dependencies(${PIPELINE_PREFIX}_link ${PIPELINE_PREFIX}_opt1)

  get_target_property(LINKER_LANG ${PIPELINE_PREFIX}_link LINKER_LANGUAGE)

  file(TO_CMAKE_PATH
    "${HARNESS_INPUT_DIR}/${BMK_NAME}/$ENV{ANNOTATELOOPS_WHITELIST_FILE}"
    PIPELINE_INPUT_FILE)

  if(LINK_LANGUAGE EQUAL "CXX")
    if(EXISTS ${PIPELINE_INPUT_FILE})
      set(PIPELINE_CMDLINE_ARG "-al-fn-whitelist=${PIPELINE_INPUT_FILE}")
    else()
      message(STATUS "could not find file: ${PIPELINE_INPUT_FILE}")
    endif()
  endif()

  llvmir_attach_opt_pass_target(
    TARGET ${PIPELINE_PREFIX}_opt2
    DEPENDS ${PIPELINE_PREFIX}_link
    -load ${ANNOTATELOOPS_LIB_LOCATION}
    -annotate-loops
    -al-loop-start-id=2
    -al-loop-id-interval=4
    -al-loop-lines
    -al-stats=${REPORT_FILE}
    ${PIPELINE_CMDLINE_ARG})
  add_dependencies(${PIPELINE_PREFIX}_opt2 ${PIPELINE_PREFIX}_link)

  llvmir_attach_executable(
    TARGET ${PIPELINE_PREFIX}_bc_exe
    DEPENDS ${PIPELINE_PREFIX}_opt2)
  add_dependencies(${PIPELINE_PREFIX}_bc_exe ${PIPELINE_PREFIX}_opt2)

  target_link_libraries(${PIPELINE_PREFIX}_bc_exe m)

  ## pipeline aggregate targets
  add_custom_target(${PIPELINE_SUBTARGET} DEPENDS
    ${PIPELINE_PREFIX}_bc
    ${PIPELINE_PREFIX}_opt1
    ${PIPELINE_PREFIX}_link
    ${PIPELINE_PREFIX}_opt2
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

