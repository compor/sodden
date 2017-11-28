# cmake file

message(STATUS "setting up pipeline: BmkBasicInstall")

function(BmkBasicInstallPipeline trgt)
  get_property(bmk_name TARGET ${trgt} PROPERTY BMK_NAME)

  set(DEST_DIR "${bmk_name}")
  set(BMK_BIN_NAME "${trgt}")
  set(BMK_BIN_PREAMBLE "")
  set(PIPELINE_SCRIPT_PREFIX "")

  install(TARGETS ${trgt} RUNTIME DESTINATION ${DEST_DIR} OPTIONAL)

  configure_file("scripts/_run.sh.in" "scripts/run.sh" @ONLY)

  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/scripts/
    DESTINATION ${DEST_DIR}
    PATTERN "*.sh"
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE)
endfunction()

