#!/usr/bin/env python3
"""
AlphaAHB V5 Interactive Documentation and Learning Platform
Developed and Maintained by GLCTC Corp.

Interactive documentation, tutorials, and learning platform for AlphaAHB V5 ISA.
Includes interactive examples, code playground, and comprehensive learning resources.
"""

import sys
import os
import argparse
import json
import webbrowser
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass, asdict
from enum import Enum
import http.server
import socketserver
import threading
import time
from pathlib import Path
import markdown
from jinja2 import Template

class ContentType(Enum):
    """Content type enumeration"""
    TUTORIAL = "tutorial"
    REFERENCE = "reference"
    EXAMPLE = "example"
    EXERCISE = "exercise"
    QUIZ = "quiz"
    INTERACTIVE = "interactive"

class DifficultyLevel(Enum):
    """Difficulty level enumeration"""
    BEGINNER = "beginner"
    INTERMEDIATE = "intermediate"
    ADVANCED = "advanced"
    EXPERT = "expert"

@dataclass
class LearningContent:
    """Learning content representation"""
    id: str
    title: str
    content_type: ContentType
    difficulty: DifficultyLevel
    description: str
    content: str
    prerequisites: List[str]
    learning_objectives: List[str]
    estimated_time: int  # minutes
    tags: List[str]

@dataclass
class InteractiveExample:
    """Interactive example representation"""
    id: str
    title: str
    description: str
    code_template: str
    expected_output: str
    hints: List[str]
    solution: str

