# Dual Target Support: Alpha and Alpham

## Overview

The Alpham ISA provides **dual target support** to ensure maximum compatibility with existing Alpha software while enabling modern MIMD capabilities. This document explains how to use both targets effectively.

## Target Architecture

### Alpha Target (Legacy Compatibility)
- **Target Triple**: `alpha-linux-gnu`, `alpha-netbsd`, `alpha-openbsd`, `alpha-freebsd`
- **Architecture**: Original Alpha architecture
- **Registers**: 32 GPRs (R0-R31), 32 FPRs (F0-F31)
- **Features**: Basic RISC operations, floating-point arithmetic
- **Use Case**: Legacy software compatibility, existing Alpha applications

### Alpham Target (MIMD-Enhanced)
- **Target Triple**: `alpham-linux-gnu`, `alpham-netbsd`, `alpham-openbsd`, `alpham-freebsd`
- **Architecture**: MIMD-enhanced Alpha architecture
- **Registers**: 32 GPRs, 32 FPRs, 32 VPRs, 32 AIRs, 16 MIMDRs, 16 SECRs, 16 SCRs, 8 RTRs, 16 DPRs
- **Features**: All Alpha features + MIMD, Vector, AI/ML, Security, Scientific Computing
- **Use Case**: Modern applications, high-performance computing, AI/ML workloads

## Compilation Examples

### Basic Compilation

#### Original Alpha Target
```bash
# Compile C code for original Alpha
clang -target alpha-linux-gnu -o program program.c

# Compile C++ code for original Alpha
clang++ -target alpha-linux-gnu -o program program.cpp

# Cross-compile from x86_64 to Alpha
clang -target alpha-linux-gnu -march=alpha -o program program.c
```

#### Alpham Target
```bash
# Compile C code for Alpham
clang -target alpham-linux-gnu -o program program.c

# Compile C++ code for Alpham
clang++ -target alpham-linux-gnu -o program program.cpp

# Cross-compile from x86_64 to Alpham
clang -target alpham-linux-gnu -march=alpham -o program program.c
```

### Advanced Compilation

#### With Optimizations
```bash
# Alpha with optimizations
clang -target alpha-linux-gnu -O3 -o program program.c

# Alpham with optimizations
clang -target alpham-linux-gnu -O3 -o program program.c
```

#### With Feature-Specific Optimizations
```bash
# Alpham with vectorization
clang -target alpham-linux-gnu -O3 -mllvm -enable-vectorize -o program program.c

# Alpham with AI/ML optimizations
clang -target alpham-linux-gnu -O3 -mllvm -enable-ai-optimize -o program program.c

# Alpham with MIMD optimizations
clang -target alpham-linux-gnu -O3 -mllvm -enable-mimd-optimize -o program program.c
```

## Target Selection Guide

### When to Use Alpha Target

1. **Legacy Software**: Existing Alpha applications that need to run unchanged
2. **Compatibility**: Software that must run on original Alpha hardware
3. **Simple Applications**: Basic applications that don't need advanced features
4. **Migration**: Gradual migration from Alpha to Alpham

### When to Use Alpham Target

1. **New Development**: New applications that can benefit from modern features
2. **High Performance**: Applications requiring MIMD, vector, or AI/ML capabilities
3. **Scientific Computing**: Applications using advanced mathematical operations
4. **AI/ML Workloads**: Neural networks, machine learning applications
5. **Parallel Processing**: Applications that can benefit from MIMD capabilities

## Feature Comparison

| Feature | Alpha | Alpham | Description |
|---------|-------|--------|-------------|
| **Basic Instructions** | ✅ | ✅ | ADD, SUB, MUL, DIV, etc. |
| **Floating-Point** | ✅ | ✅ | IEEE 754 compliant |
| **Memory Operations** | ✅ | ✅ | Load/Store operations |
| **Branch Operations** | ✅ | ✅ | Conditional branches |
| **Vector Processing** | ❌ | ✅ | 512-bit SIMD operations |
| **AI/ML Operations** | ❌ | ✅ | Neural network primitives |
| **MIMD Operations** | ❌ | ✅ | Multi-core processing |
| **Security Operations** | ❌ | ✅ | Hardware security features |
| **Scientific Computing** | ❌ | ✅ | Specialized math functions |
| **Real-Time Operations** | ❌ | ✅ | Real-time scheduling |
| **Debug/Profiling** | ❌ | ✅ | Performance monitoring |

## Migration Strategy

### Phase 1: Assessment
1. **Inventory**: Identify existing Alpha applications
2. **Analysis**: Determine which applications can benefit from Alpham features
3. **Planning**: Create migration roadmap

### Phase 2: Gradual Migration
1. **Legacy Support**: Keep Alpha target for existing applications
2. **New Development**: Use Alpham target for new applications
3. **Hybrid Approach**: Mix both targets as needed

### Phase 3: Full Migration
1. **Feature Adoption**: Gradually adopt Alpham features in existing applications
2. **Performance Optimization**: Optimize for Alpham capabilities
3. **Complete Migration**: Eventually migrate all applications to Alpham

## Toolchain Support

### Compiler Support
- **LLVM Backend**: Both Alpha and Alpham targets supported
- **GCC Backend**: Planned for future releases
- **Cross-Compilation**: Full cross-compilation support

### Debugger Support
- **GDB**: Full debugging support for both targets
- **Hardware Breakpoints**: Supported on both targets
- **Performance Monitoring**: Enhanced on Alpham target

### Simulator Support
- **Cycle-Accurate**: Both targets supported
- **Multi-Core**: Alpham target supports MIMD simulation
- **Performance Analysis**: Enhanced profiling on Alpham target

## Best Practices

### Development
1. **Start with Alpha**: Begin with Alpha target for compatibility
2. **Gradual Enhancement**: Add Alpham features incrementally
3. **Feature Detection**: Use runtime feature detection when possible
4. **Performance Testing**: Test on both targets

### Deployment
1. **Target Selection**: Choose appropriate target for each application
2. **Mixed Environments**: Support both targets in production
3. **Monitoring**: Monitor performance on both targets
4. **Documentation**: Document target requirements

## Troubleshooting

### Common Issues

#### Target Not Found
```bash
# Error: target 'alpha-linux-gnu' not found
# Solution: Ensure LLVM is built with Alpha target
cmake -DLLVM_TARGETS_TO_BUILD="Alpha;Alpham" ../llvm
```

#### Feature Not Available
```bash
# Error: vector instructions not available on Alpha target
# Solution: Use Alpham target for vector operations
clang -target alpham-linux-gnu -o program program.c
```

#### Compatibility Issues
```bash
# Error: application doesn't run on Alpham target
# Solution: Use Alpha target for legacy compatibility
clang -target alpha-linux-gnu -o program program.c
```

### Debugging
1. **Target Detection**: Verify correct target is being used
2. **Feature Flags**: Check feature flags are properly set
3. **Runtime Detection**: Use runtime feature detection
4. **Logging**: Enable debug logging for target selection

## Conclusion

The dual target support in Alpham provides the perfect balance between legacy compatibility and modern capabilities. By supporting both Alpha and Alpham targets, developers can:

- **Maintain Compatibility**: Existing Alpha software continues to work
- **Enable Innovation**: New applications can use modern features
- **Gradual Migration**: Move from Alpha to Alpham at their own pace
- **Best of Both Worlds**: Choose the right target for each application

This approach ensures that Alpham becomes the natural evolution of the Alpha architecture while preserving the entire existing ecosystem.
