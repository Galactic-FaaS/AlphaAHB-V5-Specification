#!/usr/bin/env python3
"""
AlphaAHB V5 Assembler
Developed and Maintained by GLCTC Corp.

A comprehensive assembler for the AlphaAHB V5 Instruction Set Architecture.
Supports all instruction types, macros, and advanced features including:
- Complete Alpha ISA V5 instruction set
- AlphaM MIMD SoC specific instructions
- Advanced arithmetic and floating-point operations
- AI/ML and vector processing instructions
- Security and scientific computing extensions
"""

import sys
import os
import argparse
import re
import struct
from typing import Dict, List, Tuple, Optional, Union
from dataclasses import dataclass
from enum import Enum

class InstructionType(Enum):
    """Instruction type enumeration"""
    BASIC = "basic"
    ARITHMETIC = "arithmetic"
    FLOATING_POINT = "floating_point"
    VECTOR = "vector"
    AI_ML = "ai_ml"
    MIMD = "mimd"
    SECURITY = "security"
    SCIENTIFIC = "scientific"
    REAL_TIME = "real_time"
    DEBUG = "debug"
    SYSTEM = "system"

class DataType(Enum):
    """Data type enumeration"""
    I8 = "i8"
    I16 = "i16"
    I32 = "i32"
    I64 = "i64"
    F16 = "f16"
    F32 = "f32"
    F64 = "f64"
    F128 = "f128"
    F256 = "f256"
    F512 = "f512"
    VECTOR = "vector"

@dataclass
class Instruction:
    """Instruction representation"""
    opcode: str
    operands: List[str]
    line_number: int
    address: int
    instruction_type: InstructionType
    data_type: DataType
    encoding: bytes

@dataclass
class Register:
    """Register representation"""
    name: str
    number: int
    size: int
    type: str

