# TCL File Generated by Component Editor 18.1
# Fri Jul 14 15:43:22 CST 2023
# DO NOT MODIFY


# 
# dvp_ddr3_vga_top "dvp_ddr3_vga_top" v1.0
# zhangfeng 2023.07.14.15:43:22
# dvp_ddr3_vga_top
# 

# 
# request TCL package from ACDS 16.1
# 
package require -exact qsys 16.1


# 
# module dvp_ddr3_vga_top
# 
set_module_property DESCRIPTION dvp_ddr3_vga_top
set_module_property NAME dvp_ddr3_vga_top
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP CoreCourse
set_module_property AUTHOR zhangfeng
set_module_property DISPLAY_NAME dvp_ddr3_vga_top
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL dvp_ddr3_vga_top
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file burst_read_master.v VERILOG PATH ip/dvp_ddr3_vga/burst_read_master.v
add_fileset_file burst_write_master.v VERILOG PATH ip/dvp_ddr3_vga/burst_write_master.v
add_fileset_file ddr3_read.v VERILOG PATH ip/dvp_ddr3_vga/ddr3_read.v
add_fileset_file ddr3_vga_ctrl.v VERILOG PATH ip/dvp_ddr3_vga/ddr3_vga_ctrl.v
add_fileset_file ddr3_vga_top.v VERILOG PATH ip/dvp_ddr3_vga/ddr3_vga_top.v
add_fileset_file ddr3_write.v VERILOG PATH ip/dvp_ddr3_vga/ddr3_write.v
add_fileset_file dvp_ddr3_ctrl.v VERILOG PATH ip/dvp_ddr3_vga/dvp_ddr3_ctrl.v
add_fileset_file dvp_ddr3_top.v VERILOG PATH ip/dvp_ddr3_vga/dvp_ddr3_top.v
add_fileset_file dvp_ddr3_vga_top.v VERILOG PATH ip/dvp_ddr3_vga/dvp_ddr3_vga_top.v TOP_LEVEL_FILE
add_fileset_file dvp_rgb888.v VERILOG PATH ip/dvp_ddr3_vga/dvp_rgb888.v
add_fileset_file latency_aware_read_master.v VERILOG PATH ip/dvp_ddr3_vga/latency_aware_read_master.v
add_fileset_file vga_ctrl.v VERILOG PATH ip/dvp_ddr3_vga/vga_ctrl.v
add_fileset_file vip.v VERILOG PATH ip/dvp_ddr3_vga/vip.v
add_fileset_file write_master.v VERILOG PATH ip/dvp_ddr3_vga/write_master.v
add_fileset_file asyn_fifo.v VERILOG PATH ip/dvp_ddr3_vga/asyn_fifo.v
add_fileset_file bilinear_interpolation.v VERILOG PATH ip/dvp_ddr3_vga/bilinear_interpolation.v
add_fileset_file bram_ture_dual_port.v VERILOG PATH ip/dvp_ddr3_vga/bram_ture_dual_port.v
add_fileset_file dvp_gray.v VERILOG PATH ip/dvp_ddr3_vga/dvp_gray.v
add_fileset_file resize_top.v VERILOG PATH ip/dvp_ddr3_vga/resize_top.v
add_fileset_file rgb2gray.v VERILOG PATH ip/dvp_ddr3_vga/rgb2gray.v