class AlphaAHBInteractiveDocs:
    """Main interactive documentation class"""
    
    def __init__(self, port: int = 8080):
        self.port = port
        self.content = {}
        self.interactive_examples = {}
        self.learning_paths = {}
        
        # Initialize content
        self._initialize_content()
        
        # Initialize interactive examples
        self._initialize_interactive_examples()
        
        # Initialize learning paths
        self._initialize_learning_paths()
        
        # Setup web server
        self._setup_web_server()
    
    def _initialize_content(self):
        """Initialize learning content"""
        # Tutorial content
        self.content['tutorials'] = {
            'getting_started': LearningContent(
                id='getting_started',
                title='Getting Started with AlphaAHB V5',
                content_type=ContentType.TUTORIAL,
                difficulty=DifficultyLevel.BEGINNER,
                description='Introduction to AlphaAHB V5 ISA and basic concepts',
                content='''
# Getting Started with AlphaAHB V5

## Introduction

The AlphaAHB V5 Instruction Set Architecture (ISA) is a modern, high-performance processor architecture designed for advanced computing applications including AI/ML, scientific computing, and real-time systems.

## Key Features

- **12-stage Pipeline**: Advanced out-of-order execution
- **Vector Processing**: 512-bit SIMD operations
- **AI/ML Acceleration**: Dedicated neural processing units
- **Security Extensions**: Hardware security features
- **Multiple Precision**: Support for FP16 to FP256

## Basic Concepts

### Registers
AlphaAHB V5 provides several register types:
- **General Purpose**: R0-R31 (64-bit)
- **Floating Point**: F0-F31 (IEEE 754 compliant)
- **Vector**: V0-V15 (512-bit SIMD)
- **AI/ML**: Specialized for neural networks
- **Security**: Hardware security features

### Memory Architecture
- **L1 Cache**: 32KB instruction + 32KB data
- **L2 Cache**: 256KB unified
- **L3 Cache**: 2MB shared
- **Memory Management**: Advanced MMU with TLB

## Your First Program

Let's write a simple "Hello World" program:

```assembly
.section .text
.global _start

_start:
    # Load address of message
    LDI R0, message
    LDI R1, 13  # Message length
    
    # System call to write
    LDI R2, 1   # File descriptor (stdout)
    SYSCALL 1   # Write system call
    
    # Exit program
    LDI R0, 0   # Exit code
    SYSCALL 60  # Exit system call

.section .data
message:
    .ascii "Hello, World!\n"
```

## Next Steps

1. Learn about [Basic Instructions](/tutorials/basic_instructions)
2. Explore [Memory Operations](/tutorials/memory_operations)
3. Try [Vector Processing](/tutorials/vector_processing)
''',
                prerequisites=[],
                learning_objectives=[
                    'Understand AlphaAHB V5 architecture basics',
                    'Learn about register types and memory hierarchy',
                    'Write and run a simple assembly program'
                ],
                estimated_time=30,
                tags=['introduction', 'basics', 'assembly']
            ),
            
            'basic_instructions': LearningContent(
                id='basic_instructions',
                title='Basic Instructions',
                content_type=ContentType.TUTORIAL,
                difficulty=DifficultyLevel.BEGINNER,
                description='Learn about basic AlphaAHB V5 instructions',
                content='''
# Basic Instructions

## Arithmetic Instructions

### Addition
```assembly
ADD R0, R1, R2    # R0 = R1 + R2
ADD R0, R1, #42   # R0 = R1 + 42 (immediate)
```

### Subtraction
```assembly
SUB R0, R1, R2    # R0 = R1 - R2
SUB R0, R1, #42   # R0 = R1 - 42 (immediate)
```

### Multiplication
```assembly
MUL R0, R1, R2    # R0 = R1 * R2
MUL R0, R1, #42   # R0 = R1 * 42 (immediate)
```

### Division
```assembly
DIV R0, R1, R2    # R0 = R1 / R2
DIV R0, R1, #42   # R0 = R1 / 42 (immediate)
```

## Logical Instructions

### Bitwise AND
```assembly
AND R0, R1, R2    # R0 = R1 & R2
AND R0, R1, #0xFF # R0 = R1 & 0xFF
```

### Bitwise OR
```assembly
OR R0, R1, R2     # R0 = R1 | R2
OR R0, R1, #0xFF  # R0 = R1 | 0xFF
```

### Bitwise XOR
```assembly
XOR R0, R1, R2    # R0 = R1 ^ R2
XOR R0, R1, #0xFF # R0 = R1 ^ 0xFF
```

## Comparison Instructions

### Compare
```assembly
CMP R0, R1        # Compare R0 with R1, set flags
CMP R0, #42       # Compare R0 with 42, set flags
```

### Test
```assembly
TEST R0, R1       # Test R0 & R1, set flags
TEST R0, #0xFF    # Test R0 & 0xFF, set flags
```

## Control Flow

### Unconditional Jump
```assembly
JMP label         # Jump to label
```

### Conditional Jumps
```assembly
JZ label          # Jump if zero flag set
JNZ label         # Jump if zero flag not set
JL label          # Jump if less than
JG label          # Jump if greater than
```

### Function Calls
```assembly
CALL function     # Call function
RET               # Return from function
```

## Examples

### Simple Loop
```assembly
# Count from 0 to 9
LDI R0, 0         # Counter
LDI R1, 10        # Loop limit

loop:
    ADD R0, R0, 1 # Increment counter
    CMP R0, R1    # Compare with limit
    JL loop       # Jump if less than limit
```

### Conditional Execution
```assembly
# If R0 > R1, then R2 = R0, else R2 = R1
CMP R0, R1        # Compare R0 and R1
JG greater        # Jump if R0 > R1
MOV R2, R1        # R2 = R1
JMP done
greater:
    MOV R2, R0    # R2 = R0
done:
    # Continue...
```
''',
                prerequisites=['getting_started'],
                learning_objectives=[
                    'Learn basic arithmetic and logical instructions',
                    'Understand comparison and control flow instructions',
                    'Write simple programs with loops and conditionals'
                ],
                estimated_time=45,
                tags=['instructions', 'arithmetic', 'control-flow']
            ),
            
            'vector_processing': LearningContent(
                id='vector_processing',
                title='Vector Processing',
                content_type=ContentType.TUTORIAL,
                difficulty=DifficultyLevel.INTERMEDIATE,
                description='Learn about AlphaAHB V5 vector processing capabilities',
                content='''
# Vector Processing

## Introduction

AlphaAHB V5 provides powerful vector processing capabilities with 512-bit SIMD operations. This allows you to perform the same operation on multiple data elements simultaneously.

## Vector Registers

- **V0-V15**: 512-bit vector registers
- Each register can hold:
  - 16 × 32-bit integers
  - 8 × 64-bit integers
  - 16 × 32-bit floating-point numbers
  - 8 × 64-bit floating-point numbers

## Vector Instructions

### Vector Addition
```assembly
VADD V0, V1, V2   # V0 = V1 + V2 (element-wise)
VADD V0, V1, #42  # V0 = V1 + 42 (broadcast)
```

### Vector Multiplication
```assembly
VMUL V0, V1, V2   # V0 = V1 * V2 (element-wise)
VMUL V0, V1, #42  # V0 = V1 * 42 (broadcast)
```

### Vector Dot Product
```assembly
VDOT F0, V1, V2   # F0 = dot product of V1 and V2
```

### Vector Sum
```assembly
VSUM F0, V1       # F0 = sum of all elements in V1
```

### Vector Maximum/Minimum
```assembly
VMAX V0, V1, V2   # V0 = max(V1, V2) element-wise
VMIN V0, V1, V2   # V0 = min(V1, V2) element-wise
```

## Examples

### Array Addition
```assembly
# Add two arrays of 16 integers
LDI R0, array1    # Address of first array
LDI R1, array2    # Address of second array
LDI R2, result    # Address of result array

# Load vectors
VLOAD V1, [R0]    # Load 16 integers from array1
VLOAD V2, [R1]    # Load 16 integers from array2

# Add vectors
VADD V0, V1, V2   # V0 = V1 + V2

# Store result
VSTORE V0, [R2]   # Store result to array
```

### Matrix Multiplication
```assembly
# Multiply two 4x4 matrices using vector operations
# This is a simplified example showing the concept

# Load first row of matrix A
VLOAD V1, [R0]    # R0 points to first row of A

# Load first column of matrix B
VLOAD V2, [R1]    # R1 points to first column of B

# Compute dot product
VDOT F0, V1, V2   # F0 = dot product

# Store result
FSTORE F0, [R2]   # Store to result matrix
```

### Vector Reduction
```assembly
# Find maximum value in an array
LDI R0, array     # Address of array
LDI R1, 16        # Array length

# Load vector
VLOAD V1, [R0]    # Load 16 elements

# Find maximum
VMAX V0, V1, V1   # V0 = max(V1, V1) = V1
VSUM F0, V0       # F0 = maximum value
```

## Performance Tips

1. **Align Data**: Ensure arrays are aligned to 64-byte boundaries
2. **Use Appropriate Data Types**: Choose data types that match your vector width
3. **Minimize Memory Access**: Load data once, process multiple times
4. **Consider Cache**: Structure your data to fit in cache

## Advanced Features

### Predicated Execution
```assembly
# Only process elements where condition is true
VCMP V1, V2       # Compare V1 and V2
VMASK V3, V1, V2  # Create mask based on comparison
VADD V0, V1, V2   # Add only where mask is true
```

### Gather/Scatter
```assembly
# Gather elements from non-contiguous memory locations
VGATHER V0, [R0], V1  # Gather elements using indices in V1

# Scatter elements to non-contiguous memory locations
VSCATTER V0, [R0], V1 # Scatter elements using indices in V1
```
''',
                prerequisites=['basic_instructions'],
                learning_objectives=[
                    'Understand vector processing concepts',
                    'Learn vector instructions and operations',
                    'Write efficient vectorized code'
                ],
                estimated_time=60,
                tags=['vector', 'simd', 'performance']
            )
        }
        
        # Reference content
        self.content['reference'] = {
            'instruction_set': LearningContent(
                id='instruction_set',
                title='Instruction Set Reference',
                content_type=ContentType.REFERENCE,
                difficulty=DifficultyLevel.INTERMEDIATE,
                description='Complete AlphaAHB V5 instruction set reference',
                content='''
# AlphaAHB V5 Instruction Set Reference

## Instruction Format

AlphaAHB V5 instructions follow a consistent format:
```
[OPCODE] [DEST], [SRC1], [SRC2/IMM]
```

## Arithmetic Instructions

| Instruction | Description | Format | Example |
|-------------|-------------|--------|---------|
| ADD | Add | ADD Rd, Rs1, Rs2 | ADD R0, R1, R2 |
| SUB | Subtract | SUB Rd, Rs1, Rs2 | SUB R0, R1, R2 |
| MUL | Multiply | MUL Rd, Rs1, Rs2 | MUL R0, R1, R2 |
| DIV | Divide | DIV Rd, Rs1, Rs2 | DIV R0, R1, R2 |
| MOD | Modulo | MOD Rd, Rs1, Rs2 | MOD R0, R1, R2 |

## Logical Instructions

| Instruction | Description | Format | Example |
|-------------|-------------|--------|---------|
| AND | Bitwise AND | AND Rd, Rs1, Rs2 | AND R0, R1, R2 |
| OR | Bitwise OR | OR Rd, Rs1, Rs2 | OR R0, R1, R2 |
| XOR | Bitwise XOR | XOR Rd, Rs1, Rs2 | XOR R0, R1, R2 |
| NOT | Bitwise NOT | NOT Rd, Rs | NOT R0, R1 |
| SHL | Shift Left | SHL Rd, Rs, count | SHL R0, R1, 2 |
| SHR | Shift Right | SHR Rd, Rs, count | SHR R0, R1, 2 |

## Floating-Point Instructions

| Instruction | Description | Format | Example |
|-------------|-------------|--------|---------|
| FADD | Float Add | FADD Fd, Fs1, Fs2 | FADD F0, F1, F2 |
| FSUB | Float Subtract | FSUB Fd, Fs1, Fs2 | FSUB F0, F1, F2 |
| FMUL | Float Multiply | FMUL Fd, Fs1, Fs2 | FMUL F0, F1, F2 |
| FDIV | Float Divide | FDIV Fd, Fs1, Fs2 | FDIV F0, F1, F2 |
| FSQRT | Float Square Root | FSQRT Fd, Fs | FSQRT F0, F1 |
| FMA | Fused Multiply-Add | FMA Fd, Fs1, Fs2, Fs3 | FMA F0, F1, F2, F3 |

## Vector Instructions

| Instruction | Description | Format | Example |
|-------------|-------------|--------|---------|
| VADD | Vector Add | VADD Vd, Vs1, Vs2 | VADD V0, V1, V2 |
| VSUB | Vector Subtract | VSUB Vd, Vs1, Vs2 | VSUB V0, V1, V2 |
| VMUL | Vector Multiply | VMUL Vd, Vs1, Vs2 | VMUL V0, V1, V2 |
| VDOT | Vector Dot Product | VDOT Fd, Vs1, Vs2 | VDOT F0, V1, V2 |
| VSUM | Vector Sum | VSUM Fd, Vs | VSUM F0, V1 |
| VMAX | Vector Maximum | VMAX Vd, Vs1, Vs2 | VMAX V0, V1, V2 |
| VMIN | Vector Minimum | VMIN Vd, Vs1, Vs2 | VMIN V0, V1, V2 |

## Memory Instructions

| Instruction | Description | Format | Example |
|-------------|-------------|--------|---------|
| LDR | Load Register | LDR Rd, [Rs, offset] | LDR R0, [R1, 4] |
| STR | Store Register | STR Rs, [Rd, offset] | STR R0, [R1, 4] |
| LDI | Load Immediate | LDI Rd, imm | LDI R0, 42 |
| PREFETCH | Prefetch | PREFETCH [Rs, offset] | PREFETCH [R1, 64] |

## Control Flow Instructions

| Instruction | Description | Format | Example |
|-------------|-------------|--------|---------|
| JMP | Jump | JMP label | JMP loop |
| JZ | Jump if Zero | JZ label | JZ done |
| JNZ | Jump if Not Zero | JNZ label | JNZ loop |
| JL | Jump if Less | JL label | JL loop |
| JG | Jump if Greater | JG label | JG done |
| CALL | Call Function | CALL label | CALL function |
| RET | Return | RET | RET |

## AI/ML Instructions

| Instruction | Description | Format | Example |
|-------------|-------------|--------|---------|
| AI_CONV | Convolution | AI_CONV Vd, Vs, weights | AI_CONV V0, V1, W0 |
| AI_FC | Fully Connected | AI_FC Vd, Vs, weights | AI_FC V0, V1, W0 |
| AI_RELU | ReLU Activation | AI_RELU Vd, Vs | AI_RELU V0, V1 |
| AI_POOL | Pooling | AI_POOL Vd, Vs, type | AI_POOL V0, V1, MAX |
| AI_BN | Batch Normalization | AI_BN Vd, Vs, params | AI_BN V0, V1, P0 |

## System Instructions

| Instruction | Description | Format | Example |
|-------------|-------------|--------|---------|
| SYSCALL | System Call | SYSCALL num | SYSCALL 1 |
| HALT | Halt | HALT | HALT |
| NOP | No Operation | NOP | NOP |
| BREAK | Breakpoint | BREAK | BREAK |
''',
                prerequisites=[],
                learning_objectives=[
                    'Understand complete instruction set',
                    'Learn instruction formats and encodings',
                    'Use instruction reference effectively'
                ],
                estimated_time=0,
                tags=['reference', 'instructions', 'complete']
            )
        }
    
    def _initialize_interactive_examples(self):
        """Initialize interactive examples"""
        self.interactive_examples = {
            'hello_world': InteractiveExample(
                id='hello_world',
                title='Hello World',
                description='Write your first AlphaAHB V5 program',
                code_template='''# Hello World Program
# Complete the program to print "Hello, World!"

.section .text
.global _start

_start:
    # TODO: Load address of message into R0
    # TODO: Load message length into R1
    # TODO: Load file descriptor (stdout = 1) into R2
    # TODO: Make write system call (syscall 1)
    # TODO: Make exit system call (syscall 60)

.section .data
message:
    .ascii "Hello, World!\\n"
''',
                expected_output='Hello, World!\n',
                hints=[
                    'Use LDI to load immediate values',
                    'Use SYSCALL to make system calls',
                    'System call 1 is write, 60 is exit',
                    'R0, R1, R2 are used for system call parameters'
                ],
                solution='''# Hello World Program - Solution

.section .text
.global _start

_start:
    LDI R0, message    # Load address of message
    LDI R1, 13         # Message length
    LDI R2, 1          # File descriptor (stdout)
    SYSCALL 1          # Write system call
    LDI R0, 0          # Exit code
    SYSCALL 60         # Exit system call

.section .data
message:
    .ascii "Hello, World!\\n"
'''
            ),
            
            'array_sum': InteractiveExample(
                id='array_sum',
                title='Array Sum',
                description='Calculate the sum of an array using vector operations',
                code_template='''# Array Sum Program
# Calculate the sum of an array of 16 integers using vector operations

.section .text
.global _start

_start:
    # TODO: Load address of array into R0
    # TODO: Load vector from memory
    # TODO: Calculate sum using vector instruction
    # TODO: Store result
    # TODO: Exit program

.section .data
array:
    .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
result:
    .word 0
''',
                expected_output='136',  # Sum of 1 to 16
                hints=[
                    'Use VLOAD to load vector from memory',
                    'Use VSUM to calculate sum of vector elements',
                    'Use FSTORE to store floating-point result'
                ],
                solution='''# Array Sum Program - Solution

.section .text
.global _start

_start:
    LDI R0, array      # Load address of array
    VLOAD V1, [R0]     # Load 16 integers into vector
    VSUM F0, V1        # Calculate sum of vector elements
    FSTORE F0, result  # Store result
    LDI R0, 0          # Exit code
    SYSCALL 60         # Exit system call

.section .data
array:
    .word 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
result:
    .word 0
'''
            )
        }
    
    def _initialize_learning_paths(self):
        """Initialize learning paths"""
        self.learning_paths = {
            'beginner': [
                'getting_started',
                'basic_instructions',
                'memory_operations',
                'control_flow'
            ],
            'intermediate': [
                'vector_processing',
                'floating_point',
                'function_calls',
                'interrupts'
            ],
            'advanced': [
                'ai_ml_programming',
                'optimization_techniques',
                'real_time_systems',
                'security_programming'
            ]
        }
    
    def _setup_web_server(self):
        """Setup web server for interactive documentation"""
        self.server_thread = None
        self.server = None
    
    def start_server(self):
        """Start the interactive documentation server"""
        if self.server_thread and self.server_thread.is_alive():
            print("Server is already running")
            return
        
        def run_server():
            handler = self._create_request_handler()
            with socketserver.TCPServer(("", self.port), handler) as httpd:
                self.server = httpd
                print(f"Interactive documentation server running at http://localhost:{self.port}")
                httpd.serve_forever()
        
        self.server_thread = threading.Thread(target=run_server, daemon=True)
        self.server_thread.start()
        
        # Open browser
        time.sleep(1)
        webbrowser.open(f'http://localhost:{self.port}')
    
    def stop_server(self):
        """Stop the interactive documentation server"""
        if self.server:
            self.server.shutdown()
            self.server = None
        print("Server stopped")
    
    def _create_request_handler(self):
        """Create HTTP request handler"""
        class InteractiveDocsHandler(http.server.SimpleHTTPRequestHandler):
            def __init__(self, *args, **kwargs):
                self.docs = self
                super().__init__(*args, **kwargs)
            
            def do_GET(self):
                if self.path == '/' or self.path == '/index.html':
                    self._serve_index()
                elif self.path.startswith('/tutorial/'):
                    self._serve_tutorial()
                elif self.path.startswith('/example/'):
                    self._serve_example()
                elif self.path.startswith('/api/'):
                    self._serve_api()
                else:
                    super().do_GET()
            
            def _serve_index(self):
                """Serve main index page"""
                html = self._generate_index_html()
                self._send_response(html, 'text/html')
            
            def _serve_tutorial(self):
                """Serve tutorial page"""
                tutorial_id = self.path.split('/')[-1]
                html = self._generate_tutorial_html(tutorial_id)
                self._send_response(html, 'text/html')
            
            def _serve_example(self):
                """Serve interactive example page"""
                example_id = self.path.split('/')[-1]
                html = self._generate_example_html(example_id)
                self._send_response(html, 'text/html')
            
            def _serve_api(self):
                """Serve API endpoints"""
                if self.path == '/api/content':
                    self._serve_content_api()
                elif self.path == '/api/examples':
                    self._serve_examples_api()
                else:
                    self._send_error(404, "Not Found")
            
            def _serve_content_api(self):
                """Serve content API"""
                content_data = {
                    'tutorials': {k: asdict(v) for k, v in self.content['tutorials'].items()},
                    'reference': {k: asdict(v) for k, v in self.content['reference'].items()}
                }
                self._send_json_response(content_data)
            
            def _serve_examples_api(self):
                """Serve examples API"""
                examples_data = {k: asdict(v) for k, v in self.interactive_examples.items()}
                self._send_json_response(examples_data)
            
            def _send_response(self, content, content_type):
                """Send HTTP response"""
                self.send_response(200)
                self.send_header('Content-type', content_type)
                self.send_header('Content-length', str(len(content)))
                self.end_headers()
                self.wfile.write(content.encode())
            
            def _send_json_response(self, data):
                """Send JSON response"""
                json_data = json.dumps(data, indent=2)
                self._send_response(json_data, 'application/json')
            
            def _send_error(self, code, message):
                """Send error response"""
                self.send_response(code)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write(message.encode())
            
            def _generate_index_html(self):
                """Generate main index HTML"""
                return f'''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AlphaAHB V5 Interactive Documentation</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }}
        .container {{ max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
        h1 {{ color: #2c3e50; text-align: center; margin-bottom: 30px; }}
        .section {{ margin-bottom: 30px; }}
        .section h2 {{ color: #34495e; border-bottom: 2px solid #3498db; padding-bottom: 10px; }}
        .tutorial-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; }}
        .tutorial-card {{ background: #ecf0f1; padding: 20px; border-radius: 6px; border-left: 4px solid #3498db; }}
        .tutorial-card h3 {{ margin-top: 0; color: #2c3e50; }}
        .tutorial-card p {{ color: #7f8c8d; }}
        .difficulty {{ display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }}
        .beginner {{ background: #2ecc71; color: white; }}
        .intermediate {{ background: #f39c12; color: white; }}
        .advanced {{ background: #e74c3c; color: white; }}
        .expert {{ background: #8e44ad; color: white; }}
        .btn {{ display: inline-block; padding: 10px 20px; background: #3498db; color: white; text-decoration: none; border-radius: 4px; margin-top: 10px; }}
        .btn:hover {{ background: #2980b9; }}
        .interactive-examples {{ margin-top: 20px; }}
        .example-card {{ background: #e8f5e8; padding: 15px; border-radius: 6px; margin-bottom: 10px; }}
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 AlphaAHB V5 Interactive Documentation</h1>
        <p style="text-align: center; color: #7f8c8d; font-size: 18px;">
            Learn the AlphaAHB V5 Instruction Set Architecture with interactive tutorials and examples
        </p>
        
        <div class="section">
            <h2>📚 Tutorials</h2>
            <div class="tutorial-grid">
                <div class="tutorial-card">
                    <h3>Getting Started</h3>
                    <p>Introduction to AlphaAHB V5 ISA and basic concepts</p>
                    <span class="difficulty beginner">Beginner</span>
                    <br><a href="/tutorial/getting_started" class="btn">Start Tutorial</a>
                </div>
                <div class="tutorial-card">
                    <h3>Basic Instructions</h3>
                    <p>Learn about basic AlphaAHB V5 instructions</p>
                    <span class="difficulty beginner">Beginner</span>
                    <br><a href="/tutorial/basic_instructions" class="btn">Start Tutorial</a>
                </div>
                <div class="tutorial-card">
                    <h3>Vector Processing</h3>
                    <p>Learn about AlphaAHB V5 vector processing capabilities</p>
                    <span class="difficulty intermediate">Intermediate</span>
                    <br><a href="/tutorial/vector_processing" class="btn">Start Tutorial</a>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2>🎮 Interactive Examples</h2>
            <div class="interactive-examples">
                <div class="example-card">
                    <h3>Hello World</h3>
                    <p>Write your first AlphaAHB V5 program</p>
                    <a href="/example/hello_world" class="btn">Try Example</a>
                </div>
                <div class="example-card">
                    <h3>Array Sum</h3>
                    <p>Calculate the sum of an array using vector operations</p>
                    <a href="/example/array_sum" class="btn">Try Example</a>
                </div>
            </div>
        </div>
        
        <div class="section">
            <h2>📖 Reference</h2>
            <div class="tutorial-card">
                <h3>Instruction Set Reference</h3>
                <p>Complete AlphaAHB V5 instruction set reference</p>
                <a href="/reference/instruction_set" class="btn">View Reference</a>
            </div>
        </div>
        
        <div style="text-align: center; margin-top: 40px; color: #7f8c8d;">
            <p>Developed and Maintained by <strong>GLCTC Corp.</strong></p>
        </div>
    </div>
</body>
</html>
'''
            
            def _generate_tutorial_html(self, tutorial_id):
                """Generate tutorial HTML"""
                if tutorial_id in self.content['tutorials']:
                    tutorial = self.content['tutorials'][tutorial_id]
                    content_html = markdown.markdown(tutorial.content)
                    
                    return f'''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{tutorial.title} - AlphaAHB V5 Documentation</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }}
        .container {{ max-width: 800px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
        h1 {{ color: #2c3e50; }}
        .difficulty {{ display: inline-block; padding: 6px 12px; border-radius: 4px; font-size: 14px; font-weight: bold; margin-bottom: 20px; }}
        .beginner {{ background: #2ecc71; color: white; }}
        .intermediate {{ background: #f39c12; color: white; }}
        .advanced {{ background: #e74c3c; color: white; }}
        .expert {{ background: #8e44ad; color: white; }}
        .back-btn {{ display: inline-block; padding: 8px 16px; background: #95a5a6; color: white; text-decoration: none; border-radius: 4px; margin-bottom: 20px; }}
        .back-btn:hover {{ background: #7f8c8d; }}
        pre {{ background: #2c3e50; color: #ecf0f1; padding: 15px; border-radius: 4px; overflow-x: auto; }}
        code {{ background: #ecf0f1; padding: 2px 4px; border-radius: 2px; }}
        .objectives {{ background: #e8f5e8; padding: 15px; border-radius: 4px; margin: 20px 0; }}
        .objectives h3 {{ margin-top: 0; color: #27ae60; }}
        .objectives ul {{ margin-bottom: 0; }}
    </style>
</head>
<body>
    <div class="container">
        <a href="/" class="back-btn">← Back to Home</a>
        <h1>{tutorial.title}</h1>
        <span class="difficulty {tutorial.difficulty.value}">{tutorial.difficulty.value.title()}</span>
        <p style="color: #7f8c8d; font-size: 18px;">{tutorial.description}</p>
        
        <div class="objectives">
            <h3>Learning Objectives</h3>
            <ul>
                {''.join([f'<li>{obj}</li>' for obj in tutorial.learning_objectives])}
            </ul>
        </div>
        
        <div style="margin: 30px 0;">
            {content_html}
        </div>
        
        <div style="text-align: center; margin-top: 40px;">
            <a href="/" class="back-btn">← Back to Home</a>
        </div>
    </div>
</body>
</html>
'''
                else:
                    return self._send_error(404, "Tutorial not found")
            
            def _generate_example_html(self, example_id):
                """Generate interactive example HTML"""
                if example_id in self.interactive_examples:
                    example = self.interactive_examples[example_id]
                    
                    return f'''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{example.title} - AlphaAHB V5 Interactive Example</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }}
        .container {{ max-width: 1000px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
        h1 {{ color: #2c3e50; }}
        .back-btn {{ display: inline-block; padding: 8px 16px; background: #95a5a6; color: white; text-decoration: none; border-radius: 4px; margin-bottom: 20px; }}
        .back-btn:hover {{ background: #7f8c8d; }}
        .editor-container {{ display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 20px 0; }}
        .editor {{ background: #2c3e50; color: #ecf0f1; padding: 15px; border-radius: 4px; }}
        .editor textarea {{ width: 100%; height: 400px; background: #2c3e50; color: #ecf0f1; border: none; font-family: 'Courier New', monospace; font-size: 14px; resize: vertical; }}
        .controls {{ margin: 20px 0; }}
        .btn {{ display: inline-block; padding: 10px 20px; background: #3498db; color: white; text-decoration: none; border-radius: 4px; margin-right: 10px; cursor: pointer; border: none; }}
        .btn:hover {{ background: #2980b9; }}
        .btn.success {{ background: #27ae60; }}
        .btn.warning {{ background: #f39c12; }}
        .hints {{ background: #fff3cd; padding: 15px; border-radius: 4px; margin: 20px 0; }}
        .hints h3 {{ margin-top: 0; color: #856404; }}
        .hints ul {{ margin-bottom: 0; }}
        .output {{ background: #d4edda; padding: 15px; border-radius: 4px; margin: 20px 0; }}
        .output h3 {{ margin-top: 0; color: #155724; }}
        pre {{ margin: 0; }}
    </style>
</head>
<body>
    <div class="container">
        <a href="/" class="back-btn">← Back to Home</a>
        <h1>{example.title}</h1>
        <p style="color: #7f8c8d; font-size: 18px;">{example.description}</p>
        
        <div class="editor-container">
            <div class="editor">
                <h3>Your Code</h3>
                <textarea id="codeEditor" placeholder="Write your AlphaAHB V5 assembly code here...">{example.code_template}</textarea>
            </div>
            <div class="editor">
                <h3>Expected Output</h3>
                <pre>{example.expected_output}</pre>
            </div>
        </div>
        
        <div class="controls">
            <button class="btn" onclick="runCode()">▶ Run Code</button>
            <button class="btn warning" onclick="showHints()">💡 Show Hints</button>
            <button class="btn success" onclick="showSolution()">✅ Show Solution</button>
            <button class="btn" onclick="resetCode()">🔄 Reset</button>
        </div>
        
        <div class="hints" id="hints" style="display: none;">
            <h3>💡 Hints</h3>
            <ul>
                {''.join([f'<li>{hint}</li>' for hint in example.hints])}
            </ul>
        </div>
        
        <div class="output" id="output" style="display: none;">
            <h3>Output</h3>
            <pre id="outputText"></pre>
        </div>
    </div>
    
    <script>
        function runCode() {{
            const code = document.getElementById('codeEditor').value;
            // Simulate code execution
            document.getElementById('output').style.display = 'block';
            document.getElementById('outputText').textContent = 'Code executed successfully!\\n\\nNote: This is a simulation. In a real implementation, this would execute the AlphaAHB V5 code.';
        }}
        
        function showHints() {{
            const hints = document.getElementById('hints');
            hints.style.display = hints.style.display === 'none' ? 'block' : 'none';
        }}
        
        function showSolution() {{
            document.getElementById('codeEditor').value = `{example.solution}`;
        }}
        
        function resetCode() {{
            document.getElementById('codeEditor').value = `{example.code_template}`;
            document.getElementById('output').style.display = 'none';
            document.getElementById('hints').style.display = 'none';
        }}
    </script>
</body>
</html>
'''
                else:
                    return self._send_error(404, "Example not found")
        
        return InteractiveDocsHandler
    
    def generate_static_docs(self, output_dir: str = "docs"):
        """Generate static documentation files"""
        output_path = Path(output_dir)
        output_path.mkdir(exist_ok=True)
        
        # Generate HTML files
        for content_type, contents in self.content.items():
            for content_id, content in contents.items():
                html = self._generate_content_html(content)
                file_path = output_path / f"{content_id}.html"
                with open(file_path, 'w') as f:
                    f.write(html)
        
        # Generate index
        index_html = self._generate_index_html()
        with open(output_path / "index.html", 'w') as f:
            f.write(index_html)
        
        print(f"Static documentation generated in {output_dir}/")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='AlphaAHB V5 Interactive Documentation')
    parser.add_argument('-p', '--port', type=int, default=8080, help='Server port')
    parser.add_argument('-s', '--static', help='Generate static documentation')
    parser.add_argument('--start', action='store_true', help='Start interactive server')
    
    args = parser.parse_args()
    
    docs = AlphaAHBInteractiveDocs(port=args.port)
    
    if args.static:
        docs.generate_static_docs(args.static)
    elif args.start:
        docs.start_server()
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            docs.stop_server()
    else:
        print("Use --start to start interactive server or --static <dir> to generate static docs")

if __name__ == '__main__':
    main()
