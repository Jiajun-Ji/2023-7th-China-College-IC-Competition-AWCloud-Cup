set_global_assignment -entity "pll_inst" -library "lib_pll_inst" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_inst" -library "lib_pll_inst" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "pll_inst" -library "lib_pll_inst" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_inst" -name SPD_FILE [file join $::quartus(sip_path) "pll_inst.spd"]

set_global_assignment -library "lib_pll_inst" -name MISC_FILE [file join $::quartus(sip_path) "pll_inst_sim/pll_inst.vo"]
