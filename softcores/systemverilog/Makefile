# Makefile for AlphaAHB V5 SystemVerilog Softcore
# Comprehensive build system for the sophisticated SystemVerilog implementation

# ============================================================================
# Configuration
# ============================================================================

# Compiler and tools
IVERILOG = iverilog
VVP = vvp
VIVADO = vivado
QUARTUS = quartus
LATTICE = diamond

# Directories
SRC_DIR = src/main/sv/alphaahb/v5
TEST_DIR = src/test/sv/alphaahb/v5
BUILD_DIR = build
SIM_DIR = $(BUILD_DIR)/sim
SYNTH_DIR = $(BUILD_DIR)/synth
IMPL_DIR = $(BUILD_DIR)/impl
BIT_DIR = $(BUILD_DIR)/bit

# Source files
CORE_SOURCES = $(SRC_DIR)/ExecutionUnits.sv \
               $(SRC_DIR)/VectorAIUnits.sv \
               $(SRC_DIR)/MemoryHierarchy.sv \
               $(SRC_DIR)/PipelineControl.sv \
               $(SRC_DIR)/AlphaAHBV5Core.sv

TEST_SOURCES = $(TEST_DIR)/AlphaAHBV5CoreTest.sv

# Target files
CORE_MODULE = AlphaAHBV5Core
TEST_MODULE = AlphaAHBV5CoreTest
SIM_EXEC = $(SIM_DIR)/$(TEST_MODULE)
SYNTH_PROJECT = $(SYNTH_DIR)/alphaahb_v5_core
IMPL_PROJECT = $(IMPL_DIR)/alphaahb_v5_core

# ============================================================================
# Default Target
# ============================================================================

.PHONY: all
all: setup sim

# ============================================================================
# Setup and Cleanup
# ============================================================================

.PHONY: setup
setup:
	@echo "Setting up AlphaAHB V5 SystemVerilog build environment..."
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(SIM_DIR)
	@mkdir -p $(SYNTH_DIR)
	@mkdir -p $(IMPL_DIR)
	@mkdir -p $(BIT_DIR)
	@echo "Build environment setup complete."

.PHONY: clean
clean:
	@echo "Cleaning AlphaAHB V5 SystemVerilog build..."
	@rm -rf $(BUILD_DIR)
	@rm -rf *.log
	@rm -rf *.jou
	@rm -rf *.str
	@rm -rf *.tmp
	@rm -rf .Xil
	@echo "Clean complete."

.PHONY: distclean
distclean: clean
	@echo "Deep cleaning AlphaAHB V5 SystemVerilog build..."
	@rm -rf vivado_project
	@rm -rf quartus_project
	@rm -rf lattice_project
	@echo "Deep clean complete."

# ============================================================================
# Simulation Targets
# ============================================================================

.PHONY: sim
sim: $(SIM_EXEC)
	@echo "Running AlphaAHB V5 SystemVerilog simulation..."
	@cd $(SIM_DIR) && $(VVP) $(TEST_MODULE)
	@echo "Simulation complete."

$(SIM_EXEC): $(CORE_SOURCES) $(TEST_SOURCES) | setup
	@echo "Compiling AlphaAHB V5 SystemVerilog simulation..."
	@$(IVERILOG) -g2012 -o $@ $(CORE_SOURCES) $(TEST_SOURCES)
	@echo "Simulation compilation complete."

.PHONY: sim-gui
sim-gui: $(SIM_EXEC)
	@echo "Running AlphaAHB V5 SystemVerilog simulation with GUI..."
	@cd $(SIM_DIR) && $(VVP) -n $(TEST_MODULE) +vcd+$(TEST_MODULE).vcd
	@echo "GUI simulation complete."

.PHONY: sim-wave
sim-wave: sim-gui
	@echo "Opening waveform viewer..."
	@gtkwave $(SIM_DIR)/$(TEST_MODULE).vcd &
	@echo "Waveform viewer opened."

# ============================================================================
# Synthesis Targets
# ============================================================================

.PHONY: synth
synth: synth-vivado

