# AlphaAHB V5 (Alpham) Examples Guide

## 🎯 **Learning by Example**

This guide provides comprehensive examples for the AlphaAHB V5 (Alpham) ISA, from basic programming concepts to advanced AI/ML applications.

## 📚 **Example Categories**

### **Basic Examples**
- **Hello World** - Simple program structure
- **Arithmetic Operations** - Basic math operations
- **Control Flow** - Loops and conditionals
- **Memory Operations** - Load and store operations

### **Advanced Examples**
- **Vector Processing** - SIMD operations
- **Floating-Point** - Advanced FP arithmetic
- **AI/ML Applications** - Neural network operations
- **MIMD Programming** - Parallel processing
- **Security Features** - Secure programming

## 🚀 **Getting Started Examples**

### **1. Hello World**

#### **C Implementation**
```c
// hello_world.c
#include <stdio.h>

int main() {
    printf("Hello, AlphaAHB V5 (Alpham)!\n");
    return 0;
}
```

#### **Assembly Implementation**
```assembly
# hello_world.s
.section .text
.global _start

_start:
    # System call: write
    LDI r1, 1          # File descriptor (stdout)
    LDI r2, message    # Message address
    LDI r3, 20         # Message length
    SYSCALL r1, r2, r3
    
    # System call: exit
    LDI r1, 0          # Exit code
    SYSCALL r1

.section .data
message:
    .ascii "Hello, AlphaAHB V5 (Alpham)!\n"
```

#### **Compilation and Execution**
```bash
# Compile C version
gcc -o hello_world hello_world.c
./hello_world

# Assemble and link assembly version
alpham-as -o hello_world.o hello_world.s
alpham-ld -o hello_world hello_world.o
./hello_world
```

### **2. Basic Arithmetic**

#### **C Implementation**
```c
// arithmetic.c
#include <stdio.h>

int main() {
    int a = 10;
    int b = 20;
    int sum, diff, prod, quot;
    
    // Basic arithmetic
    sum = a + b;
    diff = b - a;
    prod = a * b;
    quot = b / a;
    
    printf("a = %d, b = %d\n", a, b);
    printf("Sum: %d\n", sum);
    printf("Difference: %d\n", diff);
    printf("Product: %d\n", prod);
    printf("Quotient: %d\n", quot);
    
    return 0;
}
```

#### **Assembly Implementation**
```assembly
# arithmetic.s
.section .text
.global _start

_start:
    # Load values
    LDI r1, 10         # a = 10
    LDI r2, 20         # b = 20
    
    # Arithmetic operations
    ADD r3, r1, r2     # sum = a + b
    SUB r4, r2, r1     # diff = b - a
    MUL r5, r1, r2     # prod = a * b
    DIV r6, r2, r1     # quot = b / a
    
    # Store results
    ST (result_sum), r3
    ST (result_diff), r4
    ST (result_prod), r5
    ST (result_quot), r6
    
    # Exit
    LDI r1, 0
    SYSCALL r1

.section .data
result_sum:  .word 0
result_diff: .word 0
result_prod: .word 0
result_quot: .word 0
```

### **3. Control Flow**

#### **C Implementation**
```c
// control_flow.c
#include <stdio.h>

int main() {
    int i;
    
    // For loop
    printf("For loop:\n");
    for (i = 0; i < 5; i++) {
        printf("i = %d\n", i);
    }
    
    // While loop
    printf("\nWhile loop:\n");
    i = 0;
    while (i < 5) {
        printf("i = %d\n", i);
        i++;
    }
    
    // If-else
    printf("\nIf-else:\n");
    if (i == 5) {
        printf("i equals 5\n");
    } else {
        printf("i does not equal 5\n");
    }
    
    return 0;
}
```

#### **Assembly Implementation**
```assembly
# control_flow.s
.section .text
.global _start

_start:
    # For loop
    LDI r1, 0          # i = 0
    LDI r2, 5          # limit = 5
    
loop_start:
    # Check condition
    BGE r1, r2, loop_end
    
    # Loop body
    # (Print i - simplified)
    
    # Increment
    ADDI r1, r1, 1
    JMP loop_start
    
loop_end:
    # While loop
    LDI r1, 0          # i = 0
    
while_start:
    # Check condition
    BGE r1, r2, while_end
    
    # Loop body
    # (Print i - simplified)
    
    # Increment
    ADDI r1, r1, 1
    JMP while_start
    
while_end:
    # If-else
    LDI r3, 5
    BNE r1, r3, else_branch
    
    # If branch
    # (Print "i equals 5" - simplified)
    JMP if_end
    
else_branch:
    # Else branch
    # (Print "i does not equal 5" - simplified)
    
if_end:
    # Exit
    LDI r1, 0
    SYSCALL r1
```

