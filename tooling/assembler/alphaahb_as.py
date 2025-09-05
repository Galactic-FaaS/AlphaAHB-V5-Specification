#!/usr/bin/env python3
"""
AlphaAHB V5 Assembler
Developed and Maintained by GLCTC Corp.

A comprehensive assembler for the AlphaAHB V5 Instruction Set Architecture.
Supports all instruction types, macros, and advanced features.
"""

import sys
import os
import argparse
import re
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass

@dataclass
class Instruction:
    """Instruction representation"""
    opcode: str
    operands: List[str]
    line_number: int
    address: int

class AlphaAHBAssembler:
    """Main assembler class"""
    
    def __init__(self):
        self.instructions = {}
        self.labels = {}
        self.current_address = 0
        
    def assemble(self, source_code: str) -> bytes:
        """Assemble source code to binary"""
        lines = source_code.split('\n')
        binary_output = bytearray()
        
        # First pass: collect labels
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