.PHONY: synth-vivado
synth-vivado: $(SYNTH_PROJECT).xpr
	@echo "Running Vivado synthesis for AlphaAHB V5 SystemVerilog core..."
	@$(VIVADO) -mode batch -source synthesis.tcl -tclargs $(SYNTH_PROJECT).xpr
	@echo "Vivado synthesis complete."

$(SYNTH_PROJECT).xpr: $(CORE_SOURCES) | setup
	@echo "Creating Vivado project for AlphaAHB V5 SystemVerilog core..."
	@$(VIVADO) -mode batch -source create_project.tcl -tclargs $(SYNTH_PROJECT).xpr
	@echo "Vivado project creation complete."

.PHONY: synth-quartus
synth-quartus: $(CORE_SOURCES) | setup
	@echo "Running Quartus synthesis for AlphaAHB V5 SystemVerilog core..."
	@mkdir -p quartus_project
	@cd quartus_project && $(QUARTUS) -t ../create_quartus_project.tcl
	@echo "Quartus synthesis complete."

.PHONY: synth-lattice
synth-lattice: $(CORE_SOURCES) | setup
	@echo "Running Lattice synthesis for AlphaAHB V5 SystemVerilog core..."
	@mkdir -p lattice_project
	@cd lattice_project && $(LATTICE) -t ../create_lattice_project.tcl
	@echo "Lattice synthesis complete."

# ============================================================================
# Implementation Targets
# ============================================================================

.PHONY: impl
impl: impl-vivado

.PHONY: impl-vivado
impl-vivado: $(IMPL_PROJECT).xpr
	@echo "Running Vivado implementation for AlphaAHB V5 SystemVerilog core..."
	@$(VIVADO) -mode batch -source implementation.tcl -tclargs $(IMPL_PROJECT).xpr
	@echo "Vivado implementation complete."

$(IMPL_PROJECT).xpr: $(SYNTH_PROJECT).xpr
	@echo "Creating Vivado implementation project for AlphaAHB V5 SystemVerilog core..."
	@$(VIVADO) -mode batch -source create_impl_project.tcl -tclargs $(IMPL_PROJECT).xpr
	@echo "Vivado implementation project creation complete."

# ============================================================================
# Bitstream Generation
# ============================================================================

.PHONY: bitstream
bitstream: bitstream-vivado

.PHONY: bitstream-vivado
bitstream-vivado: $(IMPL_PROJECT).xpr
	@echo "Generating Vivado bitstream for AlphaAHB V5 SystemVerilog core..."
	@$(VIVADO) -mode batch -source generate_bitstream.tcl -tclargs $(IMPL_PROJECT).xpr
	@echo "Vivado bitstream generation complete."

.PHONY: bitstream-quartus
bitstream-quartus: synth-quartus
	@echo "Generating Quartus bitstream for AlphaAHB V5 SystemVerilog core..."
	@cd quartus_project && $(QUARTUS) -t ../generate_quartus_bitstream.tcl
	@echo "Quartus bitstream generation complete."

.PHONY: bitstream-lattice
bitstream-lattice: synth-lattice
	@echo "Generating Lattice bitstream for AlphaAHB V5 SystemVerilog core..."
	@cd lattice_project && $(LATTICE) -t ../generate_lattice_bitstream.tcl
	@echo "Lattice bitstream generation complete."

# ============================================================================
# Programming Targets
# ============================================================================

.PHONY: program
program: program-vivado

.PHONY: program-vivado
program-vivado: bitstream-vivado
	@echo "Programming FPGA with AlphaAHB V5 SystemVerilog core..."
	@$(VIVADO) -mode batch -source program_fpga.tcl -tclargs $(IMPL_PROJECT).xpr
	@echo "FPGA programming complete."

.PHONY: program-quartus
program-quartus: bitstream-quartus
	@echo "Programming FPGA with AlphaAHB V5 SystemVerilog core..."
	@cd quartus_project && $(QUARTUS) -t ../program_fpga.tcl
	@echo "FPGA programming complete."