# 
# parameters
# 
add_parameter DVP_USER_DATA_WIDTH INTEGER 128
set_parameter_property DVP_USER_DATA_WIDTH DEFAULT_VALUE 128
set_parameter_property DVP_USER_DATA_WIDTH DISPLAY_NAME DVP_USER_DATA_WIDTH
set_parameter_property DVP_USER_DATA_WIDTH TYPE INTEGER
set_parameter_property DVP_USER_DATA_WIDTH UNITS None
set_parameter_property DVP_USER_DATA_WIDTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property DVP_USER_DATA_WIDTH HDL_PARAMETER true
add_parameter DVP_AVALON_DATA_WIDTH INTEGER 128
set_parameter_property DVP_AVALON_DATA_WIDTH DEFAULT_VALUE 128
set_parameter_property DVP_AVALON_DATA_WIDTH DISPLAY_NAME DVP_AVALON_DATA_WIDTH
set_parameter_property DVP_AVALON_DATA_WIDTH TYPE INTEGER
set_parameter_property DVP_AVALON_DATA_WIDTH UNITS None
set_parameter_property DVP_AVALON_DATA_WIDTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property DVP_AVALON_DATA_WIDTH HDL_PARAMETER true
add_parameter DVP_MEMORY_BASED_FIFO INTEGER 1
set_parameter_property DVP_MEMORY_BASED_FIFO DEFAULT_VALUE 1
set_parameter_property DVP_MEMORY_BASED_FIFO DISPLAY_NAME DVP_MEMORY_BASED_FIFO
set_parameter_property DVP_MEMORY_BASED_FIFO TYPE INTEGER
set_parameter_property DVP_MEMORY_BASED_FIFO UNITS None
set_parameter_property DVP_MEMORY_BASED_FIFO ALLOWED_RANGES -2147483648:2147483647
set_parameter_property DVP_MEMORY_BASED_FIFO HDL_PARAMETER true
add_parameter DVP_FIFO_DEPTH INTEGER 256
set_parameter_property DVP_FIFO_DEPTH DEFAULT_VALUE 256
set_parameter_property DVP_FIFO_DEPTH DISPLAY_NAME DVP_FIFO_DEPTH
set_parameter_property DVP_FIFO_DEPTH TYPE INTEGER
set_parameter_property DVP_FIFO_DEPTH UNITS None
set_parameter_property DVP_FIFO_DEPTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property DVP_FIFO_DEPTH HDL_PARAMETER true
add_parameter DVP_FIFO_DEPTH_LOG2 INTEGER 8
set_parameter_property DVP_FIFO_DEPTH_LOG2 DEFAULT_VALUE 8
set_parameter_property DVP_FIFO_DEPTH_LOG2 DISPLAY_NAME DVP_FIFO_DEPTH_LOG2
set_parameter_property DVP_FIFO_DEPTH_LOG2 TYPE INTEGER
set_parameter_property DVP_FIFO_DEPTH_LOG2 UNITS None
set_parameter_property DVP_FIFO_DEPTH_LOG2 ALLOWED_RANGES -2147483648:2147483647
set_parameter_property DVP_FIFO_DEPTH_LOG2 HDL_PARAMETER true
add_parameter DVP_ADDRESS_WIDTH INTEGER 32
set_parameter_property DVP_ADDRESS_WIDTH DEFAULT_VALUE 32
set_parameter_property DVP_ADDRESS_WIDTH DISPLAY_NAME DVP_ADDRESS_WIDTH
set_parameter_property DVP_ADDRESS_WIDTH TYPE INTEGER
set_parameter_property DVP_ADDRESS_WIDTH UNITS None
set_parameter_property DVP_ADDRESS_WIDTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property DVP_ADDRESS_WIDTH HDL_PARAMETER true
add_parameter DVP_BURST_CAPABLE INTEGER 1
set_parameter_property DVP_BURST_CAPABLE DEFAULT_VALUE 1
set_parameter_property DVP_BURST_CAPABLE DISPLAY_NAME DVP_BURST_CAPABLE
set_parameter_property DVP_BURST_CAPABLE TYPE INTEGER
set_parameter_property DVP_BURST_CAPABLE UNITS None
set_parameter_property DVP_BURST_CAPABLE ALLOWED_RANGES -2147483648:2147483647
set_parameter_property DVP_BURST_CAPABLE HDL_PARAMETER true
add_parameter DVP_MAXIMUM_BURST_COUNT INTEGER 16
set_parameter_property DVP_MAXIMUM_BURST_COUNT DEFAULT_VALUE 16
set_parameter_property DVP_MAXIMUM_BURST_COUNT DISPLAY_NAME DVP_MAXIMUM_BURST_COUNT
set_parameter_property DVP_MAXIMUM_BURST_COUNT TYPE INTEGER
set_parameter_property DVP_MAXIMUM_BURST_COUNT UNITS None
set_parameter_property DVP_MAXIMUM_BURST_COUNT ALLOWED_RANGES -2147483648:2147483647
set_parameter_property DVP_MAXIMUM_BURST_COUNT HDL_PARAMETER true
add_parameter DVP_BURST_COUNT_WIDTH INTEGER 5
set_parameter_property DVP_BURST_COUNT_WIDTH DEFAULT_VALUE 5
set_parameter_property DVP_BURST_COUNT_WIDTH DISPLAY_NAME DVP_BURST_COUNT_WIDTH
set_parameter_property DVP_BURST_COUNT_WIDTH TYPE INTEGER
set_parameter_property DVP_BURST_COUNT_WIDTH UNITS None
set_parameter_property DVP_BURST_COUNT_WIDTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property DVP_BURST_COUNT_WIDTH HDL_PARAMETER true
add_parameter VGA_USER_DATA_WIDTH INTEGER 128
set_parameter_property VGA_USER_DATA_WIDTH DEFAULT_VALUE 128
set_parameter_property VGA_USER_DATA_WIDTH DISPLAY_NAME VGA_USER_DATA_WIDTH
set_parameter_property VGA_USER_DATA_WIDTH TYPE INTEGER
set_parameter_property VGA_USER_DATA_WIDTH UNITS None
set_parameter_property VGA_USER_DATA_WIDTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property VGA_USER_DATA_WIDTH HDL_PARAMETER true
add_parameter VGA_AVALON_DATA_WIDTH INTEGER 128
set_parameter_property VGA_AVALON_DATA_WIDTH DEFAULT_VALUE 128
set_parameter_property VGA_AVALON_DATA_WIDTH DISPLAY_NAME VGA_AVALON_DATA_WIDTH
set_parameter_property VGA_AVALON_DATA_WIDTH TYPE INTEGER
set_parameter_property VGA_AVALON_DATA_WIDTH UNITS None
set_parameter_property VGA_AVALON_DATA_WIDTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property VGA_AVALON_DATA_WIDTH HDL_PARAMETER true
add_parameter VGA_MEMORY_BASED_FIFO INTEGER 1
set_parameter_property VGA_MEMORY_BASED_FIFO DEFAULT_VALUE 1
set_parameter_property VGA_MEMORY_BASED_FIFO DISPLAY_NAME VGA_MEMORY_BASED_FIFO
set_parameter_property VGA_MEMORY_BASED_FIFO TYPE INTEGER
set_parameter_property VGA_MEMORY_BASED_FIFO UNITS None
set_parameter_property VGA_MEMORY_BASED_FIFO ALLOWED_RANGES -2147483648:2147483647
set_parameter_property VGA_MEMORY_BASED_FIFO HDL_PARAMETER true
add_parameter VGA_FIFO_DEPTH INTEGER 256
set_parameter_property VGA_FIFO_DEPTH DEFAULT_VALUE 256
set_parameter_property VGA_FIFO_DEPTH DISPLAY_NAME VGA_FIFO_DEPTH
set_parameter_property VGA_FIFO_DEPTH TYPE INTEGER
set_parameter_property VGA_FIFO_DEPTH UNITS None
set_parameter_property VGA_FIFO_DEPTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property VGA_FIFO_DEPTH HDL_PARAMETER true
add_parameter VGA_FIFO_DEPTH_LOG2 INTEGER 8
set_parameter_property VGA_FIFO_DEPTH_LOG2 DEFAULT_VALUE 8
set_parameter_property VGA_FIFO_DEPTH_LOG2 DISPLAY_NAME VGA_FIFO_DEPTH_LOG2
set_parameter_property VGA_FIFO_DEPTH_LOG2 TYPE INTEGER
set_parameter_property VGA_FIFO_DEPTH_LOG2 UNITS None
set_parameter_property VGA_FIFO_DEPTH_LOG2 ALLOWED_RANGES -2147483648:2147483647
set_parameter_property VGA_FIFO_DEPTH_LOG2 HDL_PARAMETER true
add_parameter VGA_ADDRESS_WIDTH INTEGER 32
set_parameter_property VGA_ADDRESS_WIDTH DEFAULT_VALUE 32
set_parameter_property VGA_ADDRESS_WIDTH DISPLAY_NAME VGA_ADDRESS_WIDTH
set_parameter_property VGA_ADDRESS_WIDTH TYPE INTEGER
set_parameter_property VGA_ADDRESS_WIDTH UNITS None
set_parameter_property VGA_ADDRESS_WIDTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property VGA_ADDRESS_WIDTH HDL_PARAMETER true
add_parameter VGA_BURST_CAPABLE INTEGER 1
set_parameter_property VGA_BURST_CAPABLE DEFAULT_VALUE 1
set_parameter_property VGA_BURST_CAPABLE DISPLAY_NAME VGA_BURST_CAPABLE
set_parameter_property VGA_BURST_CAPABLE TYPE INTEGER
set_parameter_property VGA_BURST_CAPABLE UNITS None
set_parameter_property VGA_BURST_CAPABLE ALLOWED_RANGES -2147483648:2147483647
set_parameter_property VGA_BURST_CAPABLE HDL_PARAMETER true
add_parameter VGA_MAXIMUM_BURST_COUNT INTEGER 1
set_parameter_property VGA_MAXIMUM_BURST_COUNT DEFAULT_VALUE 1
set_parameter_property VGA_MAXIMUM_BURST_COUNT DISPLAY_NAME VGA_MAXIMUM_BURST_COUNT
set_parameter_property VGA_MAXIMUM_BURST_COUNT TYPE INTEGER
set_parameter_property VGA_MAXIMUM_BURST_COUNT UNITS None
set_parameter_property VGA_MAXIMUM_BURST_COUNT ALLOWED_RANGES -2147483648:2147483647
set_parameter_property VGA_MAXIMUM_BURST_COUNT HDL_PARAMETER true
add_parameter VGA_BURST_COUNT_WIDTH INTEGER 1
set_parameter_property VGA_BURST_COUNT_WIDTH DEFAULT_VALUE 1
set_parameter_property VGA_BURST_COUNT_WIDTH DISPLAY_NAME VGA_BURST_COUNT_WIDTH
set_parameter_property VGA_BURST_COUNT_WIDTH TYPE INTEGER
set_parameter_property VGA_BURST_COUNT_WIDTH UNITS None
set_parameter_property VGA_BURST_COUNT_WIDTH ALLOWED_RANGES -2147483648:2147483647
set_parameter_property VGA_BURST_COUNT_WIDTH HDL_PARAMETER true
add_parameter LENGTH STD_LOGIC_VECTOR 384000
set_parameter_property LENGTH DEFAULT_VALUE 384000
set_parameter_property LENGTH DISPLAY_NAME LENGTH
set_parameter_property LENGTH WIDTH 34
set_parameter_property LENGTH TYPE STD_LOGIC_VECTOR
set_parameter_property LENGTH UNITS None
set_parameter_property LENGTH ALLOWED_RANGES 0:17179869183
set_parameter_property LENGTH HDL_PARAMETER true
add_parameter BUFFER0 STD_LOGIC_VECTOR 814219264
set_parameter_property BUFFER0 DEFAULT_VALUE 814219264
set_parameter_property BUFFER0 DISPLAY_NAME BUFFER0
set_parameter_property BUFFER0 WIDTH 34
set_parameter_property BUFFER0 TYPE STD_LOGIC_VECTOR
set_parameter_property BUFFER0 UNITS None
set_parameter_property BUFFER0 ALLOWED_RANGES 0:17179869183
set_parameter_property BUFFER0 HDL_PARAMETER true
add_parameter RESIZE_LENGTH STD_LOGIC_VECTOR 90000
set_parameter_property RESIZE_LENGTH DEFAULT_VALUE 90000
set_parameter_property RESIZE_LENGTH DISPLAY_NAME RESIZE_LENGTH
set_parameter_property RESIZE_LENGTH TYPE STD_LOGIC_VECTOR
set_parameter_property RESIZE_LENGTH UNITS None
set_parameter_property RESIZE_LENGTH ALLOWED_RANGES 0:17179869183
set_parameter_property RESIZE_LENGTH HDL_PARAMETER true


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset reset_n reset_n Input 1


