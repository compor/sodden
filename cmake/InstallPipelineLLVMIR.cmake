# cmake file

include(CMakeParseArguments)

function(InstallPipelineLLVMIR)
  set(options)
  set(oneValueArgs ATTACH_TO_TARGET DEPENDS BMK_NAME)
  set(multiValueArgs)

  cmake_parse_arguments(IPLLVMIR "${options}" "${oneValueArgs}"
    "${multiValueArgs}" ${ARGN})

  get_property(llvmir_dir TARGET ${IPLLVMIR_DEPENDS} PROPERTY LLVMIR_DIR)

  # strip trailing slashes
  string(REGEX REPLACE "(.*[^/]+)(//*)$" "\\1" llvmir_stripped_dir ${llvmir_dir})
  get_filename_component(llvmir_part_dir ${llvmir_stripped_dir} NAME)

  set(PIPELINE_DEST_SUBDIR
    ${CMAKE_INSTALL_PREFIX}/${IPLLVMIR_BMK_NAME}/llvm-ir/${llvmir_part_dir})

  set(PIPELINE_PART_INSTALL_TARGET "${IPLLVMIR_DEPENDS}-install")

  add_custom_target(${PIPELINE_PART_INSTALL_TARGET}
    COMMAND ${CMAKE_COMMAND} -E
    copy_directory ${llvmir_dir} ${PIPELINE_DEST_SUBDIR})

  add_dependencies(${PIPELINE_PART_INSTALL_TARGET} ${IPLLVMIR_DEPENDS})
  add_dependencies(${IPLLVMIR_ATTACH_TO_TARGET} ${PIPELINE_PART_INSTALL_TARGET})
endfunction()

