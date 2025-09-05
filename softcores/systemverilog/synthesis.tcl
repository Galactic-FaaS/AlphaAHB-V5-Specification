# AlphaAHB V5 CPU Softcore Synthesis Script
# 
# This TCL script provides synthesis and implementation commands for
# the AlphaAHB V5 CPU softcore on various FPGA platforms.

# ============================================================================
# Synthesis Configuration
# ============================================================================

# Set project parameters
set project_name "alphaahb_v5_core"
set top_module "alphaahb_v5_system"
set target_device "xczu9eg-ffvb1156-2-e"  # Xilinx Zynq UltraScale+
set target_family "zynquplus"

# Alternative target devices:
# set target_device "xc7k325t-ffg900-2"     # Xilinx Kintex-7
# set target_device "xc7a200t-fbg676-2"     # Xilinx Artix-7
# set target_device "5csxfc6d6f31c6"        # Intel Cyclone V
# set target_device "10m50daf484c7g"        # Intel MAX 10

# ============================================================================
# Project Setup
# ============================================================================

# Create project
create_project $project_name ./build/$project_name -part $target_device -force

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Verilog [current_project]
set_property default_lib work [current_project]

# ============================================================================
# Source Files
# ============================================================================

# Add source files
add_files -norecurse {
    alphaahb_v5_core.sv
    alphaahb_v5_tb.sv
}

# Set top module
set_property top $top_module [current_fileset]

# ============================================================================
# Synthesis Settings
# ============================================================================

# Create synthesis run
create_run -flow {Vivado Synthesis 2023.1} synth_1 -constrset constrs_1

# Set synthesis strategy
set_property strategy Vivado_Synthesis_Defaults [get_runs synth_1]

# Set synthesis options
set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]

# ============================================================================
# Implementation Settings
# ============================================================================

# Create implementation run
create_run -flow {Vivado Implementation 2023.1} impl_1 -parent_run synth_1

# Set implementation strategy
set_property strategy Vivado_Implementation_Defaults [get_runs impl_1]

# Set implementation options
set_property -name {STEPS.OPT_DESIGN.ARGS.MORE OPTIONS} -value {-directive Explore} -objects [get_runs impl_1]
set_property -name {STEPS.PLACE_DESIGN.ARGS.MORE OPTIONS} -value {-directive Explore} -objects [get_runs impl_1]
set_property -name {STEPS.ROUTE_DESIGN.ARGS.MORE OPTIONS} -value {-directive Explore} -objects [get_runs impl_1]

# ============================================================================
# Timing Constraints
# ============================================================================

# Create constraints file
create_file -type constraints [file join . constraints.xdc]

# Add timing constraints
puts "Creating timing constraints..."

# Clock constraints
set clock_period 10.0  # 100 MHz
set clock_uncertainty 0.5

# Create clock constraint
puts "create_clock -period $clock_period -name clk [get_ports clk]" >> constraints.xdc
puts "set_clock_uncertainty $clock_uncertainty [get_clocks clk]" >> constraints.xdc

# Input/output delays
puts "set_input_delay -clock clk -max 2.0 [get_ports rst_n]" >> constraints.xdc
puts "set_input_delay -clock clk -max 2.0 [get_ports mem_rdata]" >> constraints.xdc
puts "set_input_delay -clock clk -max 2.0 [get_ports mem_ready]" >> constraints.xdc

puts "set_output_delay -clock clk -max 2.0 [get_ports mem_addr]" >> constraints.xdc
puts "set_output_delay -clock clk -max 2.0 [get_ports mem_wdata]" >> constraints.xdc
puts "set_output_delay -clock clk -max 2.0 [get_ports mem_we]" >> constraints.xdc
puts "set_output_delay -clock clk -max 2.0 [get_ports mem_re]" >> constraints.xdc

# Add constraints file to project
add_files -fileset constrs_1 constraints.xdc

# ============================================================================
# Synthesis Commands
# ============================================================================

# Launch synthesis
puts "Launching synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check synthesis results
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed!"
    exit 1
} else {
    puts "Synthesis completed successfully!"
}

