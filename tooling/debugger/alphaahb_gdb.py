#!/usr/bin/env python3
"""
AlphaAHB V5 Debugger
Developed and Maintained by GLCTC Corp.

A GDB-compatible debugger for the AlphaAHB V5 Instruction Set Architecture.
Supports hardware breakpoints, performance monitoring, and multi-core debugging.
"""

import sys
import os
import argparse
import socket
import threading
import struct
import time
import json
import pickle
import traceback
from typing import Dict, List, Tuple, Optional, Union
from dataclasses import dataclass, asdict
from enum import Enum
import numpy as np
import matplotlib.pyplot as plt
from collections import deque

class BreakpointType(Enum):
    """Breakpoint type enumeration"""
    SOFTWARE = "software"
    HARDWARE = "hardware"
    WATCHPOINT = "watchpoint"
    ACCESS = "access"
    CONDITIONAL = "conditional"
    TEMPORARY = "temporary"
    TRACE = "trace"

class DebugMode(Enum):
    """Debug mode enumeration"""
    NORMAL = "normal"
    TIME_TRAVEL = "time_travel"
    MULTI_CORE = "multi_core"
    PERFORMANCE = "performance"
    SECURITY = "security"

@dataclass
class Breakpoint:
    """Breakpoint representation"""
    address: int
    type: BreakpointType
    enabled: bool
    hit_count: int
    condition: Optional[str] = None
    thread_id: Optional[int] = None
    ignore_count: int = 0
    commands: List[str] = None

@dataclass
class ExecutionState:
    """Execution state snapshot"""
    cycle: int
    pc: int
    registers: 'RegisterState'
    memory_snapshot: Dict[int, bytes]
    pipeline_state: List[Dict]
    performance_counters: Dict[str, int]
    timestamp: float

@dataclass
class TraceEvent:
    """Trace event representation"""
    cycle: int
    pc: int
    instruction: str
    operands: List[str]
    registers_changed: Dict[str, Any]
    memory_accessed: List[int]
    event_type: str
    timestamp: float

@dataclass
class RegisterState:
    """Register state representation"""
    general: List[int]  # R0-R31
    floating: List[float]  # F0-F31
    vector: List[List[int]]  # V0-V15
    ai_ml: List[float]  # AI/ML registers
    security: List[int]  # Security registers
    mimd: List[int]  # MIMD registers
    scientific: List[float]  # Scientific registers
    realtime: List[int]  # Real-time registers
    debug: List[int]  # Debug registers
    pc: int
    flags: int

