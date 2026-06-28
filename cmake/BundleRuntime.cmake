function(configure_runtime_bundle target_name)
  if(NOT TARGET ${target_name})
    message(FATAL_ERROR "Target '${target_name}' does not exist")
  endif()

  if(APPLE)
    set(_bundle_origin "@loader_path")
  elseif(UNIX)
    set(_bundle_origin "$ORIGIN")
  else()
    set(_bundle_origin "")
  endif()

  if(_bundle_origin)
    set_target_properties(${target_name} PROPERTIES
      BUILD_RPATH "${_bundle_origin};${_bundle_origin}/lib"
      INSTALL_RPATH "${_bundle_origin};${_bundle_origin}/lib"
      BUILD_RPATH_USE_ORIGIN ON
    )

    if(UNIX AND NOT APPLE)
      target_link_options(${target_name} PRIVATE -Wl,--disable-new-dtags)
    endif()
  endif()

  add_custom_target(bundle_${target_name}
    COMMAND ${CMAKE_COMMAND}
      -DINPUT_FILE=$<TARGET_FILE:${target_name}>
      -DOUTPUT_DIR=${PROJECT_BINARY_DIR}/bundle/${target_name}
      -DLIB_OUTPUT_DIR=${PROJECT_BINARY_DIR}/bundle/${target_name}/lib
      -DEXECUTABLE_NAME=$<TARGET_FILE_NAME:${target_name}>
      -DCOPY_BINARY=ON
      -P ${PROJECT_SOURCE_DIR}/cmake/copy_runtime_deps.cmake
    DEPENDS ${target_name}
    COMMENT "Bundling ${target_name} with runtime dependencies"
    VERBATIM
  )
endfunction()
