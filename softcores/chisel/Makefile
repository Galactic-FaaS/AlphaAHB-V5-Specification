# AlphaAHB V5 CPU Softcore - Chisel Makefile
# 
# This Makefile provides build targets for the Chisel implementation
# of the AlphaAHB V5 CPU softcore.

# ============================================================================
# Configuration
# ============================================================================

# Project settings
PROJECT_NAME = alphaahb-v5-softcore
SCALA_VERSION = 2.13.10
CHISEL_VERSION = 3.6.0

# Tool settings
SBT = sbt
SCALA = scala
JAVA = java

# Directories
BUILD_DIR = build
TARGET_DIR = target
GENERATED_DIR = generated
REPORT_DIR = reports

# Source files
SOURCES = AlphaAHBV5Core.scala AlphaAHBV5CoreTest.scala
BUILD_FILE = build.sbt

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
	@echo "AlphaAHB V5 CPU Softcore - Chisel Build System"
	@echo "=============================================="
	@echo ""
	@echo "Available targets:"
	@echo "  all              - Show this help message"
	@echo "  clean            - Clean build directories"
	@echo "  setup            - Setup build directories"
	@echo "  compile          - Compile Scala/Chisel code"
	@echo "  test             - Run all tests"
	@echo "  sim              - Run simulation"
	@echo "  verilog          - Generate Verilog from Chisel"
	@echo "  synth            - Run synthesis"
	@echo "  impl             - Run implementation"
	@echo "  bitstream        - Generate bitstream"
	@echo "  assembly         - Create JAR file"
	@echo "  docs             - Generate documentation"
	@echo "  release          - Create release package"
	@echo ""
	@echo "Configuration:"
	@echo "  PROJECT_NAME     = $(PROJECT_NAME)"
	@echo "  SCALA_VERSION    = $(SCALA_VERSION)"
	@echo "  CHISEL_VERSION   = $(CHISEL_VERSION)"
	@echo ""

# ============================================================================
# Directory Setup
# ============================================================================

.PHONY: setup
setup:
	@echo "Setting up build directories..."
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(TARGET_DIR)
	@mkdir -p $(GENERATED_DIR)
	@mkdir -p $(REPORT_DIR)
	@echo "Build directories created"

# ============================================================================
# Clean Target
# ============================================================================

.PHONY: clean
clean:
	@echo "Cleaning build directories..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(TARGET_DIR)
	@rm -rf $(GENERATED_DIR)
	@rm -rf $(REPORT_DIR)
	@rm -rf .sbt
	@rm -rf project/target
	@rm -rf project/project
	@echo "Clean complete"

# ============================================================================
# Compilation Targets
# ============================================================================

.PHONY: compile
compile: setup
	@echo "Compiling Scala/Chisel code..."
	@$(SBT) compile
	@echo "Compilation complete"

.PHONY: compile-quick
compile-quick: setup
	@echo "Quick compilation..."
	@$(SBT) compile
	@echo "Quick compilation complete"

# ============================================================================
# Test Targets
# ============================================================================

.PHONY: test
test: compile
	@echo "Running all tests..."
	@$(SBT) test
	@echo "Tests complete"

.PHONY: test-quick
test-quick: compile
	@echo "Running quick tests..."
	@$(SBT) testQuick
	@echo "Quick tests complete"

.PHONY: test-only
test-only: compile
	@echo "Running specific test..."
	@$(SBT) "testOnly $(TEST)"
	@echo "Specific test complete"

# ============================================================================
# Simulation Targets
# ============================================================================

.PHONY: sim
sim: test
	@echo "Running simulation..."
	@$(SBT) "runSimulation"
	@echo "Simulation complete"

.PHONY: sim-debug
sim-debug: compile
	@echo "Running debug simulation..."
	@$(SBT) "runSimulation" -Ddebug=true
	@echo "Debug simulation complete"

# ============================================================================
# Verilog Generation
# ============================================================================

.PHONY: verilog
verilog: compile
	@echo "Generating Verilog from Chisel..."
	@$(SBT) "runMain alphaahb.v5.AlphaAHBV5Core"
	@$(SBT) "runMain alphaahb.v5.AlphaAHBV5System"
	@echo "Verilog generation complete"

