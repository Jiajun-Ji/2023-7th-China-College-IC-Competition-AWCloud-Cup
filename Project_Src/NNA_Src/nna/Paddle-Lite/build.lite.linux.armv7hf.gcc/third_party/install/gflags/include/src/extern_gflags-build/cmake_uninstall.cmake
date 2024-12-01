if(NOT EXISTS "/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/install/gflags/include/src/extern_gflags-build/install_manifest.txt")
  message(FATAL_ERROR "Cannot find install manifest: /opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/install/gflags/include/src/extern_gflags-build/install_manifest.txt")
endif(NOT EXISTS "/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/install/gflags/include/src/extern_gflags-build/install_manifest.txt")

if (NOT DEFINED CMAKE_INSTALL_PREFIX)
  set (CMAKE_INSTALL_PREFIX "/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/install/gflags")
endif ()
 message(${CMAKE_INSTALL_PREFIX})

file(READ "/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/third_party/install/gflags/include/src/extern_gflags-build/install_manifest.txt" files)
string(REGEX REPLACE "\n" ";" files "${files}")
foreach(file ${files})
  message(STATUS "Uninstalling $ENV{DESTDIR}${file}")
  if(IS_SYMLINK "$ENV{DESTDIR}${file}" OR EXISTS "$ENV{DESTDIR}${file}")
    exec_program(
      "/opt/software/cmake-3.10.3-Linux-x86_64/bin/cmake" ARGS "-E remove \"$ENV{DESTDIR}${file}\""
      OUTPUT_VARIABLE rm_out
      RETURN_VALUE rm_retval
      )
    if(NOT "${rm_retval}" STREQUAL 0)
      message(FATAL_ERROR "Problem when removing $ENV{DESTDIR}${file}")
    endif(NOT "${rm_retval}" STREQUAL 0)
  else(IS_SYMLINK "$ENV{DESTDIR}${file}" OR EXISTS "$ENV{DESTDIR}${file}")
    message(STATUS "File $ENV{DESTDIR}${file} does not exist.")
  endif(IS_SYMLINK "$ENV{DESTDIR}${file}" OR EXISTS "$ENV{DESTDIR}${file}")
endforeach(file)
