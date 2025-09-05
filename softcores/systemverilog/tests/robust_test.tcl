# Robust AlphaAHB V5 Test Script
# Comprehensive functionality test using Vivado

# Create project
create_project robust_test robust_test -part xc7a100tcsg324-1 -force

# Add test file
add_files -norecurse {
    src/test/sv/alphaahb/v5/RobustTest.sv
}

# Update compile order
update_compile_order -fileset sources_1

# Set top module for simulation
set_property top RobustTest [get_filesets sim_1]

# Run simulation
launch_simulation

# Run for 2000ns
run 2000ns

# Close simulation
close_sim

# Clean up
close_project

exit