.PHONY: verilog-core
verilog-core: compile
	@echo "Generating Verilog for single core..."
	@$(SBT) "runMain alphaahb.v5.AlphaAHBV5Core"
	@echo "Single core Verilog generation complete"

.PHONY: verilog-system
verilog-system: compile
	@echo "Generating Verilog for multi-core system..."
	@$(SBT) "runMain alphaahb.v5.AlphaAHBV5System"
	@echo "Multi-core system Verilog generation complete"

# ============================================================================
# Synthesis Targets
# ============================================================================

.PHONY: synth
synth: verilog
	@echo "Running synthesis..."
	@$(SBT) "runSynthesis"
	@echo "Synthesis complete"

.PHONY: synth-vivado
synth-vivado: verilog
	@echo "Running Vivado synthesis..."
	@$(SBT) "runSynthesis" -Dtool=vivado
	@echo "Vivado synthesis complete"

.PHONY: synth-quartus
synth-quartus: verilog
	@echo "Running Quartus synthesis..."
	@$(SBT) "runSynthesis" -Dtool=quartus
	@echo "Quartus synthesis complete"

.PHONY: synth-diamond
synth-diamond: verilog
	@echo "Running Diamond synthesis..."
	@$(SBT) "runSynthesis" -Dtool=diamond
	@echo "Diamond synthesis complete"

# ============================================================================
# Implementation Targets
# ============================================================================

.PHONY: impl
impl: synth
	@echo "Running implementation..."
	@$(SBT) "runImplementation"
	@echo "Implementation complete"

.PHONY: impl-vivado
impl-vivado: synth-vivado
	@echo "Running Vivado implementation..."
	@$(SBT) "runImplementation" -Dtool=vivado
	@echo "Vivado implementation complete"

.PHONY: impl-quartus
impl-quartus: synth-quartus
	@echo "Running Quartus implementation..."
	@$(SBT) "runImplementation" -Dtool=quartus
	@echo "Quartus implementation complete"

.PHONY: impl-diamond
impl-diamond: synth-diamond
	@echo "Running Diamond implementation..."
	@$(SBT) "runImplementation" -Dtool=diamond
	@echo "Diamond implementation complete"

# ============================================================================
# Bitstream Targets
# ============================================================================

.PHONY: bitstream
bitstream: impl
	@echo "Generating bitstream..."
	@$(SBT) "runBitstream"
	@echo "Bitstream generation complete"

.PHONY: bitstream-vivado
bitstream-vivado: impl-vivado
	@echo "Generating Vivado bitstream..."
	@$(SBT) "runBitstream" -Dtool=vivado
	@echo "Vivado bitstream generation complete"

.PHONY: bitstream-quartus
bitstream-quartus: impl-quartus
	@echo "Generating Quartus bitstream..."
	@$(SBT) "runBitstream" -Dtool=quartus
	@echo "Quartus bitstream generation complete"

.PHONY: bitstream-diamond
bitstream-diamond: impl-diamond
	@echo "Generating Diamond bitstream..."
	@$(SBT) "runBitstream" -Dtool=diamond
	@echo "Diamond bitstream generation complete"

# ============================================================================
# Assembly Targets
# ============================================================================

.PHONY: assembly
assembly: compile
	@echo "Creating JAR file..."
	@$(SBT) assembly
	@echo "JAR file created"

.PHONY: assembly-quick
assembly-quick: compile
	@echo "Creating quick JAR file..."
	@$(SBT) "assembly / assemblyQuick"
	@echo "Quick JAR file created"

# ============================================================================
# Documentation Targets
# ============================================================================

.PHONY: docs
docs: compile
	@echo "Generating documentation..."
	@$(SBT) "runDocs"
	@echo "Documentation generation complete"

.PHONY: docs-html
docs-html: compile
	@echo "Generating HTML documentation..."
	@$(SBT) "runDocs" -Dformat=html
	@echo "HTML documentation generation complete"

