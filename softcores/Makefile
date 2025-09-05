# AlphaAHB V5 CPU Softcore Makefile
# 
# This Makefile provides build targets for synthesizing and simulating
# the AlphaAHB V5 CPU softcore on various FPGA platforms.

# ============================================================================
# Configuration
# ============================================================================

# Project settings
PROJECT_NAME = alphaahb_v5_core
TOP_MODULE = alphaahb_v5_system
TARGET_DEVICE = xczu9eg-ffvb1156-2-e
CLOCK_FREQ = 100

# Tool settings
VIVADO = vivado
QUARTUS = quartus
DIAMOND = diamondc
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave

# Directories
BUILD_DIR = build
SYNTH_DIR = $(BUILD_DIR)/synthesis
SIM_DIR = $(BUILD_DIR)/simulation
REPORT_DIR = $(BUILD_DIR)/reports

# Source files
SOURCES = alphaahb_v5_core.sv
TESTBENCH = alphaahb_v5_tb.sv
CONSTRAINTS = constraints.xdc

# ============================================================================
# Default Target
# ============================================================================

.PHONY: all
all: help

# ============================================================================
# Help Target
# ============================================================================

.PHONY: help
help:
	@echo "AlphaAHB V5 CPU Softcore Build System"
	@echo "====================================="
	@echo ""
	@echo "Available targets:"
	@echo "  all              - Show this help message"
	@echo "  clean            - Clean build directories"
	@echo "  setup            - Setup build directories"
	@echo "  sim              - Run simulation"
	@echo "  synth            - Run synthesis"
	@echo "  impl             - Run implementation"
	@echo "  bitstream        - Generate bitstream"
	@echo "  reports          - Generate reports"
	@echo "  program          - Program FPGA"
	@echo "  test             - Run all tests"
	@echo "  gui              - Open Vivado GUI"
	@echo ""
	@echo "Simulation targets:"
	@echo "  sim-iverilog     - Run simulation with Icarus Verilog"
	@echo "  sim-vivado       - Run simulation with Vivado"
	@echo "  wave             - View simulation waveforms"
	@echo ""
	@echo "Synthesis targets:"
	@echo "  synth-vivado     - Synthesize with Vivado"
	@echo "  synth-quartus    - Synthesize with Quartus Prime"
	@echo "  synth-diamond    - Synthesize with Lattice Diamond"
	@echo ""
	@echo "Configuration:"
	@echo "  PROJECT_NAME     = $(PROJECT_NAME)"
	@echo "  TOP_MODULE       = $(TOP_MODULE)"
	@echo "  TARGET_DEVICE    = $(TARGET_DEVICE)"
	@echo "  CLOCK_FREQ       = $(CLOCK_FREQ) MHz"

# ============================================================================
# Directory Setup
# ============================================================================

.PHONY: setup
setup:
	@echo "Setting up build directories..."
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(SYNTH_DIR)
	@mkdir -p $(SIM_DIR)
	@mkdir -p $(REPORT_DIR)
	@echo "Build directories created"

# ============================================================================
# Clean Target
# ============================================================================

.PHONY: clean
clean:
	@echo "Cleaning build directories..."
	@rm -rf $(BUILD_DIR)
	@rm -rf *.log
	@rm -rf *.jou
	@rm -rf .Xil
	@rm -rf vivado_*
	@rm -rf quartus_*
	@rm -rf diamond_*
	@echo "Clean complete"

# ============================================================================
# Simulation Targets
# ============================================================================

.PHONY: sim
sim: sim-iverilog

.PHONY: sim-iverilog
sim-iverilog: setup
	@echo "Running simulation with Icarus Verilog..."
	@$(IVERILOG) -g2012 -o $(SIM_DIR)/$(PROJECT_NAME)_sim $(SOURCES) $(TESTBENCH)
	@$(VVP) $(SIM_DIR)/$(PROJECT_NAME)_sim
	@echo "Simulation complete"

.PHONY: sim-vivado
sim-vivado: setup
	@echo "Running simulation with Vivado..."
	@$(VIVADO) -mode batch -source sim_vivado.tcl
	@echo "Simulation complete"

.PHONY: wave
wave:
	@echo "Opening waveform viewer..."
	@$(GTKWAVE) $(SIM_DIR)/$(PROJECT_NAME).vcd &

# ============================================================================
# Synthesis Targets
# ============================================================================

.PHONY: synth
synth: synth-vivado

.PHONY: synth-vivado
synth-vivado: setup
	@echo "Running synthesis with Vivado..."
	@$(VIVADO) -mode batch -source synthesis.tcl
	@echo "Synthesis complete"

.PHONY: synth-quartus
synth-quartus: setup
	@echo "Running synthesis with Quartus Prime..."
	@$(QUARTUS) --64bit --mode gui $(PROJECT_NAME)
	@echo "Synthesis complete"

.PHONY: synth-diamond
synth-diamond: setup
	@echo "Running synthesis with Lattice Diamond..."
	@$(DIAMOND) -f synthesis_diamond.tcl
	@echo "Synthesis complete"

# ============================================================================
# Implementation Targets
# ============================================================================

.PHONY: impl
impl: synth-vivado
	@echo "Running implementation..."
	@$(VIVADO) -mode batch -source impl.tcl
	@echo "Implementation complete"

.PHONY: bitstream
bitstream: impl
	@echo "Generating bitstream..."
	@$(VIVADO) -mode batch -source bitstream.tcl
	@echo "Bitstream generated"

.PHONY: program
program: bitstream
	@echo "Programming FPGA..."
	@$(VIVADO) -mode batch -source program.tcl
	@echo "FPGA programmed"