# ============================================================================
# Implementation Commands
# ============================================================================

# Launch implementation
puts "Launching implementation..."
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check implementation results
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed!"
    exit 1
} else {
    puts "Implementation completed successfully!"
}

# ============================================================================
# Report Generation
# ============================================================================

# Generate reports
puts "Generating reports..."

# Synthesis report
open_run synth_1
report_utilization -file ./build/utilization_synth.rpt
report_timing -file ./build/timing_synth.rpt
report_power -file ./build/power_synth.rpt

# Implementation report
open_run impl_1
report_utilization -file ./build/utilization_impl.rpt
report_timing -file ./build/timing_impl.rpt
report_power -file ./build/power_impl.rpt
report_drc -file ./build/drc_impl.rpt

# ============================================================================
# Bitstream Generation
# ============================================================================

# Generate bitstream
puts "Generating bitstream..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Check bitstream generation
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Bitstream generation failed!"
    exit 1
} else {
    puts "Bitstream generated successfully!"
}

# ============================================================================
# Summary
# ============================================================================

puts "=========================================="
puts "AlphaAHB V5 CPU Softcore Synthesis Complete"
puts "=========================================="
puts "Project: $project_name"
puts "Target Device: $target_device"
puts "Top Module: $top_module"
puts "Clock Frequency: [expr 1000.0 / $clock_period] MHz"
puts ""
puts "Generated Files:"
puts "  - Bitstream: ./build/$project_name/$project_name.runs/impl_1/$top_module.bit"
puts "  - Reports: ./build/*.rpt"
puts "  - Constraints: ./constraints.xdc"
puts ""
puts "Next Steps:"
puts "  1. Program FPGA with bitstream"
puts "  2. Run testbench for verification"
puts "  3. Integrate with system design"
puts "=========================================="

# ============================================================================
# Alternative Synthesis Commands
# ============================================================================

# For Intel Quartus Prime
proc quartus_synthesis {} {
    puts "Quartus Prime synthesis commands:"
    puts "quartus_map --read_settings_files=on --write_settings_files=off $project_name -c $project_name"
    puts "quartus_fit --read_settings_files=off --write_settings_files=off $project_name -c $project_name"
    puts "quartus_asm --read_settings_files=off --write_settings_files=off $project_name -c $project_name"
    puts "quartus_sta $project_name -c $project_name"
}

# For Lattice Diamond
proc diamond_synthesis {} {
    puts "Lattice Diamond synthesis commands:"
    puts "diamondc -f build.tcl"
    puts "diamondc -f map.tcl"
    puts "diamondc -f par.tcl"
    puts "diamondc -f bitgen.tcl"
}

# For Microsemi Libero
proc libero_synthesis {} {
    puts "Microsemi Libero synthesis commands:"
    puts "libero SCRIPT:synth.tcl"
    puts "libero SCRIPT:impl.tcl"
    puts "libero SCRIPT:bitgen.tcl"
}

# ============================================================================
# Simulation Commands
# ============================================================================

# Launch simulation
proc launch_simulation {} {
    puts "Launching simulation..."
    launch_simulation -mode behavioral -simset sim_1 -quiet
}

# Run testbench
proc run_testbench {} {
    puts "Running testbench..."
    run -all
}

# ============================================================================
# Debug Commands
# ============================================================================

# Open synthesized design
proc open_synthesized_design {} {
    open_run synth_1
    start_gui
}

# Open implemented design
proc open_implemented_design {} {
    open_run impl_1
    start_gui
}

# View timing analysis
proc view_timing_analysis {} {
    open_run impl_1
    report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -max_paths 10 -nworst 1
}

# View utilization
proc view_utilization {} {
    open_run impl_1
    report_utilization -hierarchical -file utilization_hier.rpt
}

puts "Synthesis script loaded successfully!"
puts "Use 'launch_simulation' to run simulation"
puts "Use 'open_synthesized_design' to view synthesized design"
puts "Use 'open_implemented_design' to view implemented design"
