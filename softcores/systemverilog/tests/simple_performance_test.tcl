# AlphaAHB V5 Simple Performance Test Script
# Basic performance and multi-core testing using Vivado

# Create project
create_project simple_performance_test simple_performance_test -part xc7a100tcsg324-1 -force

# Add test file
add_files -norecurse {
    src/test/sv/alphaahb/v5/SimplePerformanceTest.sv
}

# Update compile order
update_compile_order -fileset sources_1

# Set top module for simulation
set_property top SimplePerformanceTest [get_filesets sim_1]

# Run simulation
launch_simulation

# Run for 2000ns (2us)
run 2000ns

# Close simulation
close_sim

# Clean up
close_project

exit
