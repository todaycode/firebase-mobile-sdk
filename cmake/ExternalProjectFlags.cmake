# Copyright 2018 Google
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include(CMakeParseArguments)

function(ExternalProject_BuildCommand RESULT_VAR)
  # Parse arguments
  set(options "")
  set(single_value "TARGET")
  set(multi_value "")
  cmake_parse_arguments(EP "${options}" "${single_value}" "${multi_value}" ${ARGN})

  set(build "${CMAKE_COMMAND}" --build ".")
  if(CMAKE_CONFIGURATION_TYPES)
    list(APPEND build --config $<CONFIG>)
  endif()

  if(EP_TARGET)
    list(APPEND build --target "${EP_TARGET}")
  endif()

  set(${RESULT_VAR} ${build} PARENT_SCOPE)
endfunction()

function(ExternalProject_StandardArgs RESULT_VAR NAME)
  # Parse arguments
  set(options "ENABLE_TESTS")
  set(single_value "")
  set(multi_value "CMAKE_ARGS")
  cmake_parse_arguments(EP "${options}" "${single_value}" "${multi_value}" ${ARGN})

  set(
    cmake_args
    -DCMAKE_INSTALL_PREFIX:STRING=<INSTALL_DIR>
    -DBUILD_SHARED_LIBS:BOOL=OFF
  )

  # Pass through the current CMAKE_BUILD_TYPE only if this is a
  # single-configuration generator.
  if(NOT CMAKE_CONFIGURATION_TYPES)
    list(APPEND cmake_args "-DCMAKE_BUILD_TYPE=$<CONFIG>")
  endif()

  # Path through any user-supplied arguments
  list(APPEND cmake_args ${EP_CMAKE_ARGS})

  set(
    result
    PREFIX "${PROJECT_BINARY_DIR}/external/${NAME}"
    DOWNLOAD_DIR "${PROJECT_BINARY_DIR}/downloads"
    INSTALL_DIR "${PROJECT_BINARY_DIR}/opt"
    CMAKE_ARGS ${cmake_args}
    UPDATE_COMMAND ""
  )

  if(NOT EP_ENABLE_TESTS)
    list(APPEND result TEST_COMMAND "")
  endif()

  set("${RESULT_VAR}" ${result} PARENT_SCOPE)
  set("${RESULT_VAR}_CMAKE_ARGS}" ${cmake_args} PARENT_SCOPE)
endfunction()

# Assemble the git-related arguments to an external project making use of the
# latest features where available but avoiding them when run under CMake
# versions that don't support them.
#
# The complete set of git-related arguments are stored as a list in the
# variable named by RESULT_VAR in the calling scope.
#
# Currently this handles:
#   * GIT_SUBMODULES -- added on CMake 3.0 or later. Earlier CMakes will
#       check out all submodules.
#   * GIT_SHALLOW -- added by default on CMake 3.6 or later. Disable by passing
#       GIT_SHALLOW OFF
#   * GIT_PROGRESS -- added by default on CMake 3.8 or later. Disable by
#       passing GIT_PROGRESS OFF
function(ExternalProject_GitSource RESULT_VAR)
  # Parse arguments
  set(options "")
  set(single_value GIT_REPOSITORY GIT_TAG GIT_PROGRESS GIT_SHALLOW)
  set(multi_value GIT_SUBMODULES)
  cmake_parse_arguments(EP "${options}" "${single_value}" "${multi_value}" ${ARGN})

  set(
    result
    GIT_REPOSITORY ${EP_GIT_REPOSITORY}
    GIT_TAG ${EP_GIT_TAG}
    ${EP_UNPARSED_ARGUMENTS}
  )

  # CMake 3.0 added support for constraining the set of submodules to clone
  if(NOT (CMAKE_VERSION VERSION_LESS "3.0") AND EP_GIT_SUBMODULES)
    list(APPEND result GIT_SUBMODULES ${EP_GIT_SUBMODULES})
  endif()

  # CMake 3.6 added support for shallow git clones. Use a shallow clone if
  # available
  if(NOT (CMAKE_VERSION VERSION_LESS "3.6"))
    if(NOT EP_GIT_SHALLOW)
      set(EP_GIT_SHALLOW ON)
    endif()

    list(APPEND result GIT_SHALLOW ${EP_GIT_SHALLOW})
  endif()

  # CMake 3.8 added support for showing progress for large downloads
  if(NOT (CMAKE_VERSION VERSION_LESS "3.8"))
    if(NOT EP_GIT_PROGRESS)
      set(EP_GIT_PROGRESS ON)
    endif()

    list(APPEND result GIT_PROGRESS ${EP_GIT_PROGRESS})
  endif()

  set(${RESULT_VAR} ${result} PARENT_SCOPE)

endfunction()
