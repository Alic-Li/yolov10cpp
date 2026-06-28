cmake_minimum_required(VERSION 3.19)

if(NOT DEFINED INPUT_FILE OR INPUT_FILE STREQUAL "")
  message(FATAL_ERROR "INPUT_FILE is required")
endif()
if(NOT DEFINED OUTPUT_DIR OR OUTPUT_DIR STREQUAL "")
  message(FATAL_ERROR "OUTPUT_DIR is required")
endif()
if(NOT DEFINED LIB_OUTPUT_DIR OR LIB_OUTPUT_DIR STREQUAL "")
  set(LIB_OUTPUT_DIR "${OUTPUT_DIR}")
endif()

set(COPY_BINARY "${COPY_BINARY}")
if(COPY_BINARY STREQUAL "")
  set(COPY_BINARY OFF)
endif()

get_filename_component(INPUT_FILE "${INPUT_FILE}" ABSOLUTE)
get_filename_component(OUTPUT_DIR "${OUTPUT_DIR}" ABSOLUTE)
get_filename_component(LIB_OUTPUT_DIR "${LIB_OUTPUT_DIR}" ABSOLUTE)

file(MAKE_DIRECTORY "${OUTPUT_DIR}")
file(MAKE_DIRECTORY "${LIB_OUTPUT_DIR}")

if(COPY_BINARY)
  file(COPY "${INPUT_FILE}" DESTINATION "${OUTPUT_DIR}")
endif()

if(UNIX AND DEFINED EXECUTABLE_NAME AND NOT EXECUTABLE_NAME STREQUAL "")
  if(APPLE)
    set(_library_path_var "DYLD_LIBRARY_PATH")
  else()
    set(_library_path_var "LD_LIBRARY_PATH")
  endif()

  set(_launcher "${OUTPUT_DIR}/run_${EXECUTABLE_NAME}.sh")
  file(WRITE "${_launcher}"
"#!/usr/bin/env sh
set -eu
SCRIPT_DIR=\"$(CDPATH= cd -- \"$(dirname -- \"$0\")\" && pwd)\"
export ${_library_path_var}=\"\${SCRIPT_DIR}/lib\${${_library_path_var}:+:\${${_library_path_var}}}\"
exec \"\${SCRIPT_DIR}/${EXECUTABLE_NAME}\" \"$@\"
")
  file(CHMOD "${_launcher}"
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                GROUP_READ GROUP_EXECUTE
                WORLD_READ WORLD_EXECUTE
  )
endif()

file(GET_RUNTIME_DEPENDENCIES
  EXECUTABLES "${INPUT_FILE}"
  RESOLVED_DEPENDENCIES_VAR resolved_deps
  UNRESOLVED_DEPENDENCIES_VAR unresolved_deps
  POST_EXCLUDE_REGEXES
    "^api-ms-win-"
    "^ext-ms-win-"
)

function(should_skip_dep dep out_var)
  set(skip FALSE)
  if(WIN32)
    if(dep MATCHES "^[A-Za-z]:[/\\\\]Windows[/\\\\](System32|SysWOW64)[/\\\\]")
      set(skip TRUE)
    endif()
  elseif(APPLE)
    if(dep MATCHES "^/usr/lib/lib(System|c\\+\\+|objc|m)\\..*dylib$")
      set(skip TRUE)
    endif()
  elseif(UNIX)
    if(dep MATCHES "^/lib.*/ld-linux[^/]*\\.so(\\.[^/]+)*$")
      set(skip TRUE)
    elseif(dep MATCHES "^/usr/lib.*/ld-linux[^/]*\\.so(\\.[^/]+)*$")
      set(skip TRUE)
    elseif(dep MATCHES "^/lib.*/lib(c|m|pthread|dl|rt|util|resolv|nsl|anl)\\.so(\\.[^/]+)*$")
      set(skip TRUE)
    elseif(dep MATCHES "^/usr/lib.*/lib(c|m|pthread|dl|rt|util|resolv|nsl|anl)\\.so(\\.[^/]+)*$")
      set(skip TRUE)
    endif()
  endif()
  set(${out_var} "${skip}" PARENT_SCOPE)
endfunction()

function(copy_dep dep destination_dir)
  get_filename_component(dep_name "${dep}" NAME)
  file(REAL_PATH "${dep}" dep_real)
  file(COPY_FILE "${dep_real}" "${destination_dir}/${dep_name}" ONLY_IF_DIFFERENT)
endfunction()

foreach(dep IN LISTS resolved_deps)
  should_skip_dep("${dep}" skip_dep)
  if(skip_dep)
    continue()
  endif()
  copy_dep("${dep}" "${LIB_OUTPUT_DIR}")
endforeach()

file(GLOB copied_loader_files
  "${LIB_OUTPUT_DIR}/ld-linux*.so"
  "${LIB_OUTPUT_DIR}/ld-linux*.so.*"
  "${LIB_OUTPUT_DIR}/ld-*.so"
  "${LIB_OUTPUT_DIR}/ld-*.so.*"
)
if(copied_loader_files)
  file(REMOVE ${copied_loader_files})
endif()

if(unresolved_deps)
  list(JOIN unresolved_deps ", " unresolved_text)
  message(WARNING "Unresolved runtime dependencies for ${INPUT_FILE}: ${unresolved_text}")
endif()
