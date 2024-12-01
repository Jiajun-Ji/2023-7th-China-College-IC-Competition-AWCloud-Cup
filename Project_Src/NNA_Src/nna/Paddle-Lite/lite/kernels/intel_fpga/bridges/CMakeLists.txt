if (NOT LITE_WITH_INTEL_FPGA)
    return()
endif()
message(STATUS "++++++++INTEL_FPGA_SDK Library: ${intel_fpga_runtime_libs}")
lite_cc_library(subgraph_bridge_graph_intel_fpga SRCS graph.cc DEPS ${intel_fpga_runtime_libs})
lite_cc_library(subgraph_bridge_conv_op_intel_fpga SRCS conv_op.cc DEPS core subgraph_bridge_graph_intel_fpga)


set(intel_fpga_subgraph_bridges
        core
        subgraph_bridge_graph_intel_fpga
        subgraph_bridge_conv_op_intel_fpga
        CACHE INTERNAL "intel_fpga_subgraph_bridges")