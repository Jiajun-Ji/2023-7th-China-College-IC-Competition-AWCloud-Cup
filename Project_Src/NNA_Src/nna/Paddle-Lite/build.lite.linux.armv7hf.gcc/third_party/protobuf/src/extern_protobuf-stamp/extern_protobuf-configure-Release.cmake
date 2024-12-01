

set(command "/opt/software/cmake-3.10.3-Linux-x86_64/bin/cmake;-Dprotobuf_WITH_ZLIB=OFF;-DCMAKE_SYSTEM_NAME=Linux;-DCMAKE_SYSTEM_VERSION=;-DCMAKE_CXX_COMPILER=/opt/software/gcc-linaro-5.4.1-2017.05-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-g++;-DCMAKE_C_COMPILER=/opt/software/gcc-linaro-5.4.1-2017.05-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-gcc;-DCMAKE_C_FLAGS=-march=armv7-a -mfloat-abi=hard -mfpu=neon   -fPIC -fopenmp;-DCMAKE_C_FLAGS_DEBUG=-g;-DCMAKE_C_FLAGS_RELEASE=-O3 -DNDEBUG;-DCMAKE_CXX_FLAGS=-march=armv7-a -mfloat-abi=hard -mfpu=neon   -fPIC -std=c++11 -fexceptions -fasynchronous-unwind-tables -funwind-tables -fexceptions -fasynchronous-unwind-tables -funwind-tables -fopenmp;-DCMAKE_CXX_FLAGS_RELEASE=-O3 -DNDEBUG;-DCMAKE_CXX_FLAGS_DEBUG=-g;-Dprotobuf_BUILD_TESTS=OFF;-DCMAKE_SKIP_RPATH=ON;-DCMAKE_POSITION_INDEPENDENT_CODE=ON;-DCMAKE_BUILD_TYPE=MinSizeRel;-DCMAKE_INSTALL_PREFIX=/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/install/protobuf;-DCMAKE_INSTALL_LIBDIR=lib;-DBUILD_SHARED_LIBS=OFF;-C/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/protobuf/tmp/extern_protobuf-cache-Release.cmake;-GUnix Makefiles;/opt/nna/Paddle-Lite/third-party/protobuf-mobile/cmake")
execute_process(
  COMMAND ${command}
  RESULT_VARIABLE result
  OUTPUT_FILE "/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/protobuf/src/extern_protobuf-stamp/extern_protobuf-configure-out.log"
  ERROR_FILE "/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/protobuf/src/extern_protobuf-stamp/extern_protobuf-configure-err.log"
  )
if(result)
  set(msg "Command failed: ${result}\n")
  foreach(arg IN LISTS command)
    set(msg "${msg} '${arg}'")
  endforeach()
  set(msg "${msg}\nSee also\n  /opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/protobuf/src/extern_protobuf-stamp/extern_protobuf-configure-*.log")
  message(FATAL_ERROR "${msg}")
else()
  set(msg "extern_protobuf configure command succeeded.  See also /opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/protobuf/src/extern_protobuf-stamp/extern_protobuf-configure-*.log")
  message(STATUS "${msg}")
endif()
