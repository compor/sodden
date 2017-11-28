# cmake file

message(STATUS "setting up pipeline SimplifyLoopExitsFront")

find_package(SimplifyLoopExitsFront CONFIG)

if(NOT SimplifyLoopExitsFront_FOUND)
  message(WARNING "package SimplifyLoopExitsFront was not found; skipping.")

  return()
endif()

get_target_property(SLEF_LIB_LOCATION LLVMSimplifyLoopExitsFrontPass LOCATION)
get_target_property(DEPENDEE LLVMSimplifyLoopExitsFrontPass DEPENDEE)

# configuration

macro(SimplifyLoopExitsFrontPipelineSetup)
  set(PIPELINE_NAME "SimplifyLoopExitsFront")
  set(PIPELINE_INSTALL_TARGET "${PIPELINE_NAME}-install")
endmacro()


function(SimplifyLoopExitsFrontPipeline trgt)
  SimplifyLoopExitsFrontPipelineSetup()

  if(NOT TARGET ${PIPELINE_NAME})
    add_custom_target(${PIPELINE_NAME})
  endif()

  set(PIPELINE_SUBTARGET "${PIPELINE_NAME}_${trgt}")
  set(PIPELINE_PREFIX ${PIPELINE_SUBTARGET})

  set(DEPENDEE_TRGT "AnnotateLoops_${trgt}_opt2")

  ## pipeline targets and chaining

  set(LOAD_DEPENDENCY_CMDLINE_ARG "")
  if(DEPENDEE)
    foreach(dep ${DEPENDEE})
      list(APPEND LOAD_DEPENDENCY_CMDLINE_ARG -load;${dep})
    endforeach()
  endif()

  set(PIPELINE_INPUT_FILE
    "$ENV{HARNESS_INPUT_DIR}${BMK_NAME}/$ENV{SLEF_LOOP_ID_WHITELIST_FILE}")

  if(EXISTS ${PIPELINE_INPUT_FILE})
    set(PIPELINE_CMDLINE_ARG "-slef-loop-id-whitelist=${PIPELINE_INPUT_FILE}")
  else()
    message(STATUS "could not find file: ${PIPELINE_INPUT_FILE}")
  endif()

  llvmir_attach_opt_pass_target(${PIPELINE_PREFIX}_link
    ${DEPENDEE_TRGT}
    ${LOAD_DEPENDENCY_CMDLINE_ARG}
    -load ${SLEF_LIB_LOCATION}
    -simplify-loop-exits-front
    -slef-loop-depth-ub=1
    -slef-loop-exiting-block-depth-ub=1
    ${PIPELINE_CMDLINE_ARG})
  add_dependencies(${PIPELINE_PREFIX}_link ${DEPENDEE_TRGT})

  #-slef-stats=${HARNESS_REPORT_DIR}/${BMK_NAME}-${PIPELINE_NAME}.txt

  llvmir_attach_executable(${PIPELINE_PREFIX}_bc_exe ${PIPELINE_PREFIX}_link)
  add_dependencies(${PIPELINE_PREFIX}_bc_exe ${PIPELINE_PREFIX}_link)

  target_link_libraries(${PIPELINE_PREFIX}_bc_exe m)

  ## pipeline aggregate targets
  add_custom_target(${PIPELINE_SUBTARGET} DEPENDS
    ${DEPENDEE_TRGT}
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