.PHONY: docs-pdf
docs-pdf: compile
	@echo "Generating PDF documentation..."
	@$(SBT) "runDocs" -Dformat=pdf
	@echo "PDF documentation generation complete"

# ============================================================================
# Release Targets
# ============================================================================

.PHONY: release
release: clean test verilog assembly
	@echo "Creating release package..."
	@mkdir -p $(BUILD_DIR)/release
	@cp $(TARGET_DIR)/scala-$(SCALA_VERSION)/$(PROJECT_NAME)-assembly-*.jar $(BUILD_DIR)/release/
	@cp -r $(GENERATED_DIR) $(BUILD_DIR)/release/
	@cp $(SOURCES) $(BUILD_DIR)/release/
	@cp $(BUILD_FILE) $(BUILD_DIR)/release/
	@cp Makefile $(BUILD_DIR)/release/
	@echo "Release package created in $(BUILD_DIR)/release/"

.PHONY: release-quick
release-quick: clean compile verilog assembly
	@echo "Creating quick release package..."
	@mkdir -p $(BUILD_DIR)/release
	@cp $(TARGET_DIR)/scala-$(SCALA_VERSION)/$(PROJECT_NAME)-assembly-*.jar $(BUILD_DIR)/release/
	@cp -r $(GENERATED_DIR) $(BUILD_DIR)/release/
	@cp $(SOURCES) $(BUILD_DIR)/release/
	@cp $(BUILD_FILE) $(BUILD_DIR)/release/
	@cp Makefile $(BUILD_DIR)/release/
	@echo "Quick release package created in $(BUILD_DIR)/release/"

# ============================================================================
# Development Targets
# ============================================================================

.PHONY: dev
dev: setup compile test
	@echo "Development environment ready"
	@echo "Use 'make test' to run tests"
	@echo "Use 'make verilog' to generate Verilog"
	@echo "Use 'make sim' to run simulation"

.PHONY: dev-quick
dev-quick: setup compile-quick test-quick
	@echo "Quick development environment ready"

# ============================================================================
# Debug Targets
# ============================================================================

.PHONY: debug
debug: compile
	@echo "Starting debug session..."
	@$(SBT) "console"

.PHONY: debug-test
debug-test: compile
	@echo "Starting debug test session..."
	@$(SBT) "test:console"

# ============================================================================
# Utility Targets
# ============================================================================

.PHONY: check
check: compile test
	@echo "Running all checks..."
	@$(SBT) "scalastyle"
	@$(SBT) "scalafmtCheck"
	@echo "All checks complete"

.PHONY: format
format: compile
	@echo "Formatting code..."
	@$(SBT) "scalafmt"
	@echo "Code formatting complete"

.PHONY: lint
lint: compile
	@echo "Running linter..."
	@$(SBT) "scalastyle"
	@echo "Linting complete"

# ============================================================================
# Configuration Targets
# ============================================================================

.PHONY: config
config:
	@echo "Current configuration:"
	@echo "  PROJECT_NAME     = $(PROJECT_NAME)"
	@echo "  SCALA_VERSION    = $(SCALA_VERSION)"
	@echo "  CHISEL_VERSION   = $(CHISEL_VERSION)"
	@echo "  SBT              = $(SBT)"
	@echo "  SCALA            = $(SCALA)"
	@echo "  JAVA             = $(JAVA)"

.PHONY: config-check
config-check:
	@echo "Checking configuration..."
	@$(SBT) "checkTools"
	@echo "Configuration check complete"

# ============================================================================
# Dependencies
# ============================================================================

# Make sure tests run after compilation
test: compile
sim: test
verilog: compile
synth: verilog
impl: synth
bitstream: impl
assembly: compile
docs: compile
release: test verilog assembly

# ============================================================================
# Phony Targets
# ============================================================================

.PHONY: all help clean setup compile compile-quick test test-quick test-only sim sim-debug verilog verilog-core verilog-system synth synth-vivado synth-quartus synth-diamond impl impl-vivado impl-quartus impl-diamond bitstream bitstream-vivado bitstream-quartus bitstream-diamond assembly assembly-quick docs docs-html docs-pdf release release-quick dev dev-quick debug debug-test check format lint config config-check