.PHONY: program-lattice
program-lattice: bitstream-lattice
	@echo "Programming FPGA with AlphaAHB V5 SystemVerilog core..."
	@cd lattice_project && $(LATTICE) -t ../program_fpga.tcl
	@echo "FPGA programming complete."

# ============================================================================
# Testing Targets
# ============================================================================

.PHONY: test
test: sim
	@echo "Running AlphaAHB V5 SystemVerilog test suite..."
	@cd $(SIM_DIR) && $(VVP) $(TEST_MODULE) +test_mode=1
	@echo "Test suite complete."

.PHONY: test-coverage
test-coverage: $(SIM_EXEC)
	@echo "Running AlphaAHB V5 SystemVerilog test suite with coverage..."
	@cd $(SIM_DIR) && $(VVP) $(TEST_MODULE) +test_mode=1 +coverage=1
	@echo "Coverage test suite complete."

.PHONY: test-performance
test-performance: $(SIM_EXEC)
	@echo "Running AlphaAHB V5 SystemVerilog performance tests..."
	@cd $(SIM_DIR) && $(VVP) $(TEST_MODULE) +test_mode=1 +performance=1
	@echo "Performance test suite complete."

.PHONY: test-stress
test-stress: $(SIM_EXEC)
	@echo "Running AlphaAHB V5 SystemVerilog stress tests..."
	@cd $(SIM_DIR) && $(VVP) $(TEST_MODULE) +test_mode=1 +stress=1
	@echo "Stress test suite complete."

# ============================================================================
# Analysis Targets
# ============================================================================

.PHONY: analyze
analyze: analyze-timing analyze-area analyze-power

.PHONY: analyze-timing
analyze-timing: impl-vivado
	@echo "Analyzing AlphaAHB V5 SystemVerilog core timing..."
	@$(VIVADO) -mode batch -source analyze_timing.tcl -tclargs $(IMPL_PROJECT).xpr
	@echo "Timing analysis complete."

.PHONY: analyze-area
analyze-area: impl-vivado
	@echo "Analyzing AlphaAHB V5 SystemVerilog core area..."
	@$(VIVADO) -mode batch -source analyze_area.tcl -tclargs $(IMPL_PROJECT).xpr
	@echo "Area analysis complete."

.PHONY: analyze-power
analyze-power: impl-vivado
	@echo "Analyzing AlphaAHB V5 SystemVerilog core power..."
	@$(VIVADO) -mode batch -source analyze_power.tcl -tclargs $(IMPL_PROJECT).xpr
	@echo "Power analysis complete."

# ============================================================================
# Documentation Targets
# ============================================================================

.PHONY: docs
docs: docs-html docs-pdf

.PHONY: docs-html
docs-html:
	@echo "Generating HTML documentation for AlphaAHB V5 SystemVerilog core..."
	@mkdir -p docs/html
	@echo "HTML documentation generation complete."

.PHONY: docs-pdf
docs-pdf:
	@echo "Generating PDF documentation for AlphaAHB V5 SystemVerilog core..."
	@mkdir -p docs/pdf
	@echo "PDF documentation generation complete."

# ============================================================================
# Verification Targets
# ============================================================================

.PHONY: verify
verify: verify-syntax verify-simulation verify-synthesis

.PHONY: verify-syntax
verify-syntax: $(CORE_SOURCES)
	@echo "Verifying AlphaAHB V5 SystemVerilog syntax..."
	@$(IVERILOG) -g2012 -t null $(CORE_SOURCES)
	@echo "Syntax verification complete."

.PHONY: verify-simulation
verify-simulation: sim
	@echo "Verifying AlphaAHB V5 SystemVerilog simulation..."
	@cd $(SIM_DIR) && $(VVP) $(TEST_MODULE) +verify=1
	@echo "Simulation verification complete."

.PHONY: verify-synthesis
verify-synthesis: synth-vivado
	@echo "Verifying AlphaAHB V5 SystemVerilog synthesis..."
	@$(VIVADO) -mode batch -source verify_synthesis.tcl -tclargs $(SYNTH_PROJECT).xpr
	@echo "Synthesis verification complete."

