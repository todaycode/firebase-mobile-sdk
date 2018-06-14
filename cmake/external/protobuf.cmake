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

include(ExternalProject)

# protobuf ships CMake files but not at the root of the repo, which confuses
# CMake by default. CMake 3.7 introduced SOURCE_SUBDIR as a solution to this
# problem but that's too new to be the minimum version yet.
#
# Unfortunately, to work around this, you have to specify an alternate
# CONFIGURE_COMMAND, BUILD_COMMAND, and INSTALL_COMMAND and we need to replicate
# the logic to compose those commands here.

set(
  cmake_args
  -DCMAKE_INSTALL_PREFIX:STRING=${FIREBASE_INSTALL_DIR}
  -Dprotobuf_BUILD_TESTS=OFF
)

if(NOT CMAKE_CONFIGURATION_TYPES)
  list(APPEND cmake_args "-DCMAKE_BUILD_TYPE=$<CONFIG>")
endif()

if(NOT (CMAKE_VERSION VERSION_LESS "3.7"))
  set(
    ep_args
    SOURCE_SUBDIR cmake
    CMAKE_ARGS ${cmake_args}
  )

else()
  # Build up the CONFIGURE_COMMAND, which essentially is propagating the
  # CMAKE_GENERATOR, any CMAKE_ARGS, and supplying the source directory.
  set(configure "${CMAKE_COMMAND}")

  if(CMAKE_EXTRA_GENERATOR)
    list(APPEND configure "-G${CMAKE_EXTRA_GENERATOR} - ${CMAKE_GENERATOR}")
  else()
    list(APPEND configure "-G${CMAKE_GENERATOR}")
  endif()
  if (CMAKE_GENERATOR_PLATFORM)
    list(APPEND configure "-A${CMAKE_GENERATOR_PLATFORM}")
  endif()
  if (CMAKE_GENERATOR_TOOLSET)
    list(APPEND configure "-T${CMAKE_GENERATOR_TOOLSET}")
  endif()

  list(APPEND configure ${cmake_args} "<SOURCE_DIR>/cmake")

  # Build up the BUILD_COMMAND, which should invoke the default target and
  # pass along the current configuration if this is a multi-configuration
  # generator.
  set(build "${CMAKE_COMMAND}" --build ".")
  if(CMAKE_CONFIGURATION_TYPES)
    list(APPEND build --config $<CONFIG>)
  endif()

  # The INSTALL_COMMAND is just the BUILD_COMMAND manually specifying the
  # install target.
  set(install ${build} --target install)

  set(
    ep_args
    CONFIGURE_COMMAND ${configure}
    BUILD_COMMAND ${build}
    INSTALL_COMMAND ${install}
  )
endif()


ExternalProject_Add(
  protobuf

  DOWNLOAD_DIR ${PROJECT_BINARY_DIR}/downloads
  DOWNLOAD_NAME protobuf-v3.5.11.tar.gz
  URL https://github.com/google/protobuf/archive/v3.5.1.1.tar.gz
  URL_HASH SHA256=56b5d9e1ab2bf4f5736c4cfba9f4981fbc6976246721e7ded5602fbaee6d6869

  PREFIX ${PROJECT_BINARY_DIR}/external/protobuf

  ${ep_args}

  UPDATE_COMMAND ""
  TEST_COMMAND ""
)
