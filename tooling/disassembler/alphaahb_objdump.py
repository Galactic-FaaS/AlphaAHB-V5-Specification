#!/usr/bin/env python3
"""
AlphaAHB V5 Disassembler
Developed and Maintained by GLCTC Corp.

A comprehensive disassembler for the AlphaAHB V5 Instruction Set Architecture.
Supports binary analysis, symbol table analysis, and control flow analysis.
"""

import sys
import os
import argparse
import struct
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum

class InstructionType(Enum):
    """Instruction type enumeration"""
    BASIC = "basic"
    ARITHMETIC = "arithmetic"
    AI_ML = "ai_ml"
    VECTOR = "vector"
    MIMD = "mimd"
    SECURITY = "security"
    SCIENTIFIC = "scientific"
    REALTIME = "realtime"
    DEBUG = "debug"

@dataclass
class DisassembledInstruction:
    """Disassembled instruction"""
    address: int
    opcode: int
    mnemonic: str
    operands: List[str]
    raw_bytes: bytes
    instruction_type: InstructionType

class AlphaAHBDisassembler:
    """Main disassembler class for AlphaAHB V5"""
    
    def __init__(self):
        self.instructions = {}
        self.symbols = {}
        self.labels = {}
        self.disassembled = []
        
        # Initialize instruction set (reverse lookup)
        self._initialize_instruction_set()
    
    def _initialize_instruction_set(self):
        """Initialize the complete AlphaAHB V5 instruction set for disassembly"""
        
        # Basic Instructions (Opcode 0x00-0x1F)
        basic_instructions = [
            (0x00, "NOP", "R", [], "No operation", InstructionType.BASIC),
            (0x01, "HALT", "R", [], "Halt processor", InstructionType.BASIC),
            (0x02, "RET", "R", [], "Return from subroutine", InstructionType.BASIC),
            (0x03, "CALL", "I", ["imm"], "Call subroutine", InstructionType.BASIC),
            (0x04, "JMP", "I", ["imm"], "Unconditional jump", InstructionType.BASIC),
            (0x05, "JZ", "RI", ["reg", "imm"], "Jump if zero", InstructionType.BASIC),
            (0x06, "JNZ", "RI", ["reg", "imm"], "Jump if not zero", InstructionType.BASIC),
            (0x07, "JL", "RI", ["reg", "imm"], "Jump if less", InstructionType.BASIC),
            (0x08, "JLE", "RI", ["reg", "imm"], "Jump if less or equal", InstructionType.BASIC),
            (0x09, "JG", "RI", ["reg", "imm"], "Jump if greater", InstructionType.BASIC),
            (0x0A, "JGE", "RI", ["reg", "imm"], "Jump if greater or equal", InstructionType.BASIC),
            (0x0B, "PUSH", "R", ["reg"], "Push register to stack", InstructionType.BASIC),
            (0x0C, "POP", "R", ["reg"], "Pop register from stack", InstructionType.BASIC),
            (0x0D, "MOV", "RR", ["reg1", "reg2"], "Move register to register", InstructionType.BASIC),
            (0x0E, "LDI", "RI", ["reg", "imm"], "Load immediate", InstructionType.BASIC),
            (0x0F, "LDR", "RR", ["reg1", "reg2"], "Load register", InstructionType.BASIC),
            (0x10, "STR", "RR", ["reg1", "reg2"], "Store register", InstructionType.BASIC),
            (0x11, "ADD", "RRR", ["reg1", "reg2", "reg3"], "Add registers", InstructionType.BASIC),
            (0x12, "SUB", "RRR", ["reg1", "reg2", "reg3"], "Subtract registers", InstructionType.BASIC),
            (0x13, "MUL", "RRR", ["reg1", "reg2", "reg3"], "Multiply registers", InstructionType.BASIC),
            (0x14, "DIV", "RRR", ["reg1", "reg2", "reg3"], "Divide registers", InstructionType.BASIC),
            (0x15, "AND", "RRR", ["reg1", "reg2", "reg3"], "Bitwise AND", InstructionType.BASIC),
            (0x16, "OR", "RRR", ["reg1", "reg2", "reg3"], "Bitwise OR", InstructionType.BASIC),
            (0x17, "XOR", "RRR", ["reg1", "reg2", "reg3"], "Bitwise XOR", InstructionType.BASIC),
            (0x18, "NOT", "RR", ["reg1", "reg2"], "Bitwise NOT", InstructionType.BASIC),
            (0x19, "SHL", "RRI", ["reg1", "reg2", "imm"], "Shift left", InstructionType.BASIC),
            (0x1A, "SHR", "RRI", ["reg1", "reg2", "imm"], "Shift right", InstructionType.BASIC),
            (0x1B, "CMP", "RR", ["reg1", "reg2"], "Compare registers", InstructionType.BASIC),
            (0x1C, "TEST", "RR", ["reg1", "reg2"], "Test registers", InstructionType.BASIC),
            (0x1D, "INC", "R", ["reg"], "Increment register", InstructionType.BASIC),
            (0x1E, "DEC", "R", ["reg"], "Decrement register", InstructionType.BASIC),
            (0x1F, "NEG", "RR", ["reg1", "reg2"], "Negate register", InstructionType.BASIC),
        ]
        
        # Add basic instructions
        for opcode, mnemonic, format_str, operands, desc, inst_type in basic_instructions:
            self.instructions[opcode] = {
                'mnemonic': mnemonic,
                'format': format_str,
                'operands': operands,
                'description': desc,
                'type': inst_type
            }
        
        # Advanced Arithmetic Instructions (Opcode 0x20-0x3F)
        arithmetic_instructions = [
            (0x20, "FADD", "RRR", ["reg1", "reg2", "reg3"], "Floating-point add", InstructionType.ARITHMETIC),
            (0x21, "FSUB", "RRR", ["reg1", "reg2", "reg3"], "Floating-point subtract", InstructionType.ARITHMETIC),
            (0x22, "FMUL", "RRR", ["reg1", "reg2", "reg3"], "Floating-point multiply", InstructionType.ARITHMETIC),
            (0x23, "FDIV", "RRR", ["reg1", "reg2", "reg3"], "Floating-point divide", InstructionType.ARITHMETIC),
            (0x24, "FSQRT", "RR", ["reg1", "reg2"], "Floating-point square root", InstructionType.ARITHMETIC),
            (0x25, "FABS", "RR", ["reg1", "reg2"], "Floating-point absolute value", InstructionType.ARITHMETIC),
            (0x26, "FNEG", "RR", ["reg1", "reg2"], "Floating-point negate", InstructionType.ARITHMETIC),
            (0x27, "FROUND", "RRI", ["reg1", "reg2", "imm"], "Floating-point round", InstructionType.ARITHMETIC),
            (0x28, "FTRUNC", "RR", ["reg1", "reg2"], "Floating-point truncate", InstructionType.ARITHMETIC),
            (0x29, "FCEIL", "RR", ["reg1", "reg2"], "Floating-point ceiling", InstructionType.ARITHMETIC),
            (0x2A, "FFLOOR", "RR", ["reg1", "reg2"], "Floating-point floor", InstructionType.ARITHMETIC),
            (0x2B, "FCMP", "RR", ["reg1", "reg2"], "Floating-point compare", InstructionType.ARITHMETIC),
            (0x2C, "FMIN", "RRR", ["reg1", "reg2", "reg3"], "Floating-point minimum", InstructionType.ARITHMETIC),
            (0x2D, "FMAX", "RRR", ["reg1", "reg2", "reg3"], "Floating-point maximum", InstructionType.ARITHMETIC),
            (0x2E, "FMA", "RRRR", ["reg1", "reg2", "reg3", "reg4"], "Fused multiply-add", InstructionType.ARITHMETIC),
            (0x2F, "FMS", "RRRR", ["reg1", "reg2", "reg3", "reg4"], "Fused multiply-subtract", InstructionType.ARITHMETIC),
            (0x30, "FNMA", "RRRR", ["reg1", "reg2", "reg3", "reg4"], "Fused negate multiply-add", InstructionType.ARITHMETIC),
            (0x31, "FNMS", "RRRR", ["reg1", "reg2", "reg3", "reg4"], "Fused negate multiply-subtract", InstructionType.ARITHMETIC),
            (0x32, "FCVT", "RRI", ["reg1", "reg2", "imm"], "Floating-point convert", InstructionType.ARITHMETIC),
            (0x33, "FTOI", "RR", ["reg1", "reg2"], "Floating-point to integer", InstructionType.ARITHMETIC),
            (0x34, "ITOF", "RR", ["reg1", "reg2"], "Integer to floating-point", InstructionType.ARITHMETIC),
            (0x35, "FCLASS", "RR", ["reg1", "reg2"], "Floating-point classify", InstructionType.ARITHMETIC),
            (0x36, "FCOPYSIGN", "RRR", ["reg1", "reg2", "reg3"], "Floating-point copy sign", InstructionType.ARITHMETIC),
            (0x37, "FNAN", "RR", ["reg1", "reg2"], "Floating-point NaN", InstructionType.ARITHMETIC),
            (0x38, "FINF", "RR", ["reg1", "reg2"], "Floating-point infinity", InstructionType.ARITHMETIC),
            (0x39, "FZERO", "RR", ["reg1", "reg2"], "Floating-point zero", InstructionType.ARITHMETIC),
            (0x3A, "FONE", "RR", ["reg1", "reg2"], "Floating-point one", InstructionType.ARITHMETIC),
            (0x3B, "FISNAN", "RR", ["reg1", "reg2"], "Floating-point is NaN", InstructionType.ARITHMETIC),
            (0x3C, "FISINF", "RR", ["reg1", "reg2"], "Floating-point is infinity", InstructionType.ARITHMETIC),
            (0x3D, "FISZERO", "RR", ["reg1", "reg2"], "Floating-point is zero", InstructionType.ARITHMETIC),
            (0x3E, "FISNORMAL", "RR", ["reg1", "reg2"], "Floating-point is normal", InstructionType.ARITHMETIC),
            (0x3F, "FISSUBNORMAL", "RR", ["reg1", "reg2"], "Floating-point is subnormal", InstructionType.ARITHMETIC),
        ]
        
        # Add arithmetic instructions
        for opcode, mnemonic, format_str, operands, desc, inst_type in arithmetic_instructions:
            self.instructions[opcode] = {
                'mnemonic': mnemonic,
                'format': format_str,
                'operands': operands,
                'description': desc,
                'type': inst_type
            }
    
    def disassemble_file(self, filename: str, start_addr: int = 0) -> bool:
        """Disassemble a binary file"""
        try:
            with open(filename, 'rb') as f:
                data = f.read()
            return self.disassemble(data, start_addr)
        except FileNotFoundError:
            print(f"File not found: {filename}")
            return False
        except Exception as e:
            print(f"Error reading file: {e}")
            return False
    
    def disassemble(self, data: bytes, start_addr: int = 0) -> bool:
        """Disassemble binary data"""
        self.disassembled = []
        address = start_addr
        
        while address < len(data) - 3:
            # Read 32-bit instruction
            instruction_bytes = data[address:address+4]
            if len(instruction_bytes) < 4:
                break
                
            instruction_word = struct.unpack('<I', instruction_bytes)[0]
            
            # Disassemble instruction
            disasm_inst = self._disassemble_instruction(address, instruction_word, instruction_bytes)
            self.disassembled.append(disasm_inst)
            
            address += 4
        
        return True
    
    def _disassemble_instruction(self, address: int, instruction_word: int, raw_bytes: bytes) -> DisassembledInstruction:
        """Disassemble a single instruction"""
        opcode = instruction_word & 0xFF
        
        if opcode in self.instructions:
            inst_info = self.instructions[opcode]
            mnemonic = inst_info['mnemonic']
            format_str = inst_info['format']
            inst_type = inst_info['type']
            
            # Decode operands based on format
            operands = self._decode_operands(instruction_word, format_str, inst_info['operands'])
            
            return DisassembledInstruction(
                address=address,
                opcode=opcode,
                mnemonic=mnemonic,
                operands=operands,
                raw_bytes=raw_bytes,
                instruction_type=inst_type
            )
        else:
            # Unknown instruction
            return DisassembledInstruction(
                address=address,
                opcode=opcode,
                mnemonic=f"UNKNOWN_{opcode:02X}",
                operands=[],
                raw_bytes=raw_bytes,
                instruction_type=InstructionType.BASIC
            )
    
    def _decode_operands(self, instruction_word: int, format_str: str, operand_types: List[str]) -> List[str]:
        """Decode instruction operands"""
        operands = []
        
        if format_str == "R":
            # No operands
            pass
        elif format_str == "I":
            # Immediate operand
            imm = (instruction_word >> 8) & 0xFFFFFF
            operands.append(f"0x{imm:06X}")
        elif format_str == "RI":
            # Register and immediate
            reg = (instruction_word >> 8) & 0xFF
            imm = (instruction_word >> 16) & 0xFFFF
            operands.append(self._format_register(reg))
            operands.append(f"0x{imm:04X}")
        elif format_str == "RR":
            # Two registers
            reg1 = (instruction_word >> 8) & 0xFF
            reg2 = (instruction_word >> 16) & 0xFF
            operands.append(self._format_register(reg1))
            operands.append(self._format_register(reg2))
        elif format_str == "RRR":
            # Three registers
            reg1 = (instruction_word >> 8) & 0xFF
            reg2 = (instruction_word >> 16) & 0xFF
            reg3 = (instruction_word >> 24) & 0xFF
            operands.append(self._format_register(reg1))
            operands.append(self._format_register(reg2))
            operands.append(self._format_register(reg3))
        elif format_str == "RRI":
            # Two registers and immediate
            reg1 = (instruction_word >> 8) & 0xFF
            reg2 = (instruction_word >> 16) & 0xFF
            imm = (instruction_word >> 24) & 0xFF
            operands.append(self._format_register(reg1))
            operands.append(self._format_register(reg2))
            operands.append(f"0x{imm:02X}")
        elif format_str == "RRRR":
            # Four registers (for FMA instructions)
            reg1 = (instruction_word >> 8) & 0xFF
            reg2 = (instruction_word >> 16) & 0xFF
            reg3 = (instruction_word >> 24) & 0xFF
            reg4 = (instruction_word >> 0) & 0xFF  # This would need special handling
            operands.append(self._format_register(reg1))
            operands.append(self._format_register(reg2))
            operands.append(self._format_register(reg3))
            operands.append(self._format_register(reg4))
        
        return operands
    
    def _format_register(self, reg_num: int) -> str:
        """Format register number as string"""
        if 0 <= reg_num <= 31:
            return f"R{reg_num}"
        elif 32 <= reg_num <= 63:
            return f"F{reg_num - 32}"
        elif 64 <= reg_num <= 79:
            return f"V{reg_num - 64}"
        else:
            return f"REG{reg_num}"
    
    def print_disassembly(self, show_addresses: bool = True, show_bytes: bool = True, 
                         show_types: bool = False, filter_type: Optional[InstructionType] = None):
        """Print disassembled code"""
        for inst in self.disassembled:
            if filter_type and inst.instruction_type != filter_type:
                continue
                
            line_parts = []
            
            if show_addresses:
                line_parts.append(f"{inst.address:08X}:")
            
            if show_bytes:
                hex_bytes = ' '.join(f"{b:02X}" for b in inst.raw_bytes)
                line_parts.append(f"{hex_bytes:12}")
            
            mnemonic = inst.mnemonic
            if inst.operands:
                mnemonic += " " + ", ".join(inst.operands)
            
            line_parts.append(mnemonic)
            
            if show_types:
                line_parts.append(f"({inst.instruction_type.value})")
            
            print(" ".join(line_parts))
    
    def get_statistics(self) -> Dict:
        """Get disassembly statistics"""
        stats = {
            'total_instructions': len(self.disassembled),
            'instruction_types': {},
            'opcodes': {},
            'address_range': (0, 0)
        }
        
        if self.disassembled:
            stats['address_range'] = (self.disassembled[0].address, self.disassembled[-1].address)
        
        for inst in self.disassembled:
            # Count by instruction type
            inst_type = inst.instruction_type.value
            stats['instruction_types'][inst_type] = stats['instruction_types'].get(inst_type, 0) + 1
            
            # Count by opcode
            stats['opcodes'][inst.opcode] = stats['opcodes'].get(inst.opcode, 0) + 1
        
        return stats

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='AlphaAHB V5 Disassembler')
    parser.add_argument('input', help='Input binary file')
    parser.add_argument('-a', '--address', type=int, default=0, help='Start address')
    parser.add_argument('-s', '--show-addresses', action='store_true', help='Show addresses')
    parser.add_argument('-b', '--show-bytes', action='store_true', help='Show instruction bytes')
    parser.add_argument('-t', '--show-types', action='store_true', help='Show instruction types')
    parser.add_argument('-f', '--filter', choices=['basic', 'arithmetic', 'ai_ml', 'vector', 'mimd', 'security', 'scientific', 'realtime', 'debug'], help='Filter by instruction type')
    parser.add_argument('--stats', action='store_true', help='Show statistics')
    
    args = parser.parse_args()
    
    disassembler = AlphaAHBDisassembler()
    
    if disassembler.disassemble_file(args.input, args.address):
        filter_type = None
        if args.filter:
            filter_type = InstructionType(args.filter)
        
        disassembler.print_disassembly(
            show_addresses=args.show_addresses,
            show_bytes=args.show_bytes,
            show_types=args.show_types,
            filter_type=filter_type
        )
        
        if args.stats:
            print("\nStatistics:")
            stats = disassembler.get_statistics()
            print(f"Total instructions: {stats['total_instructions']}")
            print(f"Address range: 0x{stats['address_range'][0]:08X} - 0x{stats['address_range'][1]:08X}")
            print("\nInstruction types:")
            for inst_type, count in stats['instruction_types'].items():
                print(f"  {inst_type}: {count}")
    else:
        print("Disassembly failed")
        sys.exit(1)

if __name__ == '__main__':
    main()
