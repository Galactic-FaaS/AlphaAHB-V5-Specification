# AlphaAHB V5 ISA Test Suite Makefile

CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c99
LDFLAGS = -lm

# Directories
TEST_DIR = .
BUILD_DIR = ../build
RESULTS_DIR = ../results

# Test executables
TESTS = instruction-tests ieee754-compliance performance-benchmarks

# Default target
all: $(TESTS)

# Create directories
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(RESULTS_DIR):
	mkdir -p $(RESULTS_DIR)

# Compile test executables
instruction-tests: instruction-tests.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $(BUILD_DIR)/$@ $< $(LDFLAGS)

ieee754-compliance: ieee754-compliance.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $(BUILD_DIR)/$@ $< $(LDFLAGS)

performance-benchmarks: performance-benchmarks.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $(BUILD_DIR)/$@ $< $(LDFLAGS)

# Run all tests
test: $(TESTS) | $(RESULTS_DIR)
	@echo "Running AlphaAHB V5 ISA Test Suite..."
	@echo "====================================="
	@echo ""
	@echo "=== Instruction Tests ==="
	@$(BUILD_DIR)/instruction-tests > $(RESULTS_DIR)/instruction-tests.log 2>&1; \
	if [ $$? -eq 0 ]; then \
		echo "✓ Instruction Tests PASSED"; \
	else \
		echo "✗ Instruction Tests FAILED"; \
	fi
	@echo ""
	@echo "=== IEEE 754 Compliance Tests ==="
	@$(BUILD_DIR)/ieee754-compliance > $(RESULTS_DIR)/ieee754-compliance.log 2>&1; \
	if [ $$? -eq 0 ]; then \
		echo "✓ IEEE 754 Compliance Tests PASSED"; \
	else \
		echo "✗ IEEE 754 Compliance Tests FAILED"; \
	fi
	@echo ""
	@echo "=== Performance Benchmarks ==="
	@$(BUILD_DIR)/performance-benchmarks > $(RESULTS_DIR)/performance-benchmarks.log 2>&1; \
	if [ $$? -eq 0 ]; then \
		echo "✓ Performance Benchmarks COMPLETED"; \
	else \
		echo "✗ Performance Benchmarks FAILED"; \
	fi
	@echo ""
	@echo "=== Test Summary ==="
	@echo "Results saved to $(RESULTS_DIR)/"
	@echo "Check individual log files for detailed results."

# Run individual tests
test-instructions: instruction-tests | $(RESULTS_DIR)
	@echo "Running Instruction Tests..."
	@$(BUILD_DIR)/instruction-tests

test-ieee754: ieee754-compliance | $(RESULTS_DIR)
	@echo "Running IEEE 754 Compliance Tests..."
	@$(BUILD_DIR)/ieee754-compliance

test-performance: performance-benchmarks | $(RESULTS_DIR)
	@echo "Running Performance Benchmarks..."
	@$(BUILD_DIR)/performance-benchmarks

# Clean up
clean:
	rm -rf $(BUILD_DIR) $(RESULTS_DIR)

# Install test dependencies (if needed)
install-deps:
	@echo "Installing test dependencies..."
	@echo "No additional dependencies required for basic tests."

# Help
help:
	@echo "AlphaAHB V5 ISA Test Suite Makefile"
	@echo "==================================="
	@echo ""
	@echo "Available targets:"
	@echo "  all              - Build all test executables"
	@echo "  test             - Run all tests"
	@echo "  test-instructions - Run instruction tests only"
	@echo "  test-ieee754     - Run IEEE 754 compliance tests only"
	@echo "  test-performance - Run performance benchmarks only"
	@echo "  clean            - Remove build and result directories"
	@echo "  install-deps     - Install test dependencies"
	@echo "  help             - Show this help message"
	@echo ""
	@echo "Test results are saved to $(RESULTS_DIR)/"

.PHONY: all test test-instructions test-ieee754 test-performance clean install-deps help
