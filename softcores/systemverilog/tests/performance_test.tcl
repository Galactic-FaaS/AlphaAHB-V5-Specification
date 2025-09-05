# AlphaAHB V5 Performance Test Script
# Comprehensive performance and multi-core testing using Vivado

# Create project
create_project performance_test performance_test -part xc7a100tcsg324-1 -force

# Add test file
add_files -norecurse {
    src/test/sv/alphaahb/v5/PerformanceTest.sv
}

# Update compile order
update_compile_order -fileset sources_1

# Set top module for simulation
set_property top PerformanceTest [get_filesets sim_1]

# Run simulation
launch_simulation

# Run for 5000ns (5us)
run 5000ns

# Close simulation
close_sim

# Clean up
close_project

exit