## 🔢 **Advanced Arithmetic Examples**

### **4. Floating-Point Operations**

#### **C Implementation**
```c
// floating_point.c
#include <stdio.h>
#include <math.h>

int main() {
    float a = 3.14159f;
    float b = 2.71828f;
    float sum, diff, prod, quot, sqrt_a, pow_ab;
    
    // Basic FP operations
    sum = a + b;
    diff = a - b;
    prod = a * b;
    quot = a / b;
    
    // Advanced FP operations
    sqrt_a = sqrtf(a);
    pow_ab = powf(a, b);
    
    printf("a = %f, b = %f\n", a, b);
    printf("Sum: %f\n", sum);
    printf("Difference: %f\n", diff);
    printf("Product: %f\n", prod);
    printf("Quotient: %f\n", quot);
    printf("Square root of a: %f\n", sqrt_a);
    printf("a^b: %f\n", pow_ab);
    
    return 0;
}
```

#### **Assembly Implementation**
```assembly
# floating_point.s
.section .text
.global _start

_start:
    # Load FP values
    LDI f1, 0x40490FDB  # 3.14159 (as float)
    LDI f2, 0x402DF854  # 2.71828 (as float)
    
    # FP arithmetic
    FADD f3, f1, f2     # sum = a + b
    FSUB f4, f1, f2     # diff = a - b
    FMUL f5, f1, f2     # prod = a * b
    FDIV f6, f1, f2     # quot = a / b
    
    # Advanced FP operations
    FSQRT f7, f1        # sqrt_a = sqrt(a)
    FPOW f8, f1, f2     # pow_ab = a^b
    
    # Store results
    ST (result_sum), f3
    ST (result_diff), f4
    ST (result_prod), f5
    ST (result_quot), f6
    ST (result_sqrt), f7
    ST (result_pow), f8
    
    # Exit
    LDI r1, 0
    SYSCALL r1

.section .data
result_sum:  .float 0.0
result_diff: .float 0.0
result_prod: .float 0.0
result_quot: .float 0.0
result_sqrt: .float 0.0
result_pow:  .float 0.0
```

### **5. Vector Operations**

#### **C Implementation**
```c
// vector_operations.c
#include <stdio.h>

int main() {
    int a[4] = {1, 2, 3, 4};
    int b[4] = {5, 6, 7, 8};
    int c[4];
    int i;
    
    // Vector addition
    for (i = 0; i < 4; i++) {
        c[i] = a[i] + b[i];
    }
    
    printf("Vector addition:\n");
    printf("a = [%d, %d, %d, %d]\n", a[0], a[1], a[2], a[3]);
    printf("b = [%d, %d, %d, %d]\n", b[0], b[1], b[2], b[3]);
    printf("c = [%d, %d, %d, %d]\n", c[0], c[1], c[2], c[3]);
    
    // Vector dot product
    int dot_product = 0;
    for (i = 0; i < 4; i++) {
        dot_product += a[i] * b[i];
    }
    
    printf("Dot product: %d\n", dot_product);
    
    return 0;
}
```

#### **Assembly Implementation**
```assembly
# vector_operations.s
.section .text
.global _start

_start:
    # Load vectors
    LDI v1, vector_a   # Load vector a
    LDI v2, vector_b   # Load vector b
    
    # Vector addition
    VADD v3, v1, v2    # v3 = v1 + v2
    
    # Store result
    ST (vector_c), v3
    
    # Vector dot product
    VDOT f1, v1, v2    # f1 = dot(v1, v2)
    ST (dot_product), f1
    
    # Exit
    LDI r1, 0
    SYSCALL r1

.section .data
vector_a:   .word 1, 2, 3, 4
vector_b:   .word 5, 6, 7, 8
vector_c:   .word 0, 0, 0, 0
dot_product: .float 0.0
```

