# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required(VERSION 3.8.2)

include($ENV{ZEPHYR_BASE}/cmake/app/boilerplate.cmake NO_POLICY_SCOPE)
project(zephyr_native_posix)

set(IOTC_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../..)
set(IOTC_BSP_DIR ${IOTC_PATH}/third_party/zephyr_integration/zephyr_bsp)

target_include_directories(app PRIVATE ${IOTC_PATH}/examples/common/src)
target_include_directories(app PRIVATE ${IOTC_PATH}/include)
target_include_directories(app PRIVATE ${IOTC_PATH}/include/bsp)
target_include_directories(app PRIVATE ${IOTC_PATH}/src/libiotc)
target_include_directories(app PRIVATE ${IOTC_PATH}/src/libiotc/memory)
target_include_directories(app PRIVATE ${IOTC_PATH}/src/libiotc/io/fs)
target_include_directories(app PRIVATE ${IOTC_PATH}/src/libiotc/datastructures)
target_include_directories(app PRIVATE ${IOTC_PATH}/third_party/tls/mbedtls/include)

target_sources(app PRIVATE
	src/main.c
	${IOTC_PATH}/examples/common/src/commandline.c
	${IOTC_PATH}/examples/common/src/example_utils.c
	${IOTC_BSP_DIR}/iotc_bsp_io_fs_zephyr.c
	${IOTC_BSP_DIR}/iotc_bsp_io_net_zephyr.c
	${IOTC_BSP_DIR}/iotc_bsp_mem_zephyr.c
	${IOTC_BSP_DIR}/iotc_bsp_rng_zephyr.c
	${IOTC_BSP_DIR}/iotc_bsp_time_zephyr.c
	)

add_definitions(-DIOTC_TLS_LIB_MBEDTLS)

# libiotc
target_link_libraries(app PUBLIC ${IOTC_PATH}/bin/zephyr/libiotc.a)

# mbedTLS
set(IOTC_MBEDTLS_LIB_PATH ${IOTC_PATH}/third_party/tls/mbedtls/library)
target_link_libraries(app PUBLIC ${IOTC_MBEDTLS_LIB_PATH}/libmbedtls.a)
target_link_libraries(app PUBLIC ${IOTC_MBEDTLS_LIB_PATH}/libmbedx509.a)
target_link_libraries(app PUBLIC ${IOTC_MBEDTLS_LIB_PATH}/libmbedcrypto.a)

# wolfssl, disabled since wolfssl fails to build with -m32 flag (--enable-32bit)
#  target_link_libraries(app PUBLIC ${IOTC_PATH}/third_party/tls/wolfssl/src/.libs/libwolfssl.a)


zephyr_get_include_directories_for_lang_as_string(C includes)
zephyr_get_system_include_directories_for_lang_as_string(C system_includes)
zephyr_get_compile_definitions_for_lang_as_string(C definitions)
zephyr_get_compile_options_for_lang_as_string(C options)

add_custom_target(
  outputexports
  COMMAND echo CC="${CMAKE_C_COMPILER}"
  COMMAND echo AR="${CMAKE_AR}"
  COMMAND echo Z_CFLAGS=${system_includes} ${includes} ${definitions} ${options}
  VERBATIM
  USES_TERMINAL
)
