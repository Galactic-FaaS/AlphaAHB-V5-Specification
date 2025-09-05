# AlphaAHB V5 ISA System Programming Interface

## Overview

This document defines the complete system programming interface for the AlphaAHB V5 ISA, including privilege levels, exception handling, interrupt system, virtual memory management, and system control operations.

## Table of Contents

1. [Privilege Levels](#1-privilege-levels)
2. [Exception Handling](#2-exception-handling)
3. [Interrupt System](#3-interrupt-system)
4. [Virtual Memory Management](#4-virtual-memory-management)
5. [System Control Operations](#5-system-control-operations)
6. [Debug Interface](#6-debug-interface)
7. [Performance Monitoring](#7-performance-monitoring)
8. [Power Management](#8-power-management)

---

## 1. Privilege Levels

### 1.1 Privilege Level Architecture

The AlphaAHB V5 ISA implements a **4-level privilege hierarchy**:

| Level | Name | Description | Access Rights |
|-------|------|-------------|---------------|
| 0 | User | User applications | Limited system access |
| 1 | Supervisor | Operating system | Full system access |
| 2 | Hypervisor | Virtualization | Virtual machine control |
| 3 | Machine | Firmware/BIOS | Complete hardware control |

### 1.2 Privilege Level Transitions

| Transition | Method | Description |
|------------|--------|-------------|
| User → Supervisor | System Call | `SYSCALL` instruction |
| Supervisor → Hypervisor | Hypercall | `HYPERCALL` instruction |
| Hypervisor → Machine | Machine Call | `MCALL` instruction |
| Any → User | Return | `RET` instruction |

### 1.3 Privilege Level Instructions

| Instruction | Syntax | Description | Privilege Required |
|-------------|--------|-------------|-------------------|
| SYSCALL | `SYSCALL #imm` | System call | User |
| HYPERCALL | `HYPERCALL #imm` | Hypervisor call | Supervisor |
| MCALL | `MCALL #imm` | Machine call | Hypervisor |
| RET | `RET` | Return to lower privilege | Any |

---

## 2. Exception Handling

### 2.1 Exception Types

| Exception | Code | Description | Priority |
|-----------|------|-------------|----------|
| Instruction Address Misaligned | 0 | Instruction address not aligned | 1 |
| Instruction Access Fault | 1 | Instruction access violation | 2 |
| Illegal Instruction | 2 | Invalid instruction | 3 |
| Breakpoint | 3 | Breakpoint hit | 4 |
| Load Address Misaligned | 4 | Load address not aligned | 5 |
| Load Access Fault | 5 | Load access violation | 6 |
| Store Address Misaligned | 6 | Store address not aligned | 7 |
| Store Access Fault | 7 | Store access violation | 8 |
| User Environment Call | 8 | System call from user | 9 |
| Supervisor Environment Call | 9 | Hypervisor call from supervisor | 10 |
| Hypervisor Environment Call | 10 | Machine call from hypervisor | 11 |
| Machine Environment Call | 11 | Machine call from machine | 12 |
| Instruction Page Fault | 12 | Instruction page fault | 13 |
| Load Page Fault | 13 | Load page fault | 14 |
| Store Page Fault | 14 | Store page fault | 15 |
| Floating-Point Exception | 15 | Floating-point error | 16 |
| Vector Exception | 16 | Vector operation error | 17 |
| AI/ML Exception | 17 | AI/ML operation error | 18 |
| MIMD Exception | 18 | MIMD operation error | 19 |
| Security Exception | 19 | Security violation | 20 |
| Reserved | 20-31 | Reserved for future use | - |

### 2.2 Exception Vector Table

| Vector | Address | Description |
|--------|---------|-------------|
| 0 | 0x00000000 | Reset vector |
| 1 | 0x00000008 | Instruction address misaligned |
| 2 | 0x00000010 | Instruction access fault |
| 3 | 0x00000018 | Illegal instruction |
| 4 | 0x00000020 | Breakpoint |
| 5 | 0x00000028 | Load address misaligned |
| 6 | 0x00000030 | Load access fault |
| 7 | 0x00000038 | Store address misaligned |
| 8 | 0x00000040 | Store access fault |
| 9 | 0x00000048 | User environment call |
| 10 | 0x00000050 | Supervisor environment call |
| 11 | 0x00000058 | Hypervisor environment call |
| 12 | 0x00000060 | Machine environment call |
| 13 | 0x00000068 | Instruction page fault |
| 14 | 0x00000070 | Load page fault |
| 15 | 0x00000078 | Store page fault |
| 16 | 0x00000080 | Floating-point exception |
| 17 | 0x00000088 | Vector exception |
| 18 | 0x00000090 | AI/ML exception |
| 19 | 0x00000098 | MIMD exception |
| 20 | 0x000000A0 | Security exception |

### 2.3 Exception Context

When an exception occurs, the processor saves the following context:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Exception Context                           │
├─────────────────────────────────────────────────────────────────┤
│ PC (Program Counter) - 64 bits                                │
│ FLAGS (Status Flags) - 64 bits                                │
│ CORE_ID (Core ID) - 32 bits                                   │
│ THREAD_ID (Thread ID) - 32 bits                               │
│ PRIVILEGE (Privilege Level) - 8 bits                          │
│ EXCEPTION_CODE (Exception Code) - 8 bits                      │
│ EXCEPTION_ADDRESS (Exception Address) - 64 bits               │
│ EXCEPTION_VALUE (Exception Value) - 64 bits                   │
│ RESERVED (Reserved) - 64 bits                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 2.4 Exception Handling Instructions

| Instruction | Syntax | Description |
|-------------|--------|-------------|
| TRAP | `TRAP #imm` | Generate exception |
| BREAK | `BREAK #imm` | Generate breakpoint |
| RFE | `RFE` | Return from exception |
| RFI | `RFI` | Return from interrupt |

---

## 3. Interrupt System

### 3.1 Interrupt Types

| Interrupt | Code | Description | Priority |
|-----------|------|-------------|----------|
| Timer Interrupt | 0 | Timer expiration | 1 |
| External Interrupt | 1 | External device interrupt | 2 |
| Software Interrupt | 2 | Software-generated interrupt | 3 |
| Performance Interrupt | 3 | Performance counter overflow | 4 |
| Debug Interrupt | 4 | Debug event | 5 |
| Power Management Interrupt | 5 | Power management event | 6 |
| Security Interrupt | 6 | Security event | 7 |
| Reserved | 7-15 | Reserved for future use | - |

### 3.2 Interrupt Controller

The AlphaAHB V5 ISA includes a **Programmable Interrupt Controller (PIC)**:

| Register | Address | Description |
|----------|---------|-------------|
| PIC_CTRL | 0x10000000 | Interrupt controller control |
| PIC_STATUS | 0x10000008 | Interrupt controller status |
| PIC_MASK | 0x10000010 | Interrupt mask register |
| PIC_PRIORITY | 0x10000018 | Interrupt priority register |
| PIC_VECTOR | 0x10000020 | Interrupt vector register |

### 3.3 Interrupt Handling

| Instruction | Syntax | Description |
|-------------|--------|-------------|
| ENABLE_IRQ | `ENABLE_IRQ #imm` | Enable interrupt |
| DISABLE_IRQ | `DISABLE_IRQ #imm` | Disable interrupt |
| SET_IRQ_MASK | `SET_IRQ_MASK #imm` | Set interrupt mask |
| CLEAR_IRQ_MASK | `CLEAR_IRQ_MASK #imm` | Clear interrupt mask |
| SET_IRQ_PRIORITY | `SET_IRQ_PRIORITY #imm, #priority` | Set interrupt priority |

---

## 4. Virtual Memory Management

### 4.1 Virtual Memory Architecture

The AlphaAHB V5 ISA implements a **64-bit virtual address space** with **48-bit physical address space**:

| Address Space | Size | Description |
|---------------|------|-------------|
| Virtual | 64-bit | 2^64 bytes (16 exabytes) |
| Physical | 48-bit | 2^48 bytes (256 terabytes) |
| Page Size | 4KB | Standard page size |
| Large Page Size | 2MB | Large page size |
| Huge Page Size | 1GB | Huge page size |

### 4.2 Page Table Formats

#### 4.2.1 Level 4 Page Table Entry (PTE)

```
┌─────────────────────────────────────────────────────────────────┐
│                    64-bit Page Table Entry                    │
├─────────────────────────────────────────────────────────────────┤
│ 63 │ 62-48 │ 47-12 │ 11-8 │ 7-6 │ 5-4 │ 3-2 │ 1 │ 0 │
│ V  │ RES   │ PPN   │ RES  │ A   │ D   │ U   │ W │ R │
│ 1  │ 15    │ 36    │ 4    │ 2   │ 2   │ 2   │ 1 │ 1 │
└─────────────────────────────────────────────────────────────────┘
```

| Bit | Name | Description |
|-----|------|-------------|
| 0 | R | Read permission |
| 1 | W | Write permission |
| 3-2 | U | User access level |
| 5-4 | D | Dirty bit |
| 7-6 | A | Accessed bit |
| 47-12 | PPN | Physical page number |
| 63 | V | Valid bit |

#### 4.2.2 Translation Lookaside Buffer (TLB)

| TLB Level | Entries | Associativity | Latency |
|-----------|---------|---------------|---------|
| L1 TLB | 64 | 4-way | 1 cycle |
| L2 TLB | 512 | 8-way | 3 cycles |
| L3 TLB | 4096 | 16-way | 8 cycles |

### 4.3 Virtual Memory Instructions

| Instruction | Syntax | Description |
|-------------|--------|-------------|
| TLB_FLUSH | `TLB_FLUSH` | Flush entire TLB |
| TLB_FLUSH_ASID | `TLB_FLUSH_ASID #imm` | Flush TLB for ASID |
| TLB_FLUSH_PAGE | `TLB_FLUSH_PAGE Rs1` | Flush TLB for page |
| TLB_FLUSH_ALL | `TLB_FLUSH_ALL` | Flush all TLBs |
| PAGE_FAULT | `PAGE_FAULT Rs1` | Generate page fault |

---

## 5. System Control Operations

### 5.1 Cache Control

| Instruction | Syntax | Description |
|-------------|--------|-------------|
| CACHE_FLUSH | `CACHE_FLUSH` | Flush entire cache |
| CACHE_FLUSH_L1 | `CACHE_FLUSH_L1` | Flush L1 cache |
| CACHE_FLUSH_L2 | `CACHE_FLUSH_L2` | Flush L2 cache |
| CACHE_FLUSH_L3 | `CACHE_FLUSH_L3` | Flush L3 cache |
| CACHE_INVALIDATE | `CACHE_INVALIDATE` | Invalidate entire cache |
| CACHE_PREFETCH | `CACHE_PREFETCH Rs1` | Prefetch data |

### 5.2 Memory Management

| Instruction | Syntax | Description |
|-------------|--------|-------------|
| MEMORY_BARRIER | `MEMORY_BARRIER` | Memory barrier |
| MEMORY_FENCE | `MEMORY_FENCE` | Memory fence |
| MEMORY_SYNC | `MEMORY_SYNC` | Memory synchronization |
| MEMORY_FLUSH | `MEMORY_FLUSH` | Memory flush |

### 5.3 Core Management

| Instruction | Syntax | Description |
|-------------|--------|-------------|
| CORE_HALT | `CORE_HALT` | Halt current core |
| CORE_RESUME | `CORE_RESUME #imm` | Resume core |
| CORE_RESET | `CORE_RESET #imm` | Reset core |
| CORE_SLEEP | `CORE_SLEEP` | Put core to sleep |
| CORE_WAKE | `CORE_WAKE #imm` | Wake up core |

---

## 6. Debug Interface

### 6.1 Debug Registers

| Register | Address | Description |
|----------|---------|-------------|
| DEBUG_CTRL | 0x20000000 | Debug control register |
| DEBUG_STATUS | 0x20000008 | Debug status register |
| DEBUG_BREAKPOINT | 0x20000010 | Breakpoint register |
| DEBUG_WATCHPOINT | 0x20000018 | Watchpoint register |
| DEBUG_TRACE | 0x20000020 | Trace register |

### 6.2 Debug Instructions

| Instruction | Syntax | Description |
|-------------|--------|-------------|
| BREAKPOINT | `BREAKPOINT #imm` | Set breakpoint |
| WATCHPOINT | `WATCHPOINT Rs1` | Set watchpoint |
| TRACE_START | `TRACE_START` | Start tracing |
| TRACE_STOP | `TRACE_STOP` | Stop tracing |
| DEBUG_STEP | `DEBUG_STEP` | Single step |

### 6.3 Debug Features

| Feature | Description |
|---------|-------------|
| Hardware Breakpoints | 8 breakpoints |
| Hardware Watchpoints | 8 watchpoints |
| Instruction Tracing | Complete instruction trace |
| Data Tracing | Complete data trace |
| Performance Profiling | Performance counter support |

---

## 7. Performance Monitoring

### 7.1 Performance Counters

| Counter | Address | Description |
|---------|---------|-------------|
| PERF_CTRL | 0x30000000 | Performance control |
| PERF_COUNT0 | 0x30000008 | Performance counter 0 |
| PERF_COUNT1 | 0x30000010 | Performance counter 1 |
| PERF_COUNT2 | 0x30000018 | Performance counter 2 |
| PERF_COUNT3 | 0x30000020 | Performance counter 3 |
| PERF_COUNT4 | 0x30000028 | Performance counter 4 |
| PERF_COUNT5 | 0x30000030 | Performance counter 5 |
| PERF_COUNT6 | 0x30000038 | Performance counter 6 |
| PERF_COUNT7 | 0x30000040 | Performance counter 7 |

### 7.2 Performance Events

| Event | Code | Description |
|-------|------|-------------|
| INSTRUCTIONS | 0x00 | Instructions executed |
| CYCLES | 0x01 | Clock cycles |
| CACHE_MISSES | 0x02 | Cache misses |
| TLB_MISSES | 0x03 | TLB misses |
| BRANCH_MISPREDICTS | 0x04 | Branch mispredictions |
| FLOATING_POINT_OPS | 0x05 | Floating-point operations |
| VECTOR_OPS | 0x06 | Vector operations |
| AI_ML_OPS | 0x07 | AI/ML operations |

### 7.3 Performance Instructions

| Instruction | Syntax | Description |
|-------------|--------|-------------|
| PERF_START | `PERF_START #imm` | Start performance counter |
| PERF_STOP | `PERF_STOP #imm` | Stop performance counter |
| PERF_READ | `PERF_READ Rd, #imm` | Read performance counter |
| PERF_RESET | `PERF_RESET #imm` | Reset performance counter |

---

## 8. Power Management

### 8.1 Power States

| State | Description | Power Consumption |
|-------|-------------|-------------------|
| ACTIVE | Full operation | 100% |
| IDLE | Reduced operation | 50% |
| SLEEP | Minimal operation | 10% |
| DEEP_SLEEP | Very minimal operation | 1% |
| OFF | No operation | 0% |

### 8.2 Power Management Instructions

| Instruction | Syntax | Description |
|-------------|--------|-------------|
| POWER_SAVE | `POWER_SAVE` | Enter power save mode |
| POWER_WAKE | `POWER_WAKE` | Wake from power save mode |
| POWER_OFF | `POWER_OFF` | Turn off power |
| POWER_ON | `POWER_ON` | Turn on power |
| FREQUENCY_SCALE | `FREQUENCY_SCALE #imm` | Scale frequency |

### 8.3 Power Management Registers

| Register | Address | Description |
|----------|---------|-------------|
| POWER_CTRL | 0x40000000 | Power control register |
| POWER_STATUS | 0x40000008 | Power status register |
| POWER_FREQ | 0x40000010 | Frequency control register |
| POWER_VOLTAGE | 0x40000018 | Voltage control register |

---

## 9. System Programming Examples

### 9.1 Exception Handler

```assembly
# Exception handler for illegal instruction
.text
.global illegal_instruction_handler

illegal_instruction_handler:
    # Save context
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    PUSH R7
    PUSH R8
    PUSH R9
    PUSH R10
    PUSH R11
    PUSH R12
    PUSH R13
    PUSH R14
    PUSH R15
    
    # Get exception information
    MOV R0, EXCEPTION_CODE
    MOV R1, EXCEPTION_ADDRESS
    MOV R2, EXCEPTION_VALUE
    
    # Handle exception
    CALL handle_illegal_instruction
    
    # Restore context
    POP R15
    POP R14
    POP R13
    POP R12
    POP R11
    POP R10
    POP R9
    POP R8
    POP R7
    POP R6
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    
    # Return from exception
    RFE
```

### 9.2 Interrupt Handler

```assembly
# Interrupt handler for timer interrupt
.text
.global timer_interrupt_handler

timer_interrupt_handler:
    # Save context
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    PUSH R7
    PUSH R8
    PUSH R9
    PUSH R10
    PUSH R11
    PUSH R12
    PUSH R13
    PUSH R14
    PUSH R15
    
    # Handle timer interrupt
    CALL handle_timer_interrupt
    
    # Restore context
    POP R15
    POP R14
    POP R13
    POP R12
    POP R11
    POP R10
    POP R9
    POP R8
    POP R7
    POP R6
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    
    # Return from interrupt
    RFI
```

### 9.3 System Call Handler

```assembly
# System call handler
.text
.global syscall_handler

syscall_handler:
    # Save context
    PUSH R0
    PUSH R1
    PUSH R2
    PUSH R3
    PUSH R4
    PUSH R5
    PUSH R6
    PUSH R7
    PUSH R8
    PUSH R9
    PUSH R10
    PUSH R11
    PUSH R12
    PUSH R13
    PUSH R14
    PUSH R15
    
    # Get system call number
    MOV R0, R10  # System call number
    MOV R1, R11  # Argument 1
    MOV R2, R12  # Argument 2
    MOV R3, R13  # Argument 3
    MOV R4, R14  # Argument 4
    MOV R5, R15  # Argument 5
    
    # Handle system call
    CALL handle_syscall
    
    # Set return value
    MOV R10, R0
    
    # Restore context
    POP R15
    POP R14
    POP R13
    POP R12
    POP R11
    POP R10
    POP R9
    POP R8
    POP R7
    POP R6
    POP R5
    POP R4
    POP R3
    POP R2
    POP R1
    POP R0
    
    # Return from system call
    RFE
```

---

## Conclusion

The AlphaAHB V5 ISA system programming interface provides comprehensive support for modern operating systems and hypervisors. The 4-level privilege hierarchy, extensive exception handling, advanced interrupt system, and complete virtual memory management enable sophisticated system software while maintaining security and performance.

Key features:
- **4-level privilege hierarchy** for secure system operation
- **Comprehensive exception handling** with 32 exception types
- **Advanced interrupt system** with programmable interrupt controller
- **Complete virtual memory management** with 64-bit virtual addressing
- **Extensive debug interface** with hardware breakpoints and tracing
- **Performance monitoring** with 8 performance counters
- **Power management** with 5 power states
