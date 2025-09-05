#!/bin/bash
# AlphaAHB V5 Tooling Build Script
# Developed and Maintained by GLCTC Corp.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Build configuration
BUILD_DIR="build"
INSTALL_DIR="install"
PYTHON_VERSION="3.8"
CXX_STANDARD="17"

# Print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check Python version
    if ! python3 --version | grep -q "Python 3\.[8-9]\|Python 3\.[1-9][0-9]"; then
        print_error "Python 3.8+ is required"
        exit 1
    fi
    
    # Check C++ compiler
    if ! command -v g++ &> /dev/null && ! command -v clang++ &> /dev/null; then
        print_error "C++ compiler (g++ or clang++) is required"
        exit 1
    fi
    
    # Check CMake
    if ! command -v cmake &> /dev/null; then
        print_error "CMake is required"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Create build directories
create_directories() {
    print_status "Creating build directories..."
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$INSTALL_DIR"
    
    print_success "Build directories created"
}

# Build Python tools
build_python_tools() {
    print_status "Building Python tools..."
    
    # Make Python scripts executable
    chmod +x assembler/alphaahb_as.py
    chmod +x disassembler/alphaahb_objdump.py
    chmod +x simulator/alphaahb_sim.py
    chmod +x debugger/alphaahb_gdb.py
    chmod +x tests/test_framework.py
    
    # Install Python dependencies
    if [ -f "requirements.txt" ]; then
        pip3 install -r requirements.txt
    fi
    
    print_success "Python tools built"
}

# Build C++ tools
build_cpp_tools() {
    print_status "Building C++ tools..."
    
    cd "$BUILD_DIR"
    
    # Configure with CMake
    cmake -DCMAKE_BUILD_TYPE=Release \
          -DCMAKE_CXX_STANDARD="$CXX_STANDARD" \
          -DCMAKE_INSTALL_PREFIX="../$INSTALL_DIR" \
          ..
    
    # Build
    make -j$(nproc)
    
    # Install
    make install
    
    cd ..
    
    print_success "C++ tools built"
}

# Build LLVM backend
build_llvm_backend() {
    print_status "Building LLVM backend..."
    
    if [ ! -d "llvm-project" ]; then
        print_warning "LLVM project not found, skipping LLVM backend build"
        return
    fi
    
    cd llvm-project
    mkdir -p build
    cd build
    
    # Configure LLVM with AlphaAHB backend
    cmake -G "Unix Makefiles" \
          -DLLVM_ENABLE_PROJECTS="clang;lld" \
          -DLLVM_TARGETS_TO_BUILD="AlphaAHB" \
          -DCMAKE_BUILD_TYPE=Release \
          ../llvm
    
    # Build LLVM
    make -j$(nproc)
    
    cd ../..
    
    print_success "LLVM backend built"
}

# Run tests
run_tests() {
    print_status "Running tests..."
    
    # Run Python tests
    if [ -f "tests/test_framework.py" ]; then
        python3 tests/test_framework.py --parallel --timeout 60
    fi
    
    # Run C++ tests
    if [ -f "$BUILD_DIR/test_runner" ]; then
        "$BUILD_DIR/test_runner"
    fi
    
    # Run performance benchmarks
    if [ -f "tests/benchmark.py" ]; then
        python3 tests/benchmark.py
    fi
    
    # Run compliance tests
    if [ -f "tests/compliance.py" ]; then
        python3 tests/compliance.py
    fi
    
    print_success "Tests completed"
}

