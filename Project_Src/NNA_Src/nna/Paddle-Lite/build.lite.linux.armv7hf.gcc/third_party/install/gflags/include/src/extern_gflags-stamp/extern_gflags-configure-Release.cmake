

set(command "/opt/software/cmake-3.10.3-Linux-x86_64/bin/cmake;-DBUILD_STATIC_LIBS=ON;-DCMAKE_INSTALL_PREFIX=/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/install/gflags;-DCMAKE_POSITION_INDEPENDENT_CODE=ON;-DBUILD_TESTING=OFF;-DCMAKE_BUILD_TYPE=MinSizeRel;-DCMAKE_SYSTEM_NAME=Linux;-DCMAKE_SYSTEM_VERSION=;-DCMAKE_CXX_COMPILER=/opt/software/gcc-linaro-5.4.1-2017.05-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-g++;-DCMAKE_C_COMPILER=/opt/software/gcc-linaro-5.4.1-2017.05-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-gcc;-DCMAKE_CXX_FLAGS=-march=armv7-a -mfloat-abi=hard -mfpu=neon   -fPIC -std=c++11 -fexceptions -fasynchronous-unwind-tables -funwind-tables -fexceptions -fasynchronous-unwind-tables -funwind-tables -fopenmp;-DCMAKE_CXX_FLAGS_RELEASE=-O3 -DNDEBUG;-DCMAKE_CXX_FLAGS_DEBUG=-g;-DCMAKE_C_FLAGS=-march=armv7-a -mfloat-abi=hard -mfpu=neon   -fPIC -fopenmp;-DCMAKE_C_FLAGS_DEBUG=-g;-DCMAKE_C_FLAGS_RELEASE=-O3 -DNDEBUG;-C/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/install/gflags/include/tmp/extern_gflags-cache-Release.cmake;-GUnix Makefiles;/opt/nna/Paddle-Lite/third-party/gflags")
execute_process(
  COMMAND ${command}
  RESULT_VARIABLE result
  OUTPUT_FILE "/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/install/gflags/include/src/extern_gflags-stamp/extern_gflags-configure-out.log"
  ERROR_FILE "/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/install/gflags/include/src/extern_gflags-stamp/extern_gflags-configure-err.log"
  )
if(result)
  set(msg "Command failed: ${result}\n")
  foreach(arg IN LISTS command)
    set(msg "${msg} '${arg}'")
  endforeach()
  set(msg "${msg}\nSee also\n  /opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/install/gflags/include/src/extern_gflags-stamp/extern_gflags-configure-*.log")
  message(FATAL_ERROR "${msg}")
else()
  set(msg "extern_gflags configure command succeeded.  See also /opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/install/gflags/include/src/extern_gflags-stamp/extern_gflags-configure-*.log")
  message(STATUS "${msg}")
endif()