# 
# connection point dvp
# 
add_interface dvp conduit end
set_interface_property dvp associatedClock clock
set_interface_property dvp associatedReset reset
set_interface_property dvp ENABLED true
set_interface_property dvp EXPORT_OF ""
set_interface_property dvp PORT_NAME_MAP ""
set_interface_property dvp CMSIS_SVD_VARIABLES ""
set_interface_property dvp SVD_ADDRESS_GROUP ""

add_interface_port dvp dvp_pclk dvp_pclk Input 1
add_interface_port dvp dvp_vsync dvp_vsync Input 1
add_interface_port dvp dvp_href dvp_href Input 1
add_interface_port dvp dvp_data dvp_data Input 8


# 
# connection point vga
# 
add_interface vga conduit end
set_interface_property vga associatedClock clock
set_interface_property vga associatedReset reset
set_interface_property vga ENABLED true
set_interface_property vga EXPORT_OF ""
set_interface_property vga PORT_NAME_MAP ""
set_interface_property vga CMSIS_SVD_VARIABLES ""
set_interface_property vga SVD_ADDRESS_GROUP ""

add_interface_port vga vga_vsync vga_vsync Output 1
add_interface_port vga vga_rgb vga_rgb Output 24
add_interface_port vga vga_clk vga_clk Output 1
add_interface_port vga vga_de vga_de Output 1
add_interface_port vga vga_hsync vga_hsync Output 1