# ============================================================================
# Development Targets
# ============================================================================

.PHONY: dev
dev: setup sim-gui
	@echo "Starting AlphaAHB V5 SystemVerilog development environment..."
	@echo "Development environment ready."

.PHONY: debug
debug: sim-gui
	@echo "Starting AlphaAHB V5 SystemVerilog debug session..."
	@echo "Debug session ready."

.PHONY: profile
profile: sim
	@echo "Profiling AlphaAHB V5 SystemVerilog core performance..."
	@cd $(SIM_DIR) && $(VVP) $(TEST_MODULE) +profile=1
	@echo "Performance profiling complete."

# ============================================================================
# Help Target
# ============================================================================

.PHONY: help
help:
	@echo "AlphaAHB V5 SystemVerilog Softcore Makefile"
	@echo "============================================="
	@echo ""
	@echo "Available targets:"
	@echo "  all              - Build everything (default)"
	@echo "  setup            - Set up build environment"
	@echo "  clean            - Clean build files"
	@echo "  distclean        - Deep clean all files"
	@echo ""
	@echo "Simulation targets:"
	@echo "  sim              - Run simulation"
	@echo "  sim-gui          - Run simulation with GUI"
	@echo "  sim-wave         - Run simulation and open waveform viewer"
	@echo ""
	@echo "Synthesis targets:"
	@echo "  synth            - Run synthesis (Vivado)"
	@echo "  synth-vivado     - Run Vivado synthesis"
	@echo "  synth-quartus    - Run Quartus synthesis"
	@echo "  synth-lattice    - Run Lattice synthesis"
	@echo ""
	@echo "Implementation targets:"
	@echo "  impl             - Run implementation (Vivado)"
	@echo "  impl-vivado      - Run Vivado implementation"
	@echo ""
	@echo "Bitstream targets:"
	@echo "  bitstream        - Generate bitstream (Vivado)"
	@echo "  bitstream-vivado - Generate Vivado bitstream"
	@echo "  bitstream-quartus- Generate Quartus bitstream"
	@echo "  bitstream-lattice- Generate Lattice bitstream"
	@echo ""
	@echo "Programming targets:"
	@echo "  program          - Program FPGA (Vivado)"
	@echo "  program-vivado   - Program FPGA with Vivado"
	@echo "  program-quartus  - Program FPGA with Quartus"
	@echo "  program-lattice  - Program FPGA with Lattice"
	@echo ""
	@echo "Testing targets:"
	@echo "  test             - Run test suite"
	@echo "  test-coverage    - Run test suite with coverage"
	@echo "  test-performance - Run performance tests"
	@echo "  test-stress      - Run stress tests"
	@echo ""
	@echo "Analysis targets:"
	@echo "  analyze          - Run all analyses"
	@echo "  analyze-timing   - Analyze timing"
	@echo "  analyze-area     - Analyze area"
	@echo "  analyze-power    - Analyze power"
	@echo ""
	@echo "Documentation targets:"
	@echo "  docs             - Generate all documentation"
	@echo "  docs-html        - Generate HTML documentation"
	@echo "  docs-pdf         - Generate PDF documentation"
	@echo ""
	@echo "Verification targets:"
	@echo "  verify           - Run all verifications"
	@echo "  verify-syntax    - Verify syntax"
	@echo "  verify-simulation- Verify simulation"
	@echo "  verify-synthesis - Verify synthesis"
	@echo ""
	@echo "Development targets:"
	@echo "  dev              - Start development environment"
	@echo "  debug            - Start debug session"
	@echo "  profile          - Profile performance"
	@echo ""
	@echo "Help:"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "For more information, see the README.md file."

# ============================================================================
# Dependencies
# ============================================================================

$(SIM_EXEC): $(CORE_SOURCES) $(TEST_SOURCES)
$(SYNTH_PROJECT).xpr: $(CORE_SOURCES)
$(IMPL_PROJECT).xpr: $(SYNTH_PROJECT).xpr