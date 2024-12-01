set_global_assignment -entity "div_three_pll" -library "lib_div_three_pll" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "div_three_pll" -library "lib_div_three_pll" -name IP_TOOL_VERSION "18.1"
set_global_assignment -entity "div_three_pll" -library "lib_div_three_pll" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_div_three_pll" -name SPD_FILE [file join $::quartus(sip_path) "div_three_pll.spd"]

set_global_assignment -library "lib_div_three_pll" -name MISC_FILE [file join $::quartus(sip_path) "div_three_pll_sim/div_three_pll.vo"]
