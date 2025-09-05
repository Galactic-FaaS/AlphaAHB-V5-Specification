# Alpha ISA V5 (Alpham) Tooling Suite

*Developed and Maintained by GLCTC Corp.*

## Overview

This comprehensive tooling suite provides complete development, testing, and analysis capabilities for the Alpha ISA V5 (Alpham - Alpha + MIMD) Instruction Set Architecture. The tooling supports both original Alpha (legacy compatibility) and modern Alpha ISA V5 (MIMD-enhanced) targets, including advanced arithmetic, AI/ML operations, vector processing, MIMD support, security extensions, and more.

## Tool Categories

### 1. Assembler (`assembler/`)
- **alpham-as**: Full-featured assembler supporting both Alpha and Alpham instructions
- **Features**:
  - Dual target support (Alpha legacy, Alpham MIMD-enhanced)
  - Complete instruction set support (Basic, Advanced Arithmetic, AI/ML, Vector, MIMD, Security, Scientific Computing, Real-Time, Debug)
  - Macro support and conditional assembly
  - Multiple output formats (binary, ELF, Intel HEX)
  - Cross-platform support (Windows, Linux, macOS)
  - Advanced optimization and code generation

### 2. Disassembler (`disassembler/`)
- **alpham-objdump**: Binary analysis and disassembly tool
- **Features**:
  - Dual target support (Alpha, Alpham)
  - Complete instruction disassembly
  - Symbol table analysis
  - Control flow analysis
  - Performance profiling support
  - Multiple input formats

### 3. Simulator (`simulator/`)
- **alpham-sim**: Cycle-accurate architectural simulator
- **Features**:
  - Dual target support (Alpha, Alpham)
  - Full pipeline simulation (12-stage)
  - Multi-core MIMD support (Alpham target)
  - Memory hierarchy simulation
  - Performance counters and profiling
  - Debug interface support
  - Real-time execution

### 4. Compiler Backend (`compiler/`)
- **LLVM Backend**: Complete LLVM targets for Alpha and Alpham
- **Features**:
  - Dual target support (alpha-linux-gnu, alpham-linux-gnu)
  - C/C++ compilation support
  - Advanced optimization passes
  - Vectorization support (Alpham target)
  - AI/ML operation optimization (Alpham target)
  - Cross-compilation support

### 5. Debugger (`debugger/`)
- **alpham-gdb**: GDB-compatible debugger
- **Features**:
  - Dual target support (Alpha, Alpham)
  - Full GDB protocol support
  - Hardware breakpoint support
  - Performance monitoring
  - Multi-core debugging (Alpham target)
  - Real-time debugging

### 6. Test Framework (`tests/`)
- **Comprehensive Test Suite**: Complete validation framework
- **Features**:
  - Unit tests for all instructions
  - Integration tests
  - Performance benchmarks
  - Stress testing
  - Compliance validation

### 7. Utilities (`utils/`)
- **Development Tools**: Supporting utilities
- **Features**:
  - Binary manipulation tools
  - Performance analysis tools
  - Documentation generators
  - Code formatters

## Quick Start

### Prerequisites
- Python 3.8+ (for Python-based tools)
- C++17 compiler (for C++ tools)
- LLVM 15+ (for compiler backend)
- CMake 3.20+ (for building)

### Building All Tools
```bash
cd tooling
./build.sh
```

### Building Individual Tools
```bash
cd tooling/assembler
make
```

## Usage Examples

### Assembling Code
```bash
alphaahb-as -o program.bin program.s
```

### Simulating Execution
```bash
alphaahb-sim -c 4 -m 4GB program.bin
```

### Debugging
```bash
alphaahb-gdb program.bin
```

## Architecture Support

- **Instruction Sets**: All AlphaAHB V5 instruction categories
- **Data Types**: IEEE 754-2019, Block FP, Arbitrary Precision, Tapered FP
- **Precision**: FP16, FP32, FP64, FP128, FP256, FP512
- **AI/ML**: Complete NPU support with all neural network operations
- **Vector Processing**: 512-bit SIMD with advanced operations
- **MIMD**: Multi-core, HTM, NUMA support
- **Security**: Hardware security extensions and cryptographic acceleration
- **Scientific Computing**: Decimal FP, interval arithmetic, special functions

## Performance Characteristics

- **Assembler**: ~1M instructions/second processing
- **Simulator**: ~100K cycles/second simulation
- **Compiler**: Full optimization with vectorization
- **Debugger**: Real-time debugging with minimal overhead

## Documentation

Each tool includes comprehensive documentation:
- User manuals
- API references
- Examples and tutorials
- Performance tuning guides

## Contributing

See the main project README for contribution guidelines.

## License

See the main project LICENSE file.

---

*This tooling suite is part of the AlphaAHB V5 ISA specification maintained by GLCTC Corp.*
