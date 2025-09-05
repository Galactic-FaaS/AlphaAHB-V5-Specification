# Simple AlphaAHB V5 Test Script
# Basic functionality test using Vivado

# Create project
create_project simple_test simple_test -part xc7a100tcsg324-1 -force

# Add test file
add_files -norecurse {
    src/test/sv/alphaahb/v5/SimpleTest.sv
}

# Update compile order
update_compile_order -fileset sources_1

# Set top module for simulation
set_property top SimpleTest [get_filesets sim_1]

# Run simulation
launch_simulation

# Run for 1000ns
run 1000ns

# Close simulation
close_sim

# Clean up
close_project

exit
