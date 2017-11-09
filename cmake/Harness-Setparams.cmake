# cmake file

include(CMakeParseArguments)

function(attach_setparams_target)
  set(options)
  set(oneValueArgs TARGET BMK_CLASS UTILITY_TARGET UTILITY_EXE)
  set(multiValueArgs)

  cmake_parse_arguments(SP "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

  set(ATTACHED_SP_TARGET ${SP_TARGET}_setparams)

  add_custom_target(${ATTACHED_SP_TARGET}
    COMMAND ${SP_UTILITY_EXE} ${SP_TARGET} ${SP_BMK_CLASS}
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Generating npbparams.h")

  add_dependencies(${SP_TARGET} ${ATTACHED_SP_TARGET})
  add_dependencies(${ATTACHED_SP_TARGET} ${SP_UTILITY_TARGET})
endfunction()

