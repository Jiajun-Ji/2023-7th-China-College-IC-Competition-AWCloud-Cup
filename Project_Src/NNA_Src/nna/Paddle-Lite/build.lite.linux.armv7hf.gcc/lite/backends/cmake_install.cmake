# Install script for directory: /opt/nna/Paddle-Lite/lite/backends

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
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/backends/opencl/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/backends/arm/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/backends/x86/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/backends/cuda/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/backends/fpga/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/backends/host/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/backends/npu/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/backends/xpu/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/backends/mlu/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/backends/bm/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/backends/metal/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/backends/intel_fpga/cmake_install.cmake")
  include("/opt/nna/Paddle-Lite/build.lite.linux.armv7hf.gcc/lite/backends/nnadapter/cmake_install.cmake")

endif()