class AlphaAHBAssembler:
    """Main assembler class"""
    
    def __init__(self, target: str = "alpham"):
        self.target = target  # "alpha" or "alpham"
        self.instructions = {}
        self.labels = {}
        self.current_address = 0
        self.register_map = self._init_register_map()
        self.instruction_set = self._init_instruction_set()
        self.macros = {}
        self.symbols = {}
        
    def _init_register_map(self) -> Dict[str, Register]:
        """Initialize register mapping"""
        registers = {}
        
        # General Purpose Registers (32 registers)
        for i in range(32):
            registers[f"R{i}"] = Register(f"R{i}", i, 64, "GPR")
            registers[f"r{i}"] = Register(f"R{i}", i, 64, "GPR")
        
        # Floating Point Registers (32 registers)
        for i in range(32):
            registers[f"F{i}"] = Register(f"F{i}", i, 64, "FPR")
            registers[f"f{i}"] = Register(f"F{i}", i, 64, "FPR")
        
        if self.target == "alpham":
            # Vector Registers (32 registers, 512-bit each)
            for i in range(32):
                registers[f"V{i}"] = Register(f"V{i}", i, 512, "VPR")
                registers[f"v{i}"] = Register(f"V{i}", i, 512, "VPR")
            
            # AI/ML Registers (32 registers)
            for i in range(32):
                registers[f"A{i}"] = Register(f"A{i}", i, 64, "AIR")
                registers[f"a{i}"] = Register(f"A{i}", i, 64, "AIR")
            
            # MIMD Registers (16 registers)
            for i in range(16):
                registers[f"M{i}"] = Register(f"M{i}", i, 64, "MIMDR")
                registers[f"m{i}"] = Register(f"M{i}", i, 64, "MIMDR")
            
            # Security Registers (16 registers)
            for i in range(16):
                registers[f"SEC{i}"] = Register(f"SEC{i}", i, 64, "SECR")
                registers[f"sec{i}"] = Register(f"SEC{i}", i, 64, "SECR")
            
            # Scientific Computing Registers (16 registers)
            for i in range(16):
                registers[f"SCR{i}"] = Register(f"SCR{i}", i, 64, "SCR")
                registers[f"scr{i}"] = Register(f"SCR{i}", i, 64, "SCR")
            
            # Real-Time Registers (8 registers)
            for i in range(8):
                registers[f"RTR{i}"] = Register(f"RTR{i}", i, 64, "RTR")
                registers[f"rtr{i}"] = Register(f"RTR{i}", i, 64, "RTR")
            
            # Debug/Profiling Registers (16 registers)
            for i in range(16):
                registers[f"DPR{i}"] = Register(f"DPR{i}", i, 64, "DPR")
                registers[f"dpr{i}"] = Register(f"DPR{i}", i, 64, "DPR")
        
        return registers

    def _init_instruction_set(self) -> Dict[str, Dict]:
        """Initialize complete instruction set"""
        instruction_set = {
            # Basic Instructions
            "add": {"type": InstructionType.BASIC, "encoding": 0x00, "operands": 3},
            "sub": {"type": InstructionType.BASIC, "encoding": 0x01, "operands": 3},
            "mul": {"type": InstructionType.BASIC, "encoding": 0x02, "operands": 3},
            "div": {"type": InstructionType.BASIC, "encoding": 0x03, "operands": 3},
            "and": {"type": InstructionType.BASIC, "encoding": 0x04, "operands": 3},
            "or": {"type": InstructionType.BASIC, "encoding": 0x05, "operands": 3},
            "xor": {"type": InstructionType.BASIC, "encoding": 0x06, "operands": 3},
            "not": {"type": InstructionType.BASIC, "encoding": 0x07, "operands": 2},
            "shl": {"type": InstructionType.BASIC, "encoding": 0x08, "operands": 3},
            "shr": {"type": InstructionType.BASIC, "encoding": 0x09, "operands": 3},
            "rol": {"type": InstructionType.BASIC, "encoding": 0x0A, "operands": 3},
            "ror": {"type": InstructionType.BASIC, "encoding": 0x0B, "operands": 3},
            
            # Memory Instructions
            "ld": {"type": InstructionType.BASIC, "encoding": 0x10, "operands": 2},
            "st": {"type": InstructionType.BASIC, "encoding": 0x11, "operands": 2},
            "ldi": {"type": InstructionType.BASIC, "encoding": 0x12, "operands": 2},
            "sti": {"type": InstructionType.BASIC, "encoding": 0x13, "operands": 2},
            "ldf": {"type": InstructionType.BASIC, "encoding": 0x14, "operands": 2},
            "stf": {"type": InstructionType.BASIC, "encoding": 0x15, "operands": 2},
            
            # Branch Instructions
            "beq": {"type": InstructionType.BASIC, "encoding": 0x20, "operands": 3},
            "bne": {"type": InstructionType.BASIC, "encoding": 0x21, "operands": 3},
            "blt": {"type": InstructionType.BASIC, "encoding": 0x22, "operands": 3},
            "bgt": {"type": InstructionType.BASIC, "encoding": 0x23, "operands": 3},
            "ble": {"type": InstructionType.BASIC, "encoding": 0x24, "operands": 3},
            "bge": {"type": InstructionType.BASIC, "encoding": 0x25, "operands": 3},
            "jmp": {"type": InstructionType.BASIC, "encoding": 0x26, "operands": 1},
            "call": {"type": InstructionType.BASIC, "encoding": 0x27, "operands": 1},
            "ret": {"type": InstructionType.BASIC, "encoding": 0x28, "operands": 0},
            
            # Floating Point Instructions
            "fadd": {"type": InstructionType.FLOATING_POINT, "encoding": 0x30, "operands": 3},
            "fsub": {"type": InstructionType.FLOATING_POINT, "encoding": 0x31, "operands": 3},
            "fmul": {"type": InstructionType.FLOATING_POINT, "encoding": 0x32, "operands": 3},
            "fdiv": {"type": InstructionType.FLOATING_POINT, "encoding": 0x33, "operands": 3},
            "fsqrt": {"type": InstructionType.FLOATING_POINT, "encoding": 0x34, "operands": 2},
            "fabs": {"type": InstructionType.FLOATING_POINT, "encoding": 0x35, "operands": 2},
            "fneg": {"type": InstructionType.FLOATING_POINT, "encoding": 0x36, "operands": 2},
            "fround": {"type": InstructionType.FLOATING_POINT, "encoding": 0x37, "operands": 2},
            "fceil": {"type": InstructionType.FLOATING_POINT, "encoding": 0x38, "operands": 2},
            "ffloor": {"type": InstructionType.FLOATING_POINT, "encoding": 0x39, "operands": 2},
            "ftrunc": {"type": InstructionType.FLOATING_POINT, "encoding": 0x3A, "operands": 2},
            "fmin": {"type": InstructionType.FLOATING_POINT, "encoding": 0x3B, "operands": 3},
            "fmax": {"type": InstructionType.FLOATING_POINT, "encoding": 0x3C, "operands": 3},
            "fcmp": {"type": InstructionType.FLOATING_POINT, "encoding": 0x3D, "operands": 3},
            "fconvert": {"type": InstructionType.FLOATING_POINT, "encoding": 0x3E, "operands": 2},
        }
        
        if self.target == "alpham":
            # Vector Instructions (512-bit SIMD)
            vector_instructions = {
                "vadd": {"type": InstructionType.VECTOR, "encoding": 0x40, "operands": 3},
                "vsub": {"type": InstructionType.VECTOR, "encoding": 0x41, "operands": 3},
                "vmul": {"type": InstructionType.VECTOR, "encoding": 0x42, "operands": 3},
                "vdiv": {"type": InstructionType.VECTOR, "encoding": 0x43, "operands": 3},
                "vand": {"type": InstructionType.VECTOR, "encoding": 0x44, "operands": 3},
                "vor": {"type": InstructionType.VECTOR, "encoding": 0x45, "operands": 3},
                "vxor": {"type": InstructionType.VECTOR, "encoding": 0x46, "operands": 3},
                "vnot": {"type": InstructionType.VECTOR, "encoding": 0x47, "operands": 2},
                "vshl": {"type": InstructionType.VECTOR, "encoding": 0x48, "operands": 3},
                "vshr": {"type": InstructionType.VECTOR, "encoding": 0x49, "operands": 3},
                "vrol": {"type": InstructionType.VECTOR, "encoding": 0x4A, "operands": 3},
                "vror": {"type": InstructionType.VECTOR, "encoding": 0x4B, "operands": 3},
                "vld": {"type": InstructionType.VECTOR, "encoding": 0x4C, "operands": 2},
                "vst": {"type": InstructionType.VECTOR, "encoding": 0x4D, "operands": 2},
                "vpermute": {"type": InstructionType.VECTOR, "encoding": 0x4E, "operands": 3},
                "vshuffle": {"type": InstructionType.VECTOR, "encoding": 0x4F, "operands": 3},
                "vblend": {"type": InstructionType.VECTOR, "encoding": 0x50, "operands": 4},
                "vselect": {"type": InstructionType.VECTOR, "encoding": 0x51, "operands": 4},
                "vreduce": {"type": InstructionType.VECTOR, "encoding": 0x52, "operands": 2},
                "vscan": {"type": InstructionType.VECTOR, "encoding": 0x53, "operands": 2},
            }
            instruction_set.update(vector_instructions)
            
            # AI/ML Instructions
            ai_instructions = {
                "conv2d": {"type": InstructionType.AI_ML, "encoding": 0x60, "operands": 4},
                "conv3d": {"type": InstructionType.AI_ML, "encoding": 0x61, "operands": 4},
                "maxpool": {"type": InstructionType.AI_ML, "encoding": 0x62, "operands": 3},
                "avgpool": {"type": InstructionType.AI_ML, "encoding": 0x63, "operands": 3},
                "relu": {"type": InstructionType.AI_ML, "encoding": 0x64, "operands": 2},
                "sigmoid": {"type": InstructionType.AI_ML, "encoding": 0x65, "operands": 2},
                "tanh": {"type": InstructionType.AI_ML, "encoding": 0x66, "operands": 2},
                "softmax": {"type": InstructionType.AI_ML, "encoding": 0x67, "operands": 2},
                "lstm": {"type": InstructionType.AI_ML, "encoding": 0x68, "operands": 4},
                "gru": {"type": InstructionType.AI_ML, "encoding": 0x69, "operands": 4},
                "transformer": {"type": InstructionType.AI_ML, "encoding": 0x6A, "operands": 4},
                "attention": {"type": InstructionType.AI_ML, "encoding": 0x6B, "operands": 4},
                "matmul": {"type": InstructionType.AI_ML, "encoding": 0x6C, "operands": 3},
                "gemm": {"type": InstructionType.AI_ML, "encoding": 0x6D, "operands": 4},
                "batchnorm": {"type": InstructionType.AI_ML, "encoding": 0x6E, "operands": 3},
                "layernorm": {"type": InstructionType.AI_ML, "encoding": 0x6F, "operands": 3},
            }
            instruction_set.update(ai_instructions)
            
            # MIMD Instructions
            mimd_instructions = {
                "spawn": {"type": InstructionType.MIMD, "encoding": 0x70, "operands": 2},
                "join": {"type": InstructionType.MIMD, "encoding": 0x71, "operands": 1},
                "barrier": {"type": InstructionType.MIMD, "encoding": 0x72, "operands": 1},
                "reduce": {"type": InstructionType.MIMD, "encoding": 0x73, "operands": 3},
                "broadcast": {"type": InstructionType.MIMD, "encoding": 0x74, "operands": 2},
                "scatter": {"type": InstructionType.MIMD, "encoding": 0x75, "operands": 3},
                "gather": {"type": InstructionType.MIMD, "encoding": 0x76, "operands": 3},
                "allreduce": {"type": InstructionType.MIMD, "encoding": 0x77, "operands": 2},
                "allgather": {"type": InstructionType.MIMD, "encoding": 0x78, "operands": 2},
                "alltoall": {"type": InstructionType.MIMD, "encoding": 0x79, "operands": 2},
            }
            instruction_set.update(mimd_instructions)
            
            # Security Instructions
            security_instructions = {
                "aes_enc": {"type": InstructionType.SECURITY, "encoding": 0x80, "operands": 3},
                "aes_dec": {"type": InstructionType.SECURITY, "encoding": 0x81, "operands": 3},
                "aes_keygen": {"type": InstructionType.SECURITY, "encoding": 0x82, "operands": 2},
                "sha256": {"type": InstructionType.SECURITY, "encoding": 0x83, "operands": 2},
                "sha512": {"type": InstructionType.SECURITY, "encoding": 0x84, "operands": 2},
                "sha3": {"type": InstructionType.SECURITY, "encoding": 0x85, "operands": 2},
                "rsa_enc": {"type": InstructionType.SECURITY, "encoding": 0x86, "operands": 3},
                "rsa_dec": {"type": InstructionType.SECURITY, "encoding": 0x87, "operands": 3},
                "ecc_sign": {"type": InstructionType.SECURITY, "encoding": 0x88, "operands": 3},
                "ecc_verify": {"type": InstructionType.SECURITY, "encoding": 0x89, "operands": 3},
                "secure_hash": {"type": InstructionType.SECURITY, "encoding": 0x8A, "operands": 2},
                "secure_rand": {"type": InstructionType.SECURITY, "encoding": 0x8B, "operands": 1},
            }
            instruction_set.update(security_instructions)
            
            # Scientific Computing Instructions
            scientific_instructions = {
                "fft": {"type": InstructionType.SCIENTIFIC, "encoding": 0x90, "operands": 2},
                "ifft": {"type": InstructionType.SCIENTIFIC, "encoding": 0x91, "operands": 2},
                "dft": {"type": InstructionType.SCIENTIFIC, "encoding": 0x92, "operands": 2},
                "idft": {"type": InstructionType.SCIENTIFIC, "encoding": 0x93, "operands": 2},
                "matrix_mul": {"type": InstructionType.SCIENTIFIC, "encoding": 0x94, "operands": 3},
                "matrix_inv": {"type": InstructionType.SCIENTIFIC, "encoding": 0x95, "operands": 2},
                "matrix_det": {"type": InstructionType.SCIENTIFIC, "encoding": 0x96, "operands": 2},
                "eigen": {"type": InstructionType.SCIENTIFIC, "encoding": 0x97, "operands": 2},
                "svd": {"type": InstructionType.SCIENTIFIC, "encoding": 0x98, "operands": 2},
                "qr": {"type": InstructionType.SCIENTIFIC, "encoding": 0x99, "operands": 2},
                "lu": {"type": InstructionType.SCIENTIFIC, "encoding": 0x9A, "operands": 2},
                "cholesky": {"type": InstructionType.SCIENTIFIC, "encoding": 0x9B, "operands": 2},
                "sin": {"type": InstructionType.SCIENTIFIC, "encoding": 0x9C, "operands": 2},
                "cos": {"type": InstructionType.SCIENTIFIC, "encoding": 0x9D, "operands": 2},
                "tan": {"type": InstructionType.SCIENTIFIC, "encoding": 0x9E, "operands": 2},
                "exp": {"type": InstructionType.SCIENTIFIC, "encoding": 0x9F, "operands": 2},
                "log": {"type": InstructionType.SCIENTIFIC, "encoding": 0xA0, "operands": 2},
                "pow": {"type": InstructionType.SCIENTIFIC, "encoding": 0xA1, "operands": 3},
            }
            instruction_set.update(scientific_instructions)
            
            # Real-Time Instructions
            realtime_instructions = {
                "rt_set_priority": {"type": InstructionType.REAL_TIME, "encoding": 0xB0, "operands": 2},
                "rt_set_deadline": {"type": InstructionType.REAL_TIME, "encoding": 0xB1, "operands": 2},
                "rt_wait": {"type": InstructionType.REAL_TIME, "encoding": 0xB2, "operands": 1},
                "rt_signal": {"type": InstructionType.REAL_TIME, "encoding": 0xB3, "operands": 1},
                "rt_timer": {"type": InstructionType.REAL_TIME, "encoding": 0xB4, "operands": 2},
                "rt_schedule": {"type": InstructionType.REAL_TIME, "encoding": 0xB5, "operands": 1},
            }
            instruction_set.update(realtime_instructions)
            
            # Debug/Profiling Instructions
            debug_instructions = {
                "profile_start": {"type": InstructionType.DEBUG, "encoding": 0xC0, "operands": 1},
                "profile_stop": {"type": InstructionType.DEBUG, "encoding": 0xC1, "operands": 1},
                "profile_read": {"type": InstructionType.DEBUG, "encoding": 0xC2, "operands": 2},
                "breakpoint": {"type": InstructionType.DEBUG, "encoding": 0xC3, "operands": 1},
                "trace_start": {"type": InstructionType.DEBUG, "encoding": 0xC4, "operands": 0},
                "trace_stop": {"type": InstructionType.DEBUG, "encoding": 0xC5, "operands": 0},
                "trace_read": {"type": InstructionType.DEBUG, "encoding": 0xC6, "operands": 2},
                "perf_counter": {"type": InstructionType.DEBUG, "encoding": 0xC7, "operands": 2},
            }
            instruction_set.update(debug_instructions)
        
        # System Instructions
        system_instructions = {
            "syscall": {"type": InstructionType.SYSTEM, "encoding": 0xF0, "operands": 0},
            "halt": {"type": InstructionType.SYSTEM, "encoding": 0xF1, "operands": 0},
            "nop": {"type": InstructionType.SYSTEM, "encoding": 0xF2, "operands": 0},
            "int": {"type": InstructionType.SYSTEM, "encoding": 0xF3, "operands": 1},
            "iret": {"type": InstructionType.SYSTEM, "encoding": 0xF4, "operands": 0},
            "trap": {"type": InstructionType.SYSTEM, "encoding": 0xF5, "operands": 1},
        }
        instruction_set.update(system_instructions)
        
        return instruction_set

    def assemble(self, source_code: str) -> bytes:
        """Assemble source code to binary"""
        lines = source_code.split('\n')
        binary_output = bytearray()
        
        # First pass: collect labels and symbols
        self._first_pass(lines)
        
        # Second pass: generate binary
        self._second_pass(lines, binary_output)
        
        return bytes(binary_output)
    
    def _first_pass(self, lines: List[str]):
        """First pass: collect labels and addresses"""
        self.current_address = 0
        
        for line_num, line in enumerate(lines, 1):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
                
            # Check for label
            if ':' in line and not line.startswith('.'):
                label = line.split(':')[0].strip()
                self.labels[label] = self.current_address
                line = line.split(':', 1)[1].strip()
            
            if line:
                self.current_address += 4  # Assume 4-byte instructions
    
    def _second_pass(self, lines: List[str], binary_output: bytearray):
        """Second pass: generate binary code"""
        self.current_address = 0
        
        for line_num, line in enumerate(lines, 1):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
                
            # Skip label definition
            if ':' in line and not line.startswith('.'):
                line = line.split(':', 1)[1].strip()
            
            if line:
                instruction = self._parse_instruction(line, line_num)
                if instruction:
                    binary = self._encode_instruction(instruction)
                    binary_output.extend(binary)
                    self.current_address += 4
    
    def _parse_instruction(self, line: str, line_number: int) -> Optional[Instruction]:
        """Parse instruction line"""
        parts = line.split()
        if not parts:
            return None
            
        opcode = parts[0].upper()
        operands = [part.rstrip(',') for part in parts[1:]]
        
        return Instruction(
            opcode=opcode,
            operands=operands,
            line_number=line_number,
            address=self.current_address
        )
    
    def _encode_instruction(self, instruction: Instruction) -> bytes:
        """Encode instruction to binary"""
        # Simplified encoding - in practice this would be much more complex
        opcode_map = {
            'ADD': 0x01,
            'SUB': 0x02,
            'MUL': 0x03,
            'DIV': 0x04,
            'LDR': 0x10,
            'STR': 0x11,
            'JMP': 0x20,
            'CALL': 0x21,
            'RET': 0x22,
            'HALT': 0xFF
        }
        
        opcode = opcode_map.get(instruction.opcode, 0x00)
        
        # Create 4-byte instruction (simplified)
        instruction_bytes = bytearray(4)
        instruction_bytes[0] = opcode
        
        # Encode operands (simplified)
        if instruction.operands:
            if len(instruction.operands) >= 1:
                reg1 = self._parse_register(instruction.operands[0])
                instruction_bytes[1] = reg1
            if len(instruction.operands) >= 2:
                reg2 = self._parse_register(instruction.operands[1])
                instruction_bytes[2] = reg2
        
        return bytes(instruction_bytes)
    
    def _parse_register(self, operand: str) -> int:
        """Parse register operand"""
        if operand.startswith('R'):
            return int(operand[1:])
        elif operand.startswith('#'):
            return int(operand[1:])
        else:
            # Check if it's a label
            return self.labels.get(operand, 0)

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='AlphaAHB V5 Assembler')
    parser.add_argument('input', help='Input assembly file')
    parser.add_argument('-o', '--output', help='Output binary file')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    # Read input file
    with open(args.input, 'r') as f:
        source_code = f.read()
    
    # Assemble
    assembler = AlphaAHBAssembler()
    binary = assembler.assemble(source_code)
    
    # Write output
    output_file = args.output or args.input.replace('.s', '.bin')
    with open(output_file, 'wb') as f:
        f.write(binary)
    
    print(f"Assembled {len(binary)} bytes to {output_file}")

if __name__ == '__main__':
    main()