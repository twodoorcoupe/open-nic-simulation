set sim_env_list {SIM_LOCATION MIN_PKT_LEN MAX_PKT_LEN NUM_PHYS_FUNC NUM_QUEUE NUM_QDMA NUM_CMAC_PORT}
set generic_list []
foreach {var value} [array get env] {
    if {$var == "PROJECT_LOCATION"} {
        set location $value
    } elseif {$var == "USER_BOX"} {
        set box $value
    } elseif {$var in $sim_env_list} {
        lappend generic_list "$var=$value"
    }
}

puts $generic_list

open_project $location
set_property generic $generic_list [current_fileset -simset]
set_property verilog_define $box [current_fileset -simset]

launch_simulation
run -all
if {$rdi::mode == "batch"} {
    close_project
    exit
}