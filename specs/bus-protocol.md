# AlphaAHB V5 ISA Bus Protocol Specification

## Overview

This document defines the detailed bus protocol for AlphaAHB V5 ISA, including signal definitions, timing diagrams, and protocol state machines. This protocol supports the full instruction set architecture implementation.

## Signal Definitions

### Master Interface Signals

| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| HCLK | 1 | Input | System clock |
| HRESETn | 1 | Input | Active low reset |
| HADDR | 48 | Output | Address bus |
| HWDATA | 512 | Output | Write data bus |
| HRDATA | 512 | Input | Read data bus |
| HWRITE | 1 | Output | Write/read indicator |
| HSIZE | 3 | Output | Transfer size |
| HBURST | 3 | Output | Burst type |
| HPROT | 8 | Output | Protection signals |
| HTRANS | 2 | Output | Transfer type |
| HMASTER | 8 | Output | Master identification |
| HMASTLOCK | 1 | Output | Locked transfer |
| HREADY | 1 | Input | Transfer ready |
| HRESP | 2 | Input | Transfer response |

### Slave Interface Signals

| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| HSEL | 1 | Input | Slave select |
| HREADYOUT | 1 | Output | Slave ready output |
| HRESP | 2 | Output | Transfer response |
| HWDATA | 512 | Input | Write data bus |
| HRDATA | 512 | Output | Read data bus |

## Transfer Types

### HTRANS Encoding

```
HTRANS[1:0] | Type    | Description
------------|---------|----------------------------------------
00          | IDLE    | No transfer required
01          | BUSY    | Connected master is not ready
10          | NONSEQ  | Single or first in burst
11          | SEQ     | Remaining transfers in burst
```

### HSIZE Encoding

```
HSIZE[2:0] | Size    | Description
-----------|---------|----------------------------------------
000        | 8-bit   | Byte transfer
001        | 16-bit  | Half-word transfer
010        | 32-bit  | Word transfer
011        | 64-bit  | Double-word transfer
100        | 128-bit | Quad-word transfer
101        | 256-bit | Octa-word transfer
110        | 512-bit | Hexa-word transfer
111        | 1024-bit| Reserved
```

### HBURST Encoding

```
HBURST[2:0] | Type    | Description
------------|---------|----------------------------------------
000         | SINGLE  | Single transfer
001         | INCR    | Incrementing burst
010         | WRAP4   | 4-beat wrapping burst
011         | INCR4   | 4-beat incrementing burst
100         | WRAP8   | 8-beat wrapping burst
101         | INCR8   | 8-beat incrementing burst
110         | WRAP16  | 16-beat wrapping burst
111         | INCR16  | 16-beat incrementing burst
```

## Timing Diagrams

### Basic Read Transfer

```
Clock:     __/‾‾\__/‾‾\__/‾‾\__/‾‾\__/‾‾\__/‾‾\__
HADDR:     ----< A1 >----< A2 >----< A3 >----
HTRANS:    ----<NONSEQ>--< SEQ >--< SEQ >----
HWRITE:    ----< 0  >----< 0  >----< 0  >----
HSIZE:     ----< 512>----< 512>----< 512>----
HREADY:    ----< 1  >----< 1  >----< 1  >----
HRDATA:    ----< D1 >----< D2 >----< D3 >----
HRESP:     ----<OKAY>----<OKAY>----<OKAY>----
```

### Basic Write Transfer

```
Clock:     __/‾‾\__/‾‾\__/‾‾\__/‾‾\__/‾‾\__/‾‾\__
HADDR:     ----< A1 >----< A2 >----< A3 >----
HTRANS:    ----<NONSEQ>--< SEQ >--< SEQ >----
HWRITE:    ----< 1  >----< 1  >----< 1  >----
HSIZE:     ----< 512>----< 512>----< 512>----
HWDATA:    ----< D1 >----< D2 >----< D3 >----
HREADY:    ----< 1  >----< 1  >----< 1  >----
HRESP:     ----<OKAY>----<OKAY>----<OKAY>----
```

## Protocol State Machine

### Master State Machine

```
    ┌─────────┐
    │  IDLE   │
    └────┬────┘
         │
         │ HTRANS = NONSEQ
         ▼
    ┌─────────┐
    │ NONSEQ  │
    └────┬────┘
         │
         │ HREADY = 1
         ▼
    ┌─────────┐
    │  SEQ    │
    └────┬────┘
         │
         │ HTRANS = IDLE
         ▼
    ┌─────────┐
    │  IDLE   │
    └─────────┘
```

### Slave State Machine

```
    ┌─────────┐
    │  IDLE   │
    └────┬────┘
         │
         │ HSEL = 1
         ▼
    ┌─────────┐
    │  BUSY   │
    └────┬────┘
         │
         │ Ready to respond
         ▼
    ┌─────────┐
    │  READY  │
    └────┬────┘
         │
         │ Transfer complete
         ▼
    ┌─────────┐
    │  IDLE   │
    └─────────┘
```

## Error Handling

### HRESP Encoding

```
HRESP[1:0] | Response | Description
-----------|----------|----------------------------------------
00         | OKAY     | Successful transfer
01         | ERROR    | Error response
10         | RETRY    | Retry response
11         | SPLIT    | Split response
```

### Error Conditions

1. **Address Error**: Invalid address range
2. **Size Error**: Unsupported transfer size
3. **Protection Error**: Access violation
4. **Timeout Error**: Slave not responding
5. **Data Error**: ECC/parity error

## Performance Optimizations

### Burst Transfers

Burst transfers improve bandwidth utilization by:
- Reducing address setup overhead
- Enabling data prefetching
- Supporting cache line fills
- Minimizing bus arbitration

### Split Transactions

Split transactions allow:
- Long-latency operations
- Non-blocking transfers
- Improved system throughput
- Better resource utilization

## Implementation Guidelines

### Clock Domain Crossing

- Use synchronizers for CDC signals
- Implement proper metastability handling
- Follow CDC verification guidelines
- Use appropriate CDC protocols

### Reset Strategy

- Asynchronous reset assertion
- Synchronous reset deassertion
- Reset distribution network
- Reset isolation between domains

### Power Management

- Clock gating for idle masters/slaves
- Power gating for unused components
- Dynamic voltage and frequency scaling
- Wake-up sequence implementation