# Run CI/CD pipeline
run_ci_pipeline() {
    print_status "Running CI/CD pipeline..."
    
    # Code quality checks
    print_status "Running code quality checks..."
    if command -v pylint &> /dev/null; then
        pylint assembler/*.py disassembler/*.py simulator/*.py debugger/*.py tests/*.py
    fi
    
    if command -v flake8 &> /dev/null; then
        flake8 assembler/*.py disassembler/*.py simulator/*.py debugger/*.py tests/*.py
    fi
    
    # Security scanning
    print_status "Running security scan..."
    if command -v bandit &> /dev/null; then
        bandit -r assembler/ disassembler/ simulator/ debugger/ tests/
    fi
    
    # Build all components
    build_python_tools
    build_cpp_tools
    
    # Run comprehensive tests
    run_tests
    
    # Generate reports
    generate_reports
    
    print_success "CI/CD pipeline completed"
}

# Generate reports
generate_reports() {
    print_status "Generating reports..."
    
    # Test coverage report
    if command -v coverage &> /dev/null; then
        coverage run -m pytest tests/
        coverage html -d coverage_report
        print_success "Coverage report generated"
    fi
    
    # Performance report
    if [ -f "performance_report.json" ]; then
        python3 -c "
import json
with open('performance_report.json', 'r') as f:
    data = json.load(f)
print('Performance Summary:')
print(f'  Total cycles: {data[\"simulation_info\"][\"total_cycles\"]}')
print(f'  Instructions: {data[\"simulation_info\"][\"instructions_executed\"]}')
print(f'  IPC: {data[\"simulation_info\"][\"instructions_executed\"] / data[\"simulation_info\"][\"total_cycles\"]:.2f}')
"
    fi
    
    print_success "Reports generated"
}

# Create installation package
create_package() {
    print_status "Creating installation package..."
    
    # Create package directory
    PACKAGE_DIR="alphaahb-v5-tooling"
    mkdir -p "$PACKAGE_DIR"
    
    # Copy tools
    cp -r assembler "$PACKAGE_DIR/"
    cp -r disassembler "$PACKAGE_DIR/"
    cp -r simulator "$PACKAGE_DIR/"
    cp -r debugger "$PACKAGE_DIR/"
    cp -r tests "$PACKAGE_DIR/"
    cp -r utils "$PACKAGE_DIR/"
    
    # Copy built binaries
    if [ -d "$INSTALL_DIR/bin" ]; then
        cp -r "$INSTALL_DIR/bin" "$PACKAGE_DIR/"
    fi
    
    # Copy documentation
    cp README.md "$PACKAGE_DIR/"
    
    # Create installation script
    cat > "$PACKAGE_DIR/install.sh" << 'EOF'
#!/bin/bash
# AlphaAHB V5 Tooling Installation Script

set -e

INSTALL_DIR="/usr/local/alphaahb-v5"

echo "Installing AlphaAHB V5 Tooling to $INSTALL_DIR..."

# Create installation directory
sudo mkdir -p "$INSTALL_DIR"

# Copy files
sudo cp -r * "$INSTALL_DIR/"

# Create symlinks
sudo ln -sf "$INSTALL_DIR/assembler/alphaahb_as.py" /usr/local/bin/alphaahb-as
sudo ln -sf "$INSTALL_DIR/disassembler/alphaahb_objdump.py" /usr/local/bin/alphaahb-objdump
sudo ln -sf "$INSTALL_DIR/simulator/alphaahb_sim.py" /usr/local/bin/alphaahb-sim
sudo ln -sf "$INSTALL_DIR/debugger/alphaahb_gdb.py" /usr/local/bin/alphaahb-gdb
sudo ln -sf "$INSTALL_DIR/tests/test_framework.py" /usr/local/bin/alphaahb-test

echo "Installation complete!"
echo "Tools are available as: alphaahb-as, alphaahb-objdump, alphaahb-sim, alphaahb-gdb, alphaahb-test"
EOF
    
    chmod +x "$PACKAGE_DIR/install.sh"
    
    # Create tarball
    tar -czf "alphaahb-v5-tooling.tar.gz" "$PACKAGE_DIR"
    
    print_success "Installation package created: alphaahb-v5-tooling.tar.gz"
}

# Main build function
main() {
    print_status "Starting AlphaAHB V5 Tooling build..."
    
    # Parse command line arguments
    BUILD_PYTHON=true
    BUILD_CPP=true
    BUILD_LLVM=false
    RUN_TESTS=false
    CREATE_PACKAGE=false
    RUN_CI=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --python-only)
                BUILD_CPP=false
                BUILD_LLVM=false
                shift
                ;;
            --cpp-only)
                BUILD_PYTHON=false
                BUILD_LLVM=false
                shift
                ;;
            --with-llvm)
                BUILD_LLVM=true
                shift
                ;;
            --test)
                RUN_TESTS=true
                shift
                ;;
            --package)
                CREATE_PACKAGE=true
                shift
                ;;
            --ci)
                RUN_CI=true
                shift
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --python-only    Build only Python tools"
                echo "  --cpp-only       Build only C++ tools"
                echo "  --with-llvm      Build LLVM backend"
                echo "  --test           Run tests after building"
                echo "  --package        Create installation package"
                echo "  --ci             Run full CI/CD pipeline"
                echo "  --help           Show this help message"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Run build steps
    if [ "$RUN_CI" = true ]; then
        run_ci_pipeline
    else
        check_prerequisites
        create_directories
        
        if [ "$BUILD_PYTHON" = true ]; then
            build_python_tools
        fi
        
        if [ "$BUILD_CPP" = true ]; then
            build_cpp_tools
        fi
        
        if [ "$BUILD_LLVM" = true ]; then
            build_llvm_backend
        fi
        
        if [ "$RUN_TESTS" = true ]; then
            run_tests
        fi
        
        if [ "$CREATE_PACKAGE" = true ]; then
            create_package
        fi
    fi
    
    print_success "Build completed successfully!"
}

# Run main function
main "$@"