## 🤖 **AI/ML Examples**

### **6. Neural Network Forward Pass**

#### **C Implementation**
```c
// neural_network.c
#include <stdio.h>
#include <math.h>

// ReLU activation function
float relu(float x) {
    return (x > 0) ? x : 0;
}

// Sigmoid activation function
float sigmoid(float x) {
    return 1.0f / (1.0f + expf(-x));
}

int main() {
    // Input layer (4 neurons)
    float input[4] = {1.0f, 2.0f, 3.0f, 4.0f};
    
    // Hidden layer weights (4x3)
    float weights[4][3] = {
        {0.1f, 0.2f, 0.3f},
        {0.4f, 0.5f, 0.6f},
        {0.7f, 0.8f, 0.9f},
        {1.0f, 1.1f, 1.2f}
    };
    
    // Hidden layer bias
    float bias[3] = {0.1f, 0.2f, 0.3f};
    
    // Hidden layer output
    float hidden[3];
    
    // Forward pass
    for (int j = 0; j < 3; j++) {
        hidden[j] = bias[j];
        for (int i = 0; i < 4; i++) {
            hidden[j] += input[i] * weights[i][j];
        }
        hidden[j] = relu(hidden[j]);
    }
    
    // Output layer (3 neurons)
    float output[3];
    for (int j = 0; j < 3; j++) {
        output[j] = sigmoid(hidden[j]);
    }
    
    // Print results
    printf("Input: [%.2f, %.2f, %.2f, %.2f]\n", 
           input[0], input[1], input[2], input[3]);
    printf("Hidden: [%.2f, %.2f, %.2f]\n", 
           hidden[0], hidden[1], hidden[2]);
    printf("Output: [%.2f, %.2f, %.2f]\n", 
           output[0], output[1], output[2]);
    
    return 0;
}
```

#### **Assembly Implementation**
```assembly
# neural_network.s
.section .text
.global _start

_start:
    # Load input vector
    LDI v1, input_vector
    
    # Load weights matrix
    LDI v2, weights_matrix
    
    # Load bias vector
    LDI v3, bias_vector
    
    # Matrix-vector multiplication
    VMUL v4, v1, v2    # v4 = input * weights
    
    # Add bias
    VADD v5, v4, v3    # v5 = v4 + bias
    
    # ReLU activation
    VRELU v6, v5       # v6 = relu(v5)
    
    # Sigmoid activation
    VSIGMOID v7, v6    # v7 = sigmoid(v6)
    
    # Store output
    ST (output_vector), v7
    
    # Exit
    LDI r1, 0
    SYSCALL r1

.section .data
input_vector:  .float 1.0, 2.0, 3.0, 4.0
weights_matrix: .float 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2
bias_vector:   .float 0.1, 0.2, 0.3
output_vector: .float 0.0, 0.0, 0.0
```

### **7. Convolution Operation**

#### **C Implementation**
```c
// convolution.c
#include <stdio.h>

int main() {
    // Input image (5x5)
    int input[5][5] = {
        {1, 2, 3, 4, 5},
        {6, 7, 8, 9, 10},
        {11, 12, 13, 14, 15},
        {16, 17, 18, 19, 20},
        {21, 22, 23, 24, 25}
    };
    
    // Kernel (3x3)
    int kernel[3][3] = {
        {1, 0, -1},
        {2, 0, -2},
        {1, 0, -1}
    };
    
    // Output (3x3)
    int output[3][3];
    
    // Convolution
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            output[i][j] = 0;
            for (int ki = 0; ki < 3; ki++) {
                for (int kj = 0; kj < 3; kj++) {
                    output[i][j] += input[i + ki][j + kj] * kernel[ki][kj];
                }
            }
        }
    }
    
    // Print output
    printf("Convolution output:\n");
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            printf("%d ", output[i][j]);
        }
        printf("\n");
    }
    
    return 0;
}
```

#### **Assembly Implementation**
```assembly
# convolution.s
.section .text
.global _start

_start:
    # Load input image
    LDI v1, input_image
    
    # Load kernel
    LDI v2, kernel
    
    # Convolution operation
    VCONV v3, v1, v2   # v3 = conv2d(input, kernel)
    
    # Store output
    ST (output_image), v3
    
    # Exit
    LDI r1, 0
    SYSCALL r1

.section .data
input_image:  .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25
kernel:       .word 1, 0, -1, 2, 0, -2, 1, 0, -1
output_image: .word 0, 0, 0, 0, 0, 0, 0, 0, 0
```

