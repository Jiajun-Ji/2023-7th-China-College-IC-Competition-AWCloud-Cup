# Install script for directory: /opt/nna/Paddle-Lite/lite/kernels

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/usr/local")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "0")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "TRUE")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/kernels/host/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/kernels/arm/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/kernels/cuda/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/kernels/x86/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/kernels/opencl/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/kernels/fpga/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/kernels/npu/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/kernels/xpu/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/kernels/mlu/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/kernels/bm/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/kernels/metal/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/kernels/intel_fpga/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/kernels/nnadapter/cmake_install.cmake")

endif()

