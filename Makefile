# AlphaAHB V5 Specification Makefile

# Compiler settings
CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O2 -g
CXXFLAGS = -Wall -Wextra -std=c++17 -O2 -g

# Directories
SRC_DIR = examples
BUILD_DIR = build
DOCS_DIR = docs
SPECS_DIR = specs
TESTS_DIR = tests

# Source files
C_SOURCES = $(wildcard $(SRC_DIR)/*.c)
CXX_SOURCES = $(wildcard $(SRC_DIR)/*.cpp)
OBJECTS = $(C_SOURCES:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o) $(CXX_SOURCES:$(SRC_DIR)/%.cpp=$(BUILD_DIR)/%.o)
EXECUTABLES = $(OBJECTS:$(BUILD_DIR)/%.o=$(BUILD_DIR)/%)

# Default target
all: build examples test docs

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Build examples
examples: $(EXECUTABLES)

$(BUILD_DIR)/%: $(SRC_DIR)/%.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o $@ $< -lm

$(BUILD_DIR)/%: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -o $@ $< -lm

# Run examples
run-vector: $(BUILD_DIR)/vector-operations
	./$(BUILD_DIR)/vector-operations

run-neural: $(BUILD_DIR)/neural-network
	./$(BUILD_DIR)/neural-network

# Test targets
test: $(EXECUTABLES)
	@echo "Running tests..."
	@for exe in $(EXECUTABLES); do \
		echo "Running $$exe..."; \
		$$exe || exit 1; \
	done
	@echo "All tests passed!"

# Documentation targets
docs:
	@echo "Generating documentation..."
	@if command -v pandoc >/dev/null 2>&1; then \
		pandoc $(DOCS_DIR)/alphaahb-v5-specification.md -o $(DOCS_DIR)/alphaahb-v5-specification.pdf; \
		echo "PDF documentation generated"; \
	else \
		echo "Pandoc not found, skipping PDF generation"; \
	fi

# Clean targets
clean:
	rm -rf $(BUILD_DIR)
	rm -f $(DOCS_DIR)/*.pdf

# Install dependencies (Ubuntu/Debian)
install-deps:
	sudo apt-get update
	sudo apt-get install -y build-essential gcc g++ make pandoc

# Install dependencies (macOS)
install-deps-mac:
	brew install gcc make pandoc

# Install dependencies (Windows)
install-deps-win:
	@echo "Please install the following manually:"
	@echo "- MinGW-w64 or Visual Studio Build Tools"
	@echo "- Make for Windows"
	@echo "- Pandoc (optional, for PDF generation)"

# Format code
format:
	@if command -v clang-format >/dev/null 2>&1; then \
		find $(SRC_DIR) -name "*.c" -o -name "*.cpp" -o -name "*.h" | xargs clang-format -i; \
		echo "Code formatted"; \
	else \
		echo "clang-format not found, skipping code formatting"; \
	fi

# Lint code
lint:
	@if command -v cppcheck >/dev/null 2>&1; then \
		cppcheck --enable=all --std=c99 $(SRC_DIR)/; \
	else \
		echo "cppcheck not found, skipping linting"; \
	fi

# Memory check
memcheck: $(EXECUTABLES)
	@if command -v valgrind >/dev/null 2>&1; then \
		for exe in $(EXECUTABLES); do \
			echo "Running valgrind on $$exe..."; \
			valgrind --leak-check=full --show-leak-kinds=all $$exe; \
		done; \
	else \
		echo "valgrind not found, skipping memory check"; \
	fi

# Performance profiling
profile: $(BUILD_DIR)/vector-operations
	@if command -v perf >/dev/null 2>&1; then \
		perf record -g ./$(BUILD_DIR)/vector-operations; \
		perf report; \
	else \
		echo "perf not found, skipping profiling"; \
	fi

# Package for distribution
package: clean docs
	@echo "Creating distribution package..."
	tar -czf alphaahb-v5-specification.tar.gz \
		--exclude='.git' \
		--exclude='$(BUILD_DIR)' \
		--exclude='*.tar.gz' \
		.
	@echo "Package created: alphaahb-v5-specification.tar.gz"

# Help target
help:
	@echo "Available targets:"
	@echo "  all          - Build everything (default)"
	@echo "  examples     - Build example programs"
	@echo "  test         - Run all tests"
	@echo "  docs         - Generate documentation"
	@echo "  clean        - Remove build artifacts"
	@echo "  install-deps - Install build dependencies"
	@echo "  format       - Format source code"
	@echo "  lint         - Lint source code"
	@echo "  memcheck     - Run memory checks"
	@echo "  profile      - Profile performance"
	@echo "  package      - Create distribution package"
	@echo "  help         - Show this help message"

# Phony targets
.PHONY: all examples test docs clean install-deps install-deps-mac install-deps-win format lint memcheck profile package help run-vector run-neural