# 
# connection point vga_slave
# 
add_interface vga_slave avalon end
set_interface_property vga_slave addressUnits WORDS
set_interface_property vga_slave associatedClock clock
set_interface_property vga_slave associatedReset reset
set_interface_property vga_slave bitsPerSymbol 8
set_interface_property vga_slave burstOnBurstBoundariesOnly false
set_interface_property vga_slave burstcountUnits WORDS
set_interface_property vga_slave explicitAddressSpan 0
set_interface_property vga_slave holdTime 0
set_interface_property vga_slave linewrapBursts false
set_interface_property vga_slave maximumPendingReadTransactions 0
set_interface_property vga_slave maximumPendingWriteTransactions 0
set_interface_property vga_slave readLatency 0
set_interface_property vga_slave readWaitTime 1
set_interface_property vga_slave setupTime 0
set_interface_property vga_slave timingUnits Cycles
set_interface_property vga_slave writeWaitTime 0
set_interface_property vga_slave ENABLED true
set_interface_property vga_slave EXPORT_OF ""
set_interface_property vga_slave PORT_NAME_MAP ""
set_interface_property vga_slave CMSIS_SVD_VARIABLES ""
set_interface_property vga_slave SVD_ADDRESS_GROUP ""

add_interface_port vga_slave vga_as_address address Input 2
add_interface_port vga_slave vga_as_write write Input 1
add_interface_port vga_slave vga_as_writedata writedata Input 32
add_interface_port vga_slave vga_as_read read Input 1
add_interface_port vga_slave vga_as_readdata readdata Output 32
add_interface_port vga_slave vga_chipselect chipselect Input 1
set_interface_assignment vga_slave embeddedsw.configuration.isFlash 0
set_interface_assignment vga_slave embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment vga_slave embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment vga_slave embeddedsw.configuration.isPrintableDevice 0


