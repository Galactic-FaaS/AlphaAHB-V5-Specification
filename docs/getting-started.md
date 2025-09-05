# Getting Started with Alpha ISA V5 (Alpham)

## 🚀 **Quick Start Guide**

Welcome to the Alpha ISA V5 (Alpham) ISA! This guide will help you get up and running quickly with the most advanced RISC instruction set architecture.

## 📋 **Prerequisites**

### **System Requirements**
- **Operating System**: Linux (Ubuntu 20.04+), Windows 10+, or macOS 10.15+
- **Memory**: 8GB RAM minimum, 16GB recommended
- **Storage**: 10GB free space minimum
- **CPU**: x86_64 or ARM64 architecture

### **Development Tools**
- **Vivado**: 2023.1+ (for SystemVerilog synthesis)
- **Java**: 23+ (for Chisel)
- **Scala CLI**: 1.9.0+ (for Chisel development)
- **Python**: 3.8+ (for tooling)
- **GCC/Clang**: For C examples

## 🏗️ **Installation**

### **1. Clone the Repository**
```bash
git clone https://github.com/your-org/AlphaAHB-V5-Specification.git
cd AlphaAHB-V5-Specification
```

### **2. Install Dependencies**

#### **For SystemVerilog Development**
```bash
# Install Vivado (Xilinx)
# Download from: https://www.xilinx.com/support/download.html

# Install Icarus Verilog (optional)
sudo apt-get install iverilog  # Ubuntu/Debian
brew install icarus-verilog    # macOS
```

#### **For Chisel Development**
```bash
# Install Java 23+
# Download from: https://adoptium.net/

# Install Scala CLI
# Download from: https://scala-cli.virtuslab.org/install
```

#### **For Tooling**
```bash
# Install Python dependencies
pip install -r requirements.txt
```

## 🧪 **Running Your First Test**

### **SystemVerilog Softcore**
```bash
cd softcores/systemverilog
vivado -mode batch -source tests/complete_test.tcl
```

### **Chisel Softcore**
```bash
cd softcores/chisel
scala-cli run tests/CompleteTest.scala
```

## 💻 **Writing Your First Program**

### **1. Create a Simple C Program**
```c
// hello_alpham.c
#include <stdio.h>

int main() {
    printf("Hello, AlphaAHB V5 (Alpham)!\n");
    
    // Example: Vector addition
    int a[4] = {1, 2, 3, 4};
    int b[4] = {5, 6, 7, 8};
    int c[4];
    
    // Vector addition using Alpham SIMD
    for (int i = 0; i < 4; i++) {
        c[i] = a[i] + b[i];
    }
    
    printf("Vector addition result: [%d, %d, %d, %d]\n", 
           c[0], c[1], c[2], c[3]);
    
    return 0;
}
```

### **2. Compile and Run**
```bash
cd examples
gcc -o hello_alpham hello_alpham.c
./hello_alpham
```

## 🔧 **Using the Tooling Suite**

### **Assembler**
```bash
# Assemble AlphaAHB V5 code
./tooling/assembler/alphaahb_as -o program.o program.s
```

### **Simulator**
```bash
# Run simulation
./tooling/simulator/alphaahb_sim program.bin
```

### **Debugger**
```bash
# Debug with GDB-compatible interface
./tooling/debugger/alpham-gdb program.elf
```

## 📚 **Learning Resources**

### **Core Concepts**
1. **[ISA Specification](alphaahb-v5-specification.md)** - Complete instruction set reference
2. **[Assembly Language](specs/assembly-language.md)** - Assembly programming guide
3. **[CPU Design](specs/cpu-design.md)** - Microarchitecture details

### **Advanced Topics**
1. **[Floating-Point](specs/floating-point-arithmetic.md)** - Advanced FP operations
2. **[Vector Processing](specs/vector-operations.md)** - SIMD programming
3. **[MIMD Programming](specs/mimd-programming.md)** - Parallel processing

### **Examples**
- **[Basic Examples](examples/)** - Simple programs to get started
- **[Advanced Examples](examples/)** - Complex algorithms and optimizations
- **[Test Suite](tests/)** - Comprehensive test cases

## 🎯 **Next Steps**

### **For Developers**
1. **Read the [ISA Specification](alphaahb-v5-specification.md)**
2. **Try the [Examples](examples/)**
3. **Run the [Test Suite](tests/)**
4. **Explore the [Tooling](tooling/)**

### **For Hardware Engineers**
1. **Study the [SystemVerilog Softcore](softcores/systemverilog/)**
2. **Examine the [Chisel Implementation](softcores/chisel/)**
3. **Review the [Synthesis Guide](documentation/PRODUCTION_DEPLOYMENT_GUIDE.md)**

### **For Researchers**
1. **Analyze the [Performance Benchmarks](tests/performance-benchmarks.c)**
2. **Study the [AI/ML Integration](specs/ai-ml-integration.md)**
3. **Explore the [Security Features](specs/security-features.md)**

## 🆘 **Getting Help**

### **Documentation**
- **[Complete Specification](alphaahb-v5-specification.md)**
- **[API Reference](docs/api-reference.md)**
- **[FAQ](docs/faq.md)**

### **Community**
- **GitHub Issues**: Report bugs and request features
- **Discussions**: Ask questions and share ideas
- **Contributing**: See [CONTRIBUTING.md](../CONTRIBUTING.md)

### **Support**
- **Email**: support@alpham-isa.org
- **Documentation**: [docs/](docs/)
- **Examples**: [examples/](examples/)

## 🎉 **Welcome to Alpham!**

You're now ready to start developing with the most advanced RISC instruction set architecture. The AlphaAHB V5 (Alpham) provides unprecedented performance and capabilities for modern computing workloads.

Happy coding! 🚀
