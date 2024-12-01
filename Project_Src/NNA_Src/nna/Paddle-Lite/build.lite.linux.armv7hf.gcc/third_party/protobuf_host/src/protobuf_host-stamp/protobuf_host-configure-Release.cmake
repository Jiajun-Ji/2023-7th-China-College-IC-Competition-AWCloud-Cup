

set(command "/opt/software/cmake-3.10.3-Linux-x86_64/bin/cmake;-DCMAKE_C_COMPILER=/usr/bin/gcc;-DCMAKE_CXX_COMPILER=/usr/bin/g++;-Dprotobuf_WITH_ZLIB=OFF;-DZLIB_ROOT:FILEPATH=;-Dprotobuf_BUILD_TESTS=OFF;-DCMAKE_SKIP_RPATH=ON;-DCMAKE_POSITION_INDEPENDENT_CODE=ON;-DCMAKE_BUILD_TYPE=MinSizeRel;-DCMAKE_INSTALL_PREFIX=/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/install/protobuf_host;-DCMAKE_INSTALL_LIBDIR=lib;-DBUILD_SHARED_LIBS=OFF;-C/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/protobuf_host/tmp/protobuf_host-cache-Release.cmake;-GUnix Makefiles;/opt/nna/Paddle-Lite/third-party/protobuf-host/cmake")
execute_process(
  COMMAND ${command}
  RESULT_VARIABLE result
  OUTPUT_FILE "/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/protobuf_host/src/protobuf_host-stamp/protobuf_host-configure-out.log"
  ERROR_FILE "/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/protobuf_host/src/protobuf_host-stamp/protobuf_host-configure-err.log"
  )
if(result)
  set(msg "Command failed: ${result}\n")
  foreach(arg IN LISTS command)
    set(msg "${msg} '${arg}'")
  endforeach()
  set(msg "${msg}\nSee also\n  /opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/protobuf_host/src/protobuf_host-stamp/protobuf_host-configure-*.log")
  message(FATAL_ERROR "${msg}")
else()
  set(msg "protobuf_host configure command succeeded.  See also /opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/protobuf_host/src/protobuf_host-stamp/protobuf_host-configure-*.log")
  message(STATUS "${msg}")
endif()