# 
# connection point dvp_slave
# 
add_interface dvp_slave avalon end
set_interface_property dvp_slave addressUnits WORDS
set_interface_property dvp_slave associatedClock clock
set_interface_property dvp_slave associatedReset reset
set_interface_property dvp_slave bitsPerSymbol 8
set_interface_property dvp_slave burstOnBurstBoundariesOnly false
set_interface_property dvp_slave burstcountUnits WORDS
set_interface_property dvp_slave explicitAddressSpan 0
set_interface_property dvp_slave holdTime 0
set_interface_property dvp_slave linewrapBursts false
set_interface_property dvp_slave maximumPendingReadTransactions 0
set_interface_property dvp_slave maximumPendingWriteTransactions 0
set_interface_property dvp_slave readLatency 0
set_interface_property dvp_slave readWaitTime 1
set_interface_property dvp_slave setupTime 0
set_interface_property dvp_slave timingUnits Cycles
set_interface_property dvp_slave writeWaitTime 0
set_interface_property dvp_slave ENABLED true
set_interface_property dvp_slave EXPORT_OF ""
set_interface_property dvp_slave PORT_NAME_MAP ""
set_interface_property dvp_slave CMSIS_SVD_VARIABLES ""
set_interface_property dvp_slave SVD_ADDRESS_GROUP ""

