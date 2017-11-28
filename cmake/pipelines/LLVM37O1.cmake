# cmake file

# this pipeline explicitly executes all the passes that are perfomed by LLVM at
# optimization level 2 (-O2) for version 3.7

macro(LLVM37O1PipelineSetupNames)
  set(PIPELINE_NAME "LLVM37O1")
  set(PIPELINE_INSTALL_TARGET "${PIPELINE_NAME}-install")
endmacro()

macro(LLVM37O1PipelineSetup)
  LLVM37O1PipelineSetupNames()

  message(STATUS "setting up pipeline ${PIPELINE_NAME}")
endmacro()

LLVM37O1PipelineSetup()

#

function(LLVM37O1Pipeline trgt)
  LLVM37O1PipelineSetupNames()

  if(NOT TARGET ${PIPELINE_NAME})
    add_custom_target(${PIPELINE_NAME})
  endif()

  set(PIPELINE_SUBTARGET "${PIPELINE_NAME}_${trgt}")
  set(PIPELINE_PREFIX ${PIPELINE_SUBTARGET})

  ## pipeline targets and chaining

  llvmir_attach_bc_target(
    TARGET ${PIPELINE_PREFIX}_bc
    DEPENDS ${trgt})
  add_dependencies(${PIPELINE_PREFIX}_bc ${trgt})

  llvmir_attach_opt_pass_target(
    TARGET ${PIPELINE_PREFIX}_optO0
    DEPENDS ${PIPELINE_PREFIX}_bc
    -targetlibinfo
    -tti
    -verify)
  add_dependencies(${PIPELINE_PREFIX}_optO0 ${PIPELINE_PREFIX}_bc)

  llvmir_attach_opt_pass_target(
    TARGET ${PIPELINE_PREFIX}_optO1
    DEPENDS ${PIPELINE_PREFIX}_optO0
    -no-aa
    -tbaa
    -scoped-noalias
    -assumption-cache-tracker
    -basicaa
    -simplifycfg
    -domtree
    -sroa
    -early-cse
    -lower-expect
    -no-aa
    -tbaa
    -scoped-noalias
    -assumption-cache-tracker
    -basicaa
    -ipsccp
    -globalopt
    -deadargelim
    -domtree
    -instcombine
    -simplifycfg
    -basiccg
    -prune-eh
    -inline-cost
    -always-inline
    -functionattrs
    -domtree
    -sroa
    -early-cse
    -lazy-value-info
    -jump-threading
    -correlated-propagation
    -simplifycfg
    -domtree
    -instcombine
    -tailcallelim
    -simplifycfg
    -reassociate
    -domtree
    -loops
    -loop-simplify
    -lcssa
    -loop-rotate
    -licm
    -loop-unswitch
    -instcombine
    -scalar-evolution
    -loop-simplify
    -lcssa
    -indvars
    -loop-idiom
    -loop-deletion
    -loop-unroll
    -memdep
    -memcpyopt
    -sccp
    -domtree
    -bdce
    -instcombine
    -lazy-value-info
    -jump-threading
    -correlated-propagation
    -domtree
    -memdep
    -dse
    -loops
    -loop-simplify
    -lcssa
    -licm
    -adce
    -simplifycfg
    -domtree
    -instcombine
    -barrier
    -float2int
    -domtree
    -loops
    -loop-simplify
    -lcssa
    -loop-rotate
    -branch-prob
    -block-freq
    -scalar-evolution
    -loop-accesses
    -loop-vectorize
    -instcombine
    -simplifycfg
    -domtree
    -instcombine
    -loops
    -loop-simplify
    -lcssa
    -scalar-evolution
    -loop-unroll
    -instcombine
    -loop-simplify
    -lcssa
    -licm
    -scalar-evolution
    -alignment-from-assumptions
    -strip-dead-prototypes
    )
  add_dependencies(${PIPELINE_PREFIX}_optO1 ${PIPELINE_PREFIX}_optO0)

  llvmir_attach_link_target(
    TARGET ${PIPELINE_PREFIX}_link
    DEPENDS ${PIPELINE_PREFIX}_optO1)
  add_dependencies(${PIPELINE_PREFIX}_link ${PIPELINE_PREFIX}_optO1)

  llvmir_attach_executable(
    TARGET ${PIPELINE_PREFIX}_bc_exe
    DEPENDS ${PIPELINE_PREFIX}_link)
  add_dependencies(${PIPELINE_PREFIX}_bc_exe ${PIPELINE_PREFIX}_link)

  target_link_libraries(${PIPELINE_PREFIX}_bc_exe m)

  ## pipeline aggregate targets
  add_custom_target(${PIPELINE_SUBTARGET} DEPENDS
    ${PIPELINE_PREFIX}_bc
    ${PIPELINE_PREFIX}_optO0
    ${PIPELINE_PREFIX}_optO1
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