## 🔒 **Security Examples**

### **8. Secure Memory Operations**

#### **C Implementation**
```c
// secure_memory.c
#include <stdio.h>
#include <string.h>

int main() {
    // Secure memory allocation
    char* secure_data = malloc(1024);
    if (secure_data == NULL) {
        printf("Memory allocation failed\n");
        return 1;
    }
    
    // Initialize with secure data
    strcpy(secure_data, "Sensitive information");
    
    // Use secure data
    printf("Secure data: %s\n", secure_data);
    
    // Clear sensitive data
    memset(secure_data, 0, 1024);
    
    // Free memory
    free(secure_data);
    
    return 0;
}
```

#### **Assembly Implementation**
```assembly
# secure_memory.s
.section .text
.global _start

_start:
    # Allocate secure memory
    LDI r1, 1024       # Size
    SYSCALL r1         # Allocate
    
    # Store secure data
    LDI r2, secure_string
    LDI r3, 0          # Index
    LDI r4, 0          # Character
    
secure_loop:
    LDB r4, (r2)       # Load character
    BEQ r4, r0, secure_end  # Check for null terminator
    
    # Store character securely
    STB (r1, r3), r4   # Store character
    
    # Increment
    ADDI r2, r2, 1
    ADDI r3, r3, 1
    JMP secure_loop
    
secure_end:
    # Clear sensitive data
    LDI r2, 0          # Zero
    LDI r3, 0          # Index
    
clear_loop:
    LDI r4, 1024       # Size
    BGE r3, r4, clear_end
    
    # Clear byte
    STB (r1, r3), r2   # Store zero
    
    # Increment
    ADDI r3, r3, 1
    JMP clear_loop
    
clear_end:
    # Free memory
    SYSCALL r1         # Free
    
    # Exit
    LDI r1, 0
    SYSCALL r1

.section .data
secure_string: .ascii "Sensitive information\0"
```

## 🚀 **Running Examples**

### **Compilation and Execution**
```bash
# Compile C examples
gcc -o hello_world hello_world.c
gcc -o arithmetic arithmetic.c
gcc -o floating_point floating_point.c
gcc -o vector_operations vector_operations.c
gcc -o neural_network neural_network.c
gcc -o convolution convolution.c
gcc -o secure_memory secure_memory.c

# Run examples
./hello_world
./arithmetic
./floating_point
./vector_operations
./neural_network
./convolution
./secure_memory
```

### **Assembly Examples**
```bash
# Assemble and link
alpham-as -o hello_world.o hello_world.s
alpham-ld -o hello_world hello_world.o
./hello_world

# Run with simulator
alpham-sim hello_world.bin

# Debug with GDB
alpham-gdb hello_world.elf
```

## 📚 **Learning Path**

### **Beginner**
1. **Hello World** - Basic program structure
2. **Arithmetic** - Basic math operations
3. **Control Flow** - Loops and conditionals
4. **Memory Operations** - Load and store

### **Intermediate**
1. **Floating-Point** - Advanced FP operations
2. **Vector Operations** - SIMD programming
3. **Function Calls** - Subroutine programming
4. **Data Structures** - Arrays and structures

### **Advanced**
1. **AI/ML Applications** - Neural network programming
2. **MIMD Programming** - Parallel processing
3. **Security Features** - Secure programming
4. **Performance Optimization** - Code optimization

## 🎯 **Best Practices**

### **Code Organization**
1. **Use meaningful names** for variables and functions
2. **Add comments** to explain complex logic
3. **Organize code** into logical sections
4. **Follow coding standards** for consistency

### **Performance**
1. **Use vector instructions** for data-parallel operations
2. **Minimize memory accesses** with register optimization
3. **Enable compiler optimizations** (-O3, -march=alpham)
4. **Profile and measure** performance

### **Security**
1. **Validate input** to prevent buffer overflows
2. **Use secure memory** operations
3. **Enable security features** (MPK, CFI, PA)
4. **Follow secure coding** practices

This examples guide provides comprehensive coverage of AlphaAHB V5 (Alpham) programming from basic concepts to advanced applications.