add_interface_port dvp_slave dvp_as_address address Input 2
add_interface_port dvp_slave dvp_as_write write Input 1
add_interface_port dvp_slave dvp_as_writedata writedata Input 32
add_interface_port dvp_slave dvp_as_read read Input 1
add_interface_port dvp_slave dvp_as_readdata readdata Output 32
add_interface_port dvp_slave dvp_chipselect chipselect Input 1
set_interface_assignment dvp_slave embeddedsw.configuration.isFlash 0
set_interface_assignment dvp_slave embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment dvp_slave embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment dvp_slave embeddedsw.configuration.isPrintableDevice 0


# 
# connection point vga_master
# 
add_interface vga_master avalon start
set_interface_property vga_master addressUnits SYMBOLS
set_interface_property vga_master associatedClock clock
set_interface_property vga_master associatedReset reset
set_interface_property vga_master bitsPerSymbol 8
set_interface_property vga_master burstOnBurstBoundariesOnly false
set_interface_property vga_master burstcountUnits WORDS
set_interface_property vga_master doStreamReads false
set_interface_property vga_master doStreamWrites false
set_interface_property vga_master holdTime 0
set_interface_property vga_master linewrapBursts false
set_interface_property vga_master maximumPendingReadTransactions 0
set_interface_property vga_master maximumPendingWriteTransactions 0
set_interface_property vga_master readLatency 0
set_interface_property vga_master readWaitTime 1
set_interface_property vga_master setupTime 0
set_interface_property vga_master timingUnits Cycles
set_interface_property vga_master writeWaitTime 0
set_interface_property vga_master ENABLED true
set_interface_property vga_master EXPORT_OF ""
set_interface_property vga_master PORT_NAME_MAP ""
set_interface_property vga_master CMSIS_SVD_VARIABLES ""
set_interface_property vga_master SVD_ADDRESS_GROUP ""

add_interface_port vga_master vga_master_address address Output VGA_ADDRESS_WIDTH
add_interface_port vga_master vga_master_burstcount burstcount Output VGA_BURST_COUNT_WIDTH
add_interface_port vga_master vga_master_byteenable byteenable Output VGA_AVALON_DATA_WIDTH/8
add_interface_port vga_master vga_master_read read Output 1
add_interface_port vga_master vga_master_readdata readdata Input VGA_AVALON_DATA_WIDTH
add_interface_port vga_master vga_master_readdatavalid readdatavalid Input 1
add_interface_port vga_master vga_master_waitrequest waitrequest Input 1


# 
# connection point dvp_master
# 
add_interface dvp_master avalon start
set_interface_property dvp_master addressUnits SYMBOLS
set_interface_property dvp_master associatedClock clock
set_interface_property dvp_master associatedReset reset
set_interface_property dvp_master bitsPerSymbol 8
set_interface_property dvp_master burstOnBurstBoundariesOnly false
set_interface_property dvp_master burstcountUnits WORDS
set_interface_property dvp_master doStreamReads false
set_interface_property dvp_master doStreamWrites false
set_interface_property dvp_master holdTime 0
set_interface_property dvp_master linewrapBursts false
set_interface_property dvp_master maximumPendingReadTransactions 0
set_interface_property dvp_master maximumPendingWriteTransactions 0
set_interface_property dvp_master readLatency 0
set_interface_property dvp_master readWaitTime 1
set_interface_property dvp_master setupTime 0
set_interface_property dvp_master timingUnits Cycles
set_interface_property dvp_master writeWaitTime 0
set_interface_property dvp_master ENABLED true
set_interface_property dvp_master EXPORT_OF ""
set_interface_property dvp_master PORT_NAME_MAP ""
set_interface_property dvp_master CMSIS_SVD_VARIABLES ""
set_interface_property dvp_master SVD_ADDRESS_GROUP ""