class AlphaAHBDebugger:
    """Main debugger class for AlphaAHB V5"""
    
    def __init__(self, target_host: str = "localhost", target_port: int = 1234):
        self.target_host = target_host
        self.target_port = target_port
        self.connected = False
        self.socket = None
        self.breakpoints = {}
        self.register_state = None
        self.memory_cache = {}
        self.performance_counters = {}
        self.threads = []
        self.running = False
        
        # Advanced debugging features
        self.debug_mode = DebugMode.NORMAL
        self.execution_history = deque(maxlen=10000)  # Time travel debugging
        self.trace_buffer = deque(maxlen=50000)  # Execution trace
        self.state_snapshots = {}  # Saved execution states
        self.race_conditions = []  # Detected race conditions
        self.deadlocks = []  # Detected deadlocks
        self.performance_profiler = {}  # Performance profiling data
        self.security_monitor = {}  # Security monitoring data
        
        # GDB protocol state
        self.packet_buffer = ""
        self.sequence_number = 0
        
    def connect(self) -> bool:
        """Connect to target"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((self.target_host, self.target_port))
            self.connected = True
            print(f"Connected to target at {self.target_host}:{self.target_port}")
            return True
        except Exception as e:
            print(f"Failed to connect: {e}")
            return False
    
    def disconnect(self):
        """Disconnect from target"""
        if self.socket:
            self.socket.close()
            self.socket = None
        self.connected = False
        print("Disconnected from target")
    
    def send_packet(self, packet: str) -> str:
        """Send GDB packet and receive response"""
        if not self.connected:
            return ""
        
        # Add checksum
        checksum = sum(ord(c) for c in packet) & 0xFF
        full_packet = f"${packet}#{checksum:02X}"
        
        try:
            self.socket.send(full_packet.encode())
            response = self.socket.recv(1024).decode()
            
            # Parse response
            if response.startswith('$') and '#' in response:
                data = response[1:response.find('#')]
                return data
            else:
                return response
        except Exception as e:
            print(f"Error sending packet: {e}")
            return ""
    
    def set_breakpoint(self, address: int, type: BreakpointType = BreakpointType.SOFTWARE) -> bool:
        """Set a breakpoint"""
        bp = Breakpoint(address=address, type=type, enabled=True, hit_count=0)
        self.breakpoints[address] = bp
        
        # Send breakpoint command to target
        if type == BreakpointType.SOFTWARE:
            cmd = f"Z0,{address:08X},1"  # Software breakpoint
        elif type == BreakpointType.HARDWARE:
            cmd = f"Z1,{address:08X},1"  # Hardware breakpoint
        elif type == BreakpointType.WATCHPOINT:
            cmd = f"Z2,{address:08X},4"  # Watchpoint (4 bytes)
        else:
            return False
        
        response = self.send_packet(cmd)
        return response == "OK"
    
    def clear_breakpoint(self, address: int) -> bool:
        """Clear a breakpoint"""
        if address in self.breakpoints:
            del self.breakpoints[address]
            
            # Send clear breakpoint command
            cmd = f"z0,{address:08X},1"
            response = self.send_packet(cmd)
            return response == "OK"
        return False
    
    def continue_execution(self) -> bool:
        """Continue execution"""
        response = self.send_packet("c")
        self.running = True
        return response.startswith("S") or response.startswith("T")
    
    def step_instruction(self) -> bool:
        """Step one instruction"""
        response = self.send_packet("s")
        return response.startswith("S") or response.startswith("T")
    
    def step_over(self) -> bool:
        """Step over function call"""
        response = self.send_packet("n")
        return response.startswith("S") or response.startswith("T")
    
    def halt_execution(self) -> bool:
        """Halt execution"""
        response = self.send_packet("\x03")  # Ctrl+C
        self.running = False
        return response.startswith("S") or response.startswith("T")
    
    def read_registers(self) -> RegisterState:
        """Read all registers"""
        response = self.send_packet("g")
        if response:
            self.register_state = self._parse_register_response(response)
        return self.register_state
    
    def write_register(self, reg_num: int, value: int) -> bool:
        """Write a register"""
        cmd = f"G{value:08X}"
        response = self.send_packet(cmd)
        return response == "OK"
    
    def read_memory(self, address: int, size: int) -> bytes:
        """Read memory"""
        cmd = f"m{address:08X},{size:X}"
        response = self.send_packet(cmd)
        if response and not response.startswith("E"):
            # Parse hex data
            data = bytes.fromhex(response)
            return data
        return b""
    
    def write_memory(self, address: int, data: bytes) -> bool:
        """Write memory"""
        hex_data = data.hex()
        cmd = f"M{address:08X},{len(data):X}:{hex_data}"
        response = self.send_packet(cmd)
        return response == "OK"
    
    def _parse_register_response(self, response: str) -> RegisterState:
        """Parse register response from target"""
        # This would parse the actual register data from the target
        # For now, return a dummy state
        return RegisterState(
            general=[0] * 32,
            floating=[0.0] * 32,
            vector=[[0] * 16 for _ in range(16)],
            ai_ml=[0.0] * 64,
            security=[0] * 32,
            mimd=[0] * 32,
            scientific=[0.0] * 32,
            realtime=[0] * 16,
            debug=[0] * 32,
            pc=0,
            flags=0
        )
    
    def get_performance_counters(self) -> Dict:
        """Get performance counters"""
        response = self.send_packet("qXfer:perf:read::0,1000")
        if response:
            # Parse performance counter data
            pass
        return self.performance_counters
    
    def set_performance_counter(self, counter: str, value: int) -> bool:
        """Set performance counter"""
        cmd = f"qXfer:perf:write::{counter}:{value:X}"
        response = self.send_packet(cmd)
        return response == "OK"
    
    def get_thread_info(self) -> List[Dict]:
        """Get thread information"""
        response = self.send_packet("qfThreadInfo")
        threads = []
        # Parse thread info
        return threads
    
    def set_thread(self, thread_id: int) -> bool:
        """Set current thread"""
        cmd = f"Hg{thread_id:X}"
        response = self.send_packet(cmd)
        return response == "OK"
    
    def get_memory_map(self) -> List[Dict]:
        """Get memory map"""
        response = self.send_packet("qXfer:memory-map:read::0,1000")
        memory_map = []
        # Parse memory map
        return memory_map
    
    def get_target_description(self) -> str:
        """Get target description"""
        response = self.send_packet("qXfer:features:read::target.xml:0,1000")
        return response
    
    def run_interactive(self):
        """Run interactive debugger"""
        print("AlphaAHB V5 Debugger - Interactive Mode")
        print("Type 'help' for available commands")
        
        while True:
            try:
                command = input("(gdb) ").strip()
                if not command:
                    continue
                
                if command == "quit" or command == "q":
                    break
                elif command == "help" or command == "h":
                    self._print_help()
                elif command.startswith("break ") or command.startswith("b "):
                    addr = int(command.split()[1], 16)
                    if self.set_breakpoint(addr):
                        print(f"Breakpoint set at 0x{addr:08X}")
                    else:
                        print("Failed to set breakpoint")
                elif command.startswith("clear "):
                    addr = int(command.split()[1], 16)
                    if self.clear_breakpoint(addr):
                        print(f"Breakpoint cleared at 0x{addr:08X}")
                    else:
                        print("Breakpoint not found")
                elif command == "continue" or command == "c":
                    if self.continue_execution():
                        print("Continuing execution")
                    else:
                        print("Failed to continue")
                elif command == "step" or command == "s":
                    if self.step_instruction():
                        print("Stepped one instruction")
                    else:
                        print("Failed to step")
                elif command == "next" or command == "n":
                    if self.step_over():
                        print("Stepped over")
                    else:
                        print("Failed to step over")
                elif command == "halt" or command == "stop":
                    if self.halt_execution():
                        print("Execution halted")
                    else:
                        print("Failed to halt")
                elif command == "registers" or command == "regs":
                    regs = self.read_registers()
                    self._print_registers(regs)
                elif command.startswith("read "):
                    parts = command.split()
                    if len(parts) >= 3:
                        addr = int(parts[1], 16)
                        size = int(parts[2])
                        data = self.read_memory(addr, size)
                        print(f"Memory at 0x{addr:08X}: {data.hex()}")
                elif command.startswith("write "):
                    parts = command.split()
                    if len(parts) >= 3:
                        addr = int(parts[1], 16)
                        data = bytes.fromhex(parts[2])
                        if self.write_memory(addr, data):
                            print(f"Wrote {len(data)} bytes to 0x{addr:08X}")
                        else:
                            print("Failed to write memory")
                elif command == "perf":
                    perf = self.get_performance_counters()
                    self._print_performance_counters(perf)
                elif command == "threads":
                    threads = self.get_thread_info()
                    self._print_threads(threads)
                elif command == "memory":
                    mem_map = self.get_memory_map()
                    self._print_memory_map(mem_map)
                elif command.startswith("save_state "):
                    name = command.split()[1]
                    self.save_execution_state(name)
                elif command.startswith("restore_state "):
                    name = command.split()[1]
                    self.restore_execution_state(name)
                elif command == "start_trace":
                    self.start_trace()
                elif command == "stop_trace":
                    self.stop_trace()
                elif command == "analyze_races":
                    races = self.analyze_race_conditions()
                    print(f"Found {len(races)} race conditions")
                    for race in races:
                        print(f"  Race at 0x{race['address']:08X} between threads {race['thread1']} and {race['thread2']}")
                elif command == "analyze_deadlocks":
                    deadlocks = self.analyze_deadlocks()
                    print(f"Found {len(deadlocks)} deadlocks")
                    for deadlock in deadlocks:
                        print(f"  Deadlock involving threads: {deadlock['threads']}")
                elif command == "start_profiling":
                    self.start_performance_profiling()
                elif command == "stop_profiling":
                    results = self.stop_performance_profiling()
                elif command == "start_security":
                    self.start_security_monitoring()
                elif command == "stop_security":
                    results = self.stop_security_monitoring()
                elif command == "generate_report":
                    self.generate_debug_report()
                elif command == "visualize_trace":
                    self.visualize_execution_trace()
                elif command.startswith("set_mode "):
                    mode_name = command.split()[1]
                    try:
                        mode = DebugMode(mode_name)
                        self.set_debug_mode(mode)
                    except ValueError:
                        print(f"Unknown debug mode: {mode_name}")
                else:
                    print(f"Unknown command: {command}")
                    
            except KeyboardInterrupt:
                print("\nUse 'quit' to exit")
            except Exception as e:
                print(f"Error: {e}")
    
    def _print_help(self):
        """Print help information"""
        print("Available commands:")
        print("  break <addr>     - Set breakpoint at address")
        print("  clear <addr>     - Clear breakpoint at address")
        print("  continue         - Continue execution")
        print("  step             - Step one instruction")
        print("  next             - Step over function call")
        print("  halt             - Halt execution")
        print("  registers        - Show all registers")
        print("  read <addr> <size> - Read memory")
        print("  write <addr> <data> - Write memory")
        print("  perf             - Show performance counters")
        print("  threads          - Show thread information")
        print("  memory           - Show memory map")
        print("")
        print("Advanced debugging commands:")
        print("  save_state <name> - Save execution state for time travel")
        print("  restore_state <name> - Restore saved execution state")
        print("  start_trace      - Start execution tracing")
        print("  stop_trace       - Stop execution tracing")
        print("  analyze_races    - Analyze for race conditions")
        print("  analyze_deadlocks - Analyze for deadlocks")
        print("  start_profiling  - Start performance profiling")
        print("  stop_profiling   - Stop performance profiling")
        print("  start_security   - Start security monitoring")
        print("  stop_security    - Stop security monitoring")
        print("  generate_report  - Generate comprehensive debug report")
        print("  visualize_trace  - Generate execution trace visualization")
        print("  set_mode <mode>  - Set debug mode (normal, time_travel, multi_core, performance, security)")
        print("")
        print("  help             - Show this help")
        print("  quit             - Exit debugger")
    
    def _print_registers(self, regs: RegisterState):
        """Print register state"""
        print("General Purpose Registers:")
        for i in range(0, 32, 4):
            print(f"  R{i:2d}: 0x{regs.general[i]:08X}  R{i+1:2d}: 0x{regs.general[i+1]:08X}  R{i+2:2d}: 0x{regs.general[i+2]:08X}  R{i+3:2d}: 0x{regs.general[i+3]:08X}")
        
        print("Floating-Point Registers:")
        for i in range(0, 32, 4):
            print(f"  F{i:2d}: {regs.floating[i]:12.6f}  F{i+1:2d}: {regs.floating[i+1]:12.6f}  F{i+2:2d}: {regs.floating[i+2]:12.6f}  F{i+3:2d}: {regs.floating[i+3]:12.6f}")
        
        print(f"Program Counter: 0x{regs.pc:08X}")
        print(f"Flags: 0x{regs.flags:08X}")
    
    def _print_performance_counters(self, perf: Dict):
        """Print performance counters"""
        print("Performance Counters:")
        for counter, value in perf.items():
            print(f"  {counter}: {value}")
    
    def _print_threads(self, threads: List[Dict]):
        """Print thread information"""
        print("Threads:")
        for thread in threads:
            print(f"  Thread {thread['id']}: {thread['state']}")
    
    def _print_memory_map(self, mem_map: List[Dict]):
        """Print memory map"""
        print("Memory Map:")
        for region in mem_map:
            print(f"  0x{region['start']:08X} - 0x{region['end']:08X}: {region['name']}")
    
    # Advanced debugging methods
    
    def set_debug_mode(self, mode: DebugMode):
        """Set debug mode"""
        self.debug_mode = mode
        print(f"Debug mode set to: {mode.value}")
    
    def save_execution_state(self, name: str) -> bool:
        """Save current execution state for time travel debugging"""
        if not self.connected:
            print("Not connected to target")
            return False
        
        try:
            # Get current state
            registers = self.read_registers()
            memory_snapshot = {}
            
            # Save memory regions
            for addr in range(0, 0x1000, 0x100):  # Save first 4KB in 256-byte chunks
                memory_snapshot[addr] = self.read_memory(addr, 256)
            
            # Create execution state
            state = ExecutionState(
                cycle=len(self.execution_history),
                pc=registers.pc,
                registers=registers,
                memory_snapshot=memory_snapshot,
                pipeline_state=[],  # Would be filled by target
                performance_counters=self.performance_counters.copy(),
                timestamp=time.time()
            )
            
            self.state_snapshots[name] = state
            print(f"Execution state saved as '{name}'")
            return True
            
        except Exception as e:
            print(f"Failed to save execution state: {e}")
            return False
    
    def restore_execution_state(self, name: str) -> bool:
        """Restore saved execution state"""
        if name not in self.state_snapshots:
            print(f"State '{name}' not found")
            return False
        
        try:
            state = self.state_snapshots[name]
            
            # Restore registers
            for i, reg_val in enumerate(state.registers.general):
                self.write_register(i, reg_val)
            
            # Restore memory
            for addr, data in state.memory_snapshot.items():
                self.write_memory(addr, data)
            
            # Restore performance counters
            self.performance_counters = state.performance_counters.copy()
            
            print(f"Execution state '{name}' restored")
            return True
            
        except Exception as e:
            print(f"Failed to restore execution state: {e}")
            return False
    
    def start_trace(self, trace_file: str = None):
        """Start execution tracing"""
        self.trace_buffer.clear()
        self.trace_file = trace_file
        print("Execution tracing started")
    
    def stop_trace(self):
        """Stop execution tracing"""
        if hasattr(self, 'trace_file') and self.trace_file:
            self.save_trace(self.trace_file)
        print("Execution tracing stopped")
    
    def save_trace(self, filename: str):
        """Save execution trace to file"""
        try:
            trace_data = {
                'events': [asdict(event) for event in self.trace_buffer],
                'metadata': {
                    'total_events': len(self.trace_buffer),
                    'start_time': self.trace_buffer[0].timestamp if self.trace_buffer else 0,
                    'end_time': self.trace_buffer[-1].timestamp if self.trace_buffer else 0
                }
            }
            
            with open(filename, 'w') as f:
                json.dump(trace_data, f, indent=2)
            
            print(f"Trace saved to {filename}")
            
        except Exception as e:
            print(f"Failed to save trace: {e}")
    
    def analyze_race_conditions(self) -> List[Dict]:
        """Analyze trace for race conditions"""
        race_conditions = []
        
        # Simple race condition detection based on memory access patterns
        memory_accesses = {}
        
        for event in self.trace_buffer:
            if event.event_type == "memory_write":
                addr = event.memory_accessed[0] if event.memory_accessed else 0
                if addr in memory_accesses:
                    # Check if another thread accessed the same memory
                    last_access = memory_accesses[addr]
                    if last_access['thread_id'] != event.thread_id:
                        race_conditions.append({
                            'address': addr,
                            'thread1': last_access['thread_id'],
                            'thread2': event.thread_id,
                            'cycle1': last_access['cycle'],
                            'cycle2': event.cycle,
                            'type': 'write-write'
                        })
                
                memory_accesses[addr] = {
                    'thread_id': event.thread_id,
                    'cycle': event.cycle,
                    'type': 'write'
                }
        
        self.race_conditions = race_conditions
        return race_conditions
    
    def analyze_deadlocks(self) -> List[Dict]:
        """Analyze trace for deadlocks"""
        deadlocks = []
        
        # Simple deadlock detection based on lock acquisition patterns
        locks = {}
        waiting_threads = {}
        
        for event in self.trace_buffer:
            if "lock" in event.instruction.lower():
                thread_id = event.thread_id
                lock_addr = event.memory_accessed[0] if event.memory_accessed else 0
                
                if "acquire" in event.instruction.lower():
                    if lock_addr in locks:
                        # Thread is waiting for a lock held by another thread
                        waiting_threads[thread_id] = {
                            'waiting_for': lock_addr,
                            'held_by': locks[lock_addr],
                            'cycle': event.cycle
                        }
                    else:
                        locks[lock_addr] = thread_id
                
                elif "release" in event.instruction.lower():
                    if lock_addr in locks and locks[lock_addr] == thread_id:
                        del locks[lock_addr]
        
        # Check for circular wait conditions
        for thread_id, wait_info in waiting_threads.items():
            if self._has_circular_wait(thread_id, waiting_threads, locks):
                deadlocks.append({
                    'threads': list(waiting_threads.keys()),
                    'locks': list(locks.keys()),
                    'type': 'circular_wait'
                })
        
        self.deadlocks = deadlocks
        return deadlocks
    
    def _has_circular_wait(self, thread_id: int, waiting_threads: Dict, locks: Dict) -> bool:
        """Check for circular wait condition"""
        visited = set()
        current = thread_id
        
        while current in waiting_threads and current not in visited:
            visited.add(current)
            current = waiting_threads[current]['held_by']
            
            if current == thread_id:
                return True
        
        return False
    
    def start_performance_profiling(self):
        """Start performance profiling"""
        self.performance_profiler = {
            'start_time': time.time(),
            'cycles': 0,
            'instructions': 0,
            'cache_hits': 0,
            'cache_misses': 0,
            'branches': 0,
            'mispredictions': 0,
            'memory_accesses': 0
        }
        print("Performance profiling started")
    
    def stop_performance_profiling(self) -> Dict:
        """Stop performance profiling and return results"""
        if not self.performance_profiler:
            return {}
        
        end_time = time.time()
        duration = end_time - self.performance_profiler['start_time']
        
        # Calculate performance metrics
        ipc = (self.performance_profiler['instructions'] / 
               self.performance_profiler['cycles']) if self.performance_profiler['cycles'] > 0 else 0
        
        cache_hit_rate = (self.performance_profiler['cache_hits'] / 
                         (self.performance_profiler['cache_hits'] + self.performance_profiler['cache_misses'])
                         ) if (self.performance_profiler['cache_hits'] + self.performance_profiler['cache_misses']) > 0 else 0
        
        branch_misprediction_rate = (self.performance_profiler['mispredictions'] / 
                                   self.performance_profiler['branches']) if self.performance_profiler['branches'] > 0 else 0
        
        results = {
            'duration': duration,
            'cycles': self.performance_profiler['cycles'],
            'instructions': self.performance_profiler['instructions'],
            'ipc': ipc,
            'cache_hit_rate': cache_hit_rate,
            'branch_misprediction_rate': branch_misprediction_rate,
            'memory_bandwidth': self.performance_profiler['memory_accesses'] / duration
        }
        
        print("Performance profiling stopped")
        print(f"Results: {results}")
        
        return results
    
    def start_security_monitoring(self):
        """Start security monitoring"""
        self.security_monitor = {
            'start_time': time.time(),
            'privilege_escalations': 0,
            'memory_violations': 0,
            'illegal_instructions': 0,
            'buffer_overflows': 0,
            'injection_attempts': 0
        }
        print("Security monitoring started")
    
    def stop_security_monitoring(self) -> Dict:
        """Stop security monitoring and return results"""
        if not self.security_monitor:
            return {}
        
        end_time = time.time()
        duration = end_time - self.security_monitor['start_time']
        
        results = {
            'duration': duration,
            'threats_detected': sum([
                self.security_monitor['privilege_escalations'],
                self.security_monitor['memory_violations'],
                self.security_monitor['illegal_instructions'],
                self.security_monitor['buffer_overflows'],
                self.security_monitor['injection_attempts']
            ]),
            'threats_per_second': sum([
                self.security_monitor['privilege_escalations'],
                self.security_monitor['memory_violations'],
                self.security_monitor['illegal_instructions'],
                self.security_monitor['buffer_overflows'],
                self.security_monitor['injection_attempts']
            ]) / duration if duration > 0 else 0,
            'details': self.security_monitor.copy()
        }
        
        print("Security monitoring stopped")
        print(f"Security report: {results}")
        
        return results
    
    def generate_debug_report(self, filename: str = None):
        """Generate comprehensive debug report"""
        if filename is None:
            filename = f"debug_report_{int(time.time())}.json"
        
        report = {
            'timestamp': time.time(),
            'debug_mode': self.debug_mode.value,
            'breakpoints': {str(addr): asdict(bp) for addr, bp in self.breakpoints.items()},
            'execution_history_length': len(self.execution_history),
            'trace_events': len(self.trace_buffer),
            'state_snapshots': list(self.state_snapshots.keys()),
            'race_conditions': self.race_conditions,
            'deadlocks': self.deadlocks,
            'performance_profiler': self.performance_profiler,
            'security_monitor': self.security_monitor,
            'threads': self.threads,
            'memory_map': self.get_memory_map()
        }
        
        try:
            with open(filename, 'w') as f:
                json.dump(report, f, indent=2)
            print(f"Debug report saved to {filename}")
        except Exception as e:
            print(f"Failed to save debug report: {e}")
    
    def visualize_execution_trace(self, filename: str = None):
        """Generate visualization of execution trace"""
        if not self.trace_buffer:
            print("No trace data available")
            return
        
        if filename is None:
            filename = f"execution_trace_{int(time.time())}.png"
        
        try:
            # Extract data for visualization
            cycles = [event.cycle for event in self.trace_buffer]
            pcs = [event.pc for event in self.trace_buffer]
            instruction_types = [event.event_type for event in self.trace_buffer]
            
            # Create visualization
            fig, axes = plt.subplots(2, 2, figsize=(15, 10))
            fig.suptitle('AlphaAHB V5 Execution Trace Analysis', fontsize=16)
            
            # PC over time
            axes[0, 0].plot(cycles, pcs, 'b-', alpha=0.7)
            axes[0, 0].set_title('Program Counter Over Time')
            axes[0, 0].set_xlabel('Cycle')
            axes[0, 0].set_ylabel('PC')
            axes[0, 0].grid(True, alpha=0.3)
            
            # Instruction type distribution
            type_counts = {}
            for inst_type in instruction_types:
                type_counts[inst_type] = type_counts.get(inst_type, 0) + 1
            
            axes[0, 1].pie(type_counts.values(), labels=type_counts.keys(), autopct='%1.1f%%')
            axes[0, 1].set_title('Instruction Type Distribution')
            
            # Memory access pattern
            memory_accesses = [event.memory_accessed for event in self.trace_buffer if event.memory_accessed]
            if memory_accesses:
                mem_addrs = [addr for access in memory_accesses for addr in access]
                axes[1, 0].hist(mem_addrs, bins=50, alpha=0.7)
                axes[1, 0].set_title('Memory Access Pattern')
                axes[1, 0].set_xlabel('Memory Address')
                axes[1, 0].set_ylabel('Access Count')
            
            # Performance over time
            if len(cycles) > 100:
                window_size = len(cycles) // 100
                windowed_cycles = [cycles[i:i+window_size] for i in range(0, len(cycles), window_size)]
                windowed_pcs = [pcs[i:i+window_size] for i in range(0, len(pcs), window_size)]
                
                avg_cycles = [np.mean(window) for window in windowed_cycles]
                avg_pcs = [np.mean(window) for window in windowed_pcs]
                
                axes[1, 1].plot(avg_cycles, avg_pcs, 'r-', linewidth=2)
                axes[1, 1].set_title('Performance Over Time (Averaged)')
                axes[1, 1].set_xlabel('Cycle Window')
                axes[1, 1].set_ylabel('Average PC')
                axes[1, 1].grid(True, alpha=0.3)
            
            plt.tight_layout()
            plt.savefig(filename, dpi=300, bbox_inches='tight')
            plt.close()
            
            print(f"Execution trace visualization saved to {filename}")
            
        except Exception as e:
            print(f"Failed to generate visualization: {e}")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='AlphaAHB V5 Debugger')
    parser.add_argument('-t', '--target', default='localhost', help='Target host')
    parser.add_argument('-p', '--port', type=int, default=1234, help='Target port')
    parser.add_argument('-i', '--interactive', action='store_true', help='Interactive mode')
    
    args = parser.parse_args()
    
    debugger = AlphaAHBDebugger(target_host=args.target, target_port=args.port)
    
    if debugger.connect():
        if args.interactive:
            debugger.run_interactive()
        else:
            print("Connected to target. Use -i for interactive mode.")
        
        debugger.disconnect()
    else:
        print("Failed to connect to target")
        sys.exit(1)

if __name__ == '__main__':
    main()