# ============================================================================
# Report Targets
# ============================================================================

.PHONY: reports
reports: impl
	@echo "Generating reports..."
	@$(VIVADO) -mode batch -source reports.tcl
	@echo "Reports generated in $(REPORT_DIR)/"

.PHONY: timing
timing: impl
	@echo "Generating timing report..."
	@$(VIVADO) -mode batch -source timing.tcl
	@echo "Timing report generated"

.PHONY: utilization
utilization: impl
	@echo "Generating utilization report..."
	@$(VIVADO) -mode batch -source utilization.tcl
	@echo "Utilization report generated"

.PHONY: power
power: impl
	@echo "Generating power report..."
	@$(VIVADO) -mode batch -source power.tcl
	@echo "Power report generated"

# ============================================================================
# Test Targets
# ============================================================================

.PHONY: test
test: sim
	@echo "Running all tests..."
	@$(VVP) $(SIM_DIR)/$(PROJECT_NAME)_sim > $(REPORT_DIR)/test_results.log
	@grep -E "(PASS|FAIL)" $(REPORT_DIR)/test_results.log
	@echo "Test results saved to $(REPORT_DIR)/test_results.log"

.PHONY: test-coverage
test-coverage: setup
	@echo "Running test coverage analysis..."
	@$(IVERILOG) -g2012 -DCOVERAGE -o $(SIM_DIR)/$(PROJECT_NAME)_cov $(SOURCES) $(TESTBENCH)
	@$(VVP) $(SIM_DIR)/$(PROJECT_NAME)_cov
	@echo "Coverage analysis complete"

# ============================================================================
# GUI Targets
# ============================================================================

.PHONY: gui
gui:
	@echo "Opening Vivado GUI..."
	@$(VIVADO) -mode gui &

.PHONY: gui-synth
gui-synth: synth-vivado
	@echo "Opening synthesized design in GUI..."
	@$(VIVADO) -mode gui -source open_synth.tcl &

.PHONY: gui-impl
gui-impl: impl
	@echo "Opening implemented design in GUI..."
	@$(VIVADO) -mode gui -source open_impl.tcl &

# ============================================================================
# Configuration Targets
# ============================================================================

.PHONY: config-vivado
config-vivado:
	@echo "Configuring for Vivado..."
	@echo "TARGET_DEVICE = $(TARGET_DEVICE)" > config.mk
	@echo "CLOCK_FREQ = $(CLOCK_FREQ)" >> config.mk
	@echo "Configuration saved to config.mk"

.PHONY: config-quartus
config-quartus:
	@echo "Configuring for Quartus Prime..."
	@echo "TARGET_DEVICE = 5csxfc6d6f31c6" > config.mk
	@echo "CLOCK_FREQ = $(CLOCK_FREQ)" >> config.mk
	@echo "Configuration saved to config.mk"

.PHONY: config-diamond
config-diamond:
	@echo "Configuring for Lattice Diamond..."
	@echo "TARGET_DEVICE = lfe5u-85f-6bg381c" > config.mk
	@echo "CLOCK_FREQ = $(CLOCK_FREQ)" >> config.mk
	@echo "Configuration saved to config.mk"

# ============================================================================
# Development Targets
# ============================================================================

.PHONY: lint
lint:
	@echo "Running linting..."
	@verilator --lint-only $(SOURCES)
	@echo "Linting complete"

.PHONY: format
format:
	@echo "Formatting code..."
	@verilog_format -i $(SOURCES) $(TESTBENCH)
	@echo "Formatting complete"

.PHONY: doc
doc:
	@echo "Generating documentation..."
	@doxygen Doxyfile
	@echo "Documentation generated in doc/"

# ============================================================================
# Debug Targets
# ============================================================================

.PHONY: debug-sim
debug-sim: sim
	@echo "Starting debug simulation..."
	@$(VVP) -i $(SIM_DIR)/$(PROJECT_NAME)_sim

.PHONY: debug-synth
debug-synth: synth-vivado
	@echo "Starting debug synthesis..."
	@$(VIVADO) -mode batch -source debug_synth.tcl

.PHONY: debug-impl
debug-impl: impl
	@echo "Starting debug implementation..."
	@$(VIVADO) -mode batch -source debug_impl.tcl

# ============================================================================
# Release Targets
# ============================================================================

.PHONY: release
release: clean test bitstream reports
	@echo "Creating release package..."
	@mkdir -p release
	@cp $(BUILD_DIR)/$(PROJECT_NAME).runs/impl_1/$(TOP_MODULE).bit release/
	@cp $(REPORT_DIR)/*.rpt release/
	@cp $(SOURCES) release/
	@cp $(TESTBENCH) release/
	@cp $(CONSTRAINTS) release/
	@cp synthesis.tcl release/
	@cp Makefile release/
	@echo "Release package created in release/"

.PHONY: install
install: release
	@echo "Installing softcore..."
	@sudo cp release/$(TOP_MODULE).bit /opt/alphaahb_v5/
	@sudo cp release/*.rpt /opt/alphaahb_v5/reports/
	@echo "Softcore installed"

# ============================================================================
# Dependencies
# ============================================================================

# Include configuration if it exists
-include config.mk

# ============================================================================
# Phony Targets
# ============================================================================

.PHONY: all help clean setup sim sim-iverilog sim-vivado wave synth synth-vivado synth-quartus synth-diamond impl bitstream program reports timing utilization power test test-coverage gui gui-synth gui-impl config-vivado config-quartus config-diamond lint format doc debug-sim debug-synth debug-impl release install