add_interface_port dvp_master dvp_master_address address Output DVP_ADDRESS_WIDTH
add_interface_port dvp_master dvp_master_burstcount burstcount Output DVP_BURST_COUNT_WIDTH
add_interface_port dvp_master dvp_master_byteenable byteenable Output DVP_AVALON_DATA_WIDTH/8
add_interface_port dvp_master dvp_master_waitrequest waitrequest Input 1
add_interface_port dvp_master dvp_master_write write Output 1
add_interface_port dvp_master dvp_master_writedata writedata Output DVP_AVALON_DATA_WIDTH


# 
# connection point dvp_wire
# 
add_interface dvp_wire conduit end
set_interface_property dvp_wire associatedClock clock
set_interface_property dvp_wire associatedReset ""
set_interface_property dvp_wire ENABLED true
set_interface_property dvp_wire EXPORT_OF ""
set_interface_property dvp_wire PORT_NAME_MAP ""
set_interface_property dvp_wire CMSIS_SVD_VARIABLES ""
set_interface_property dvp_wire SVD_ADDRESS_GROUP ""

add_interface_port dvp_wire dvp_cnt_go dvp_cnt_go Output 8


# 
# connection point vga_wire
# 
add_interface vga_wire conduit end
set_interface_property vga_wire associatedClock clock
set_interface_property vga_wire associatedReset reset
set_interface_property vga_wire ENABLED true
set_interface_property vga_wire EXPORT_OF ""
set_interface_property vga_wire PORT_NAME_MAP ""
set_interface_property vga_wire CMSIS_SVD_VARIABLES ""
set_interface_property vga_wire SVD_ADDRESS_GROUP ""

add_interface_port vga_wire vga_flag vga_flag Output 1


# 
# connection point resize_master
# 
add_interface resize_master avalon start
set_interface_property resize_master addressUnits SYMBOLS
set_interface_property resize_master associatedClock clock
set_interface_property resize_master associatedReset reset
set_interface_property resize_master bitsPerSymbol 8
set_interface_property resize_master burstOnBurstBoundariesOnly false
set_interface_property resize_master burstcountUnits WORDS
set_interface_property resize_master doStreamReads false
set_interface_property resize_master doStreamWrites false
set_interface_property resize_master holdTime 0
set_interface_property resize_master linewrapBursts false
set_interface_property resize_master maximumPendingReadTransactions 0
set_interface_property resize_master maximumPendingWriteTransactions 0
set_interface_property resize_master readLatency 0
set_interface_property resize_master readWaitTime 1
set_interface_property resize_master setupTime 0
set_interface_property resize_master timingUnits Cycles
set_interface_property resize_master writeWaitTime 0
set_interface_property resize_master ENABLED true
set_interface_property resize_master EXPORT_OF ""
set_interface_property resize_master PORT_NAME_MAP ""
set_interface_property resize_master CMSIS_SVD_VARIABLES ""
set_interface_property resize_master SVD_ADDRESS_GROUP ""

add_interface_port resize_master dvp_master_address1 address Output DVP_ADDRESS_WIDTH
add_interface_port resize_master dvp_master_write1 write Output 1
add_interface_port resize_master dvp_master_byteenable1 byteenable Output DVP_AVALON_DATA_WIDTH/8
add_interface_port resize_master dvp_master_writedata1 writedata Output DVP_AVALON_DATA_WIDTH
add_interface_port resize_master dvp_master_burstcount1 burstcount Output DVP_BURST_COUNT_WIDTH
add_interface_port resize_master dvp_master_waitrequest1 waitrequest Input 1

