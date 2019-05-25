set -ex

make PRESET=ZEPHYR IOTC_USE_EXTERNAL_TLS_LIB=1 IOTC_TLS_LIB_INC_DIR=. \
    CONFIG=memory_fs-posix_platform-tls_bsp-memory_limiter-no_certverify

cd third_party/zephyr_integration/zephyr_native_posix/build
#cd examples/zephyr_native_posix/build
make
