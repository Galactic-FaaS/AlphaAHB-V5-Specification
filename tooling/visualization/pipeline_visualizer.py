#!/usr/bin/env python3
"""
AlphaAHB V5 Pipeline Visualizer
Developed and Maintained by GLCTC Corp.

Advanced visualization tools for AlphaAHB V5 pipeline analysis, memory hierarchy,
and performance monitoring with interactive real-time displays.
"""

import sys
import os
import argparse
import json
import time
import threading
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass
from enum import Enum
import tkinter as tk
from tkinter import ttk, messagebox, filedialog
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import numpy as np
import seaborn as sns

class PipelineStage(Enum):
    """Pipeline stage enumeration"""
    FETCH = "Fetch"
    DECODE = "Decode"
    RENAME = "Rename"
    DISPATCH = "Dispatch"
    ISSUE = "Issue"
    EXECUTE = "Execute"
    WRITEBACK = "Writeback"
    COMMIT = "Commit"
    RETIRE = "Retire"

@dataclass
class Instruction:
    """Instruction representation for visualization"""
    pc: int
    mnemonic: str
    operands: List[str]
    stage: PipelineStage
    cycle: int
    stall_reason: Optional[str] = None
    hazard_type: Optional[str] = None

@dataclass
class PipelineState:
    """Pipeline state representation"""
    cycle: int
    instructions: List[Instruction]
    stalls: int
    hazards: int
    throughput: float

class AlphaAHBPipelineVisualizer:
    """Main pipeline visualizer class"""
    
    def __init__(self):
        self.pipeline_stages = list(PipelineStage)
        self.current_cycle = 0
        self.pipeline_data = []
        self.performance_data = {
            'cycles': [],
            'throughput': [],
            'stalls': [],
            'hazards': []
        }
        self.memory_data = {
            'l1_icache_hits': [],
            'l1_icache_misses': [],
            'l1_dcache_hits': [],
            'l1_dcache_misses': [],
            'l2_cache_hits': [],
            'l2_cache_misses': []
        }
        
        # Initialize GUI
        self.root = tk.Tk()
        self.root.title("AlphaAHB V5 Pipeline Visualizer")
        self.root.geometry("1400x900")
        
        self.setup_gui()
        
    def setup_gui(self):
        """Setup the GUI components"""
        # Create main notebook for tabs
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Pipeline Visualization Tab
        self.pipeline_frame = ttk.Frame(self.notebook)
        self.notebook.add(self.pipeline_frame, text="Pipeline Visualization")
        self.setup_pipeline_tab()
        
        # Memory Hierarchy Tab
        self.memory_frame = ttk.Frame(self.notebook)
        self.notebook.add(self.memory_frame, text="Memory Hierarchy")
        self.setup_memory_tab()
        
        # Performance Analysis Tab
        self.performance_frame = ttk.Frame(self.notebook)
        self.notebook.add(self.performance_frame, text="Performance Analysis")
        self.setup_performance_tab()
        
        # Control Panel
        self.setup_control_panel()
        
    def setup_pipeline_tab(self):
        """Setup pipeline visualization tab"""
        # Create pipeline diagram
        self.pipeline_fig, self.pipeline_ax = plt.subplots(figsize=(12, 6))
        self.pipeline_canvas = FigureCanvasTkAgg(self.pipeline_fig, self.pipeline_frame)
        self.pipeline_canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        # Pipeline stage labels
        self.pipeline_ax.set_xlim(0, len(self.pipeline_stages))
        self.pipeline_ax.set_ylim(0, 10)
        self.pipeline_ax.set_xticks(range(len(self.pipeline_stages)))
        self.pipeline_ax.set_xticklabels([stage.value for stage in self.pipeline_stages])
        self.pipeline_ax.set_ylabel("Instruction Position")
        self.pipeline_ax.set_title("AlphaAHB V5 Pipeline Execution")
        
        # Create instruction boxes
        self.instruction_boxes = {}
        for i, stage in enumerate(self.pipeline_stages):
            for j in range(10):
                box = plt.Rectangle((i, j), 0.8, 0.8, 
                                  facecolor='lightgray', edgecolor='black', alpha=0.3)
                self.pipeline_ax.add_patch(box)
                self.instruction_boxes[(i, j)] = box
        
        self.pipeline_ax.grid(True, alpha=0.3)
        
    def setup_memory_tab(self):
        """Setup memory hierarchy visualization tab"""
        # Create memory hierarchy diagram
        self.memory_fig, self.memory_ax = plt.subplots(figsize=(10, 8))
        self.memory_canvas = FigureCanvasTkAgg(self.memory_fig, self.memory_frame)
        self.memory_canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        # Memory hierarchy levels
        memory_levels = ['L1 I-Cache', 'L1 D-Cache', 'L2 Cache', 'L3 Cache', 'Main Memory']
        memory_sizes = [32, 32, 256, 2048, 16384]  # KB
        memory_latencies = [1, 1, 4, 12, 100]  # cycles
        
        y_pos = np.arange(len(memory_levels))
        
        # Create bars for memory hierarchy
        bars = self.memory_ax.barh(y_pos, memory_sizes, color=['red', 'orange', 'yellow', 'green', 'blue'])
        self.memory_ax.set_yticks(y_pos)
        self.memory_ax.set_yticklabels(memory_levels)
        self.memory_ax.set_xlabel('Size (KB)')
        self.memory_ax.set_title('AlphaAHB V5 Memory Hierarchy')
        
        # Add latency annotations
        for i, (bar, latency) in enumerate(zip(bars, memory_latencies)):
            self.memory_ax.text(bar.get_width() + 50, bar.get_y() + bar.get_height()/2, 
                              f'{latency} cycles', va='center')
        
        # Cache hit/miss visualization
        self.cache_fig, self.cache_ax = plt.subplots(figsize=(10, 4))
        self.cache_canvas = FigureCanvasTkAgg(self.cache_fig, self.memory_frame)
        self.cache_canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        self.cache_ax.set_title('Cache Performance Over Time')
        self.cache_ax.set_xlabel('Cycle')
        self.cache_ax.set_ylabel('Hit Rate (%)')
        
    def setup_performance_tab(self):
        """Setup performance analysis tab"""
        # Create performance metrics
        self.perf_fig, self.perf_axes = plt.subplots(2, 2, figsize=(12, 8))
        self.perf_canvas = FigureCanvasTkAgg(self.perf_fig, self.performance_frame)
        self.perf_canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True)
        
        # Throughput plot
        self.perf_axes[0, 0].set_title('Instructions Per Cycle (IPC)')
        self.perf_axes[0, 0].set_xlabel('Cycle')
        self.perf_axes[0, 0].set_ylabel('IPC')
        
        # Stall analysis
        self.perf_axes[0, 1].set_title('Pipeline Stalls')
        self.perf_axes[0, 1].set_xlabel('Cycle')
        self.perf_axes[0, 1].set_ylabel('Stalls')
        
        # Hazard analysis
        self.perf_axes[1, 0].set_title('Hazard Types')
        self.perf_axes[1, 0].set_xlabel('Cycle')
        self.perf_axes[1, 0].set_ylabel('Hazards')
        
        # Power consumption
        self.perf_axes[1, 1].set_title('Power Consumption')
        self.perf_axes[1, 1].set_xlabel('Cycle')
        self.perf_axes[1, 1].set_ylabel('Power (W)')
        
    def setup_control_panel(self):
        """Setup control panel"""
        control_frame = ttk.Frame(self.root)
        control_frame.pack(fill=tk.X, padx=10, pady=5)
        
        # Control buttons
        ttk.Button(control_frame, text="Load Data", command=self.load_data).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="Start Animation", command=self.start_animation).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="Stop Animation", command=self.stop_animation).pack(side=tk.LEFT, padx=5)
        ttk.Button(control_frame, text="Export Report", command=self.export_report).pack(side=tk.LEFT, padx=5)
        
        # Speed control
        ttk.Label(control_frame, text="Speed:").pack(side=tk.LEFT, padx=(20, 5))
        self.speed_var = tk.DoubleVar(value=1.0)
        speed_scale = ttk.Scale(control_frame, from_=0.1, to=5.0, variable=self.speed_var, orient=tk.HORIZONTAL)
        speed_scale.pack(side=tk.LEFT, padx=5)
        
        # Cycle display
        self.cycle_label = ttk.Label(control_frame, text="Cycle: 0")
        self.cycle_label.pack(side=tk.RIGHT, padx=5)
        
    def load_data(self):
        """Load simulation data"""
        filename = filedialog.askopenfilename(
            title="Load Simulation Data",
            filetypes=[("JSON files", "*.json"), ("All files", "*.*")]
        )
        
        if filename:
            try:
                with open(filename, 'r') as f:
                    data = json.load(f)
                self.process_simulation_data(data)
                messagebox.showinfo("Success", f"Loaded data from {filename}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to load data: {e}")
    
    def process_simulation_data(self, data: Dict):
        """Process simulation data for visualization"""
        self.pipeline_data = data.get('pipeline_data', [])
        self.performance_data = data.get('performance_data', {})
        self.memory_data = data.get('memory_data', {})
        
        # Update visualizations
        self.update_pipeline_visualization()
        self.update_memory_visualization()
        self.update_performance_visualization()
    
    def update_pipeline_visualization(self):
        """Update pipeline visualization"""
        self.pipeline_ax.clear()
        
        # Redraw pipeline stages
        for i, stage in enumerate(self.pipeline_stages):
            for j in range(10):
                box = plt.Rectangle((i, j), 0.8, 0.8, 
                                  facecolor='lightgray', edgecolor='black', alpha=0.3)
                self.pipeline_ax.add_patch(box)
        
        # Draw current instructions
        for instruction in self.pipeline_data:
            stage_idx = self.pipeline_stages.index(instruction.stage)
            # Color based on instruction type
            color = self.get_instruction_color(instruction)
            box = plt.Rectangle((stage_idx, instruction.cycle % 10), 0.8, 0.8, 
                              facecolor=color, edgecolor='black', alpha=0.8)
            self.pipeline_ax.add_patch(box)
            
            # Add instruction text
            self.pipeline_ax.text(stage_idx + 0.4, instruction.cycle % 10 + 0.4, 
                                instruction.mnemonic, ha='center', va='center', fontsize=8)
        
        self.pipeline_ax.set_xlim(0, len(self.pipeline_stages))
        self.pipeline_ax.set_ylim(0, 10)
        self.pipeline_ax.set_xticks(range(len(self.pipeline_stages)))
        self.pipeline_ax.set_xticklabels([stage.value for stage in self.pipeline_stages])
        self.pipeline_ax.set_ylabel("Instruction Position")
        self.pipeline_ax.set_title("AlphaAHB V5 Pipeline Execution")
        self.pipeline_ax.grid(True, alpha=0.3)
        
        self.pipeline_canvas.draw()
    
    def get_instruction_color(self, instruction: Instruction) -> str:
        """Get color for instruction based on type"""
        if instruction.stall_reason:
            return 'red'
        elif instruction.hazard_type:
            return 'orange'
        elif 'F' in instruction.mnemonic:
            return 'blue'  # Floating-point
        elif 'V' in instruction.mnemonic:
            return 'green'  # Vector
        elif 'AI' in instruction.mnemonic:
            return 'purple'  # AI/ML
        else:
            return 'lightblue'  # Basic
    
    def update_memory_visualization(self):
        """Update memory hierarchy visualization"""
        # Update cache performance plot
        if self.memory_data:
            cycles = list(range(len(self.memory_data.get('l1_icache_hits', []))))
            l1_icache_hits = self.memory_data.get('l1_icache_hits', [])
            l1_icache_misses = self.memory_data.get('l1_icache_misses', [])
            
            if cycles and l1_icache_hits and l1_icache_misses:
                hit_rates = []
                for hits, misses in zip(l1_icache_hits, l1_icache_misses):
                    total = hits + misses
                    hit_rate = (hits / total * 100) if total > 0 else 0
                    hit_rates.append(hit_rate)
                
                self.cache_ax.clear()
                self.cache_ax.plot(cycles, hit_rates, 'b-', label='L1 I-Cache Hit Rate')
                self.cache_ax.set_title('Cache Performance Over Time')
                self.cache_ax.set_xlabel('Cycle')
                self.cache_ax.set_ylabel('Hit Rate (%)')
                self.cache_ax.legend()
                self.cache_ax.grid(True, alpha=0.3)
                
                self.cache_canvas.draw()
    
    def update_performance_visualization(self):
        """Update performance visualization"""
        if self.performance_data:
            cycles = self.performance_data.get('cycles', [])
            throughput = self.performance_data.get('throughput', [])
            stalls = self.performance_data.get('stalls', [])
            hazards = self.performance_data.get('hazards', [])
            
            if cycles and throughput:
                # IPC plot
                self.perf_axes[0, 0].clear()
                self.perf_axes[0, 0].plot(cycles, throughput, 'b-')
                self.perf_axes[0, 0].set_title('Instructions Per Cycle (IPC)')
                self.perf_axes[0, 0].set_xlabel('Cycle')
                self.perf_axes[0, 0].set_ylabel('IPC')
                self.perf_axes[0, 0].grid(True, alpha=0.3)
                
                # Stalls plot
                self.perf_axes[0, 1].clear()
                self.perf_axes[0, 1].plot(cycles, stalls, 'r-')
                self.perf_axes[0, 1].set_title('Pipeline Stalls')
                self.perf_axes[0, 1].set_xlabel('Cycle')
                self.perf_axes[0, 1].set_ylabel('Stalls')
                self.perf_axes[0, 1].grid(True, alpha=0.3)
                
                # Hazards plot
                self.perf_axes[1, 0].clear()
                self.perf_axes[1, 0].plot(cycles, hazards, 'orange')
                self.perf_axes[1, 0].set_title('Hazard Types')
                self.perf_axes[1, 0].set_xlabel('Cycle')
                self.perf_axes[1, 0].set_ylabel('Hazards')
                self.perf_axes[1, 0].grid(True, alpha=0.3)
                
                self.perf_canvas.draw()
    
    def start_animation(self):
        """Start pipeline animation"""
        self.animation_running = True
        self.animate_pipeline()
    
    def stop_animation(self):
        """Stop pipeline animation"""
        self.animation_running = False
    
    def animate_pipeline(self):
        """Animate pipeline execution"""
        if not self.animation_running:
            return
        
        # Update cycle display
        self.cycle_label.config(text=f"Cycle: {self.current_cycle}")
        
        # Update visualizations
        self.update_pipeline_visualization()
        self.update_memory_visualization()
        self.update_performance_visualization()
        
        # Schedule next update
        delay = int(1000 / self.speed_var.get())  # Convert to milliseconds
        self.root.after(delay, self.animate_pipeline)
        
        self.current_cycle += 1
    
    def export_report(self):
        """Export visualization report"""
        filename = filedialog.asksaveasfilename(
            title="Export Report",
            defaultextension=".pdf",
            filetypes=[("PDF files", "*.pdf"), ("PNG files", "*.png"), ("All files", "*.*")]
        )
        
        if filename:
            try:
                if filename.endswith('.pdf'):
                    self.pipeline_fig.savefig(filename, format='pdf', bbox_inches='tight')
                elif filename.endswith('.png'):
                    self.pipeline_fig.savefig(filename, format='png', dpi=300, bbox_inches='tight')
                messagebox.showinfo("Success", f"Report exported to {filename}")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to export report: {e}")
    
    def run(self):
        """Run the visualizer"""
        self.root.mainloop()

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='AlphaAHB V5 Pipeline Visualizer')
    parser.add_argument('-d', '--data', help='Simulation data file')
    parser.add_argument('-f', '--format', choices=['json', 'csv'], default='json', help='Data format')
    
    args = parser.parse_args()
    
    visualizer = AlphaAHBPipelineVisualizer()
    
    if args.data:
        visualizer.load_data()
    
    visualizer.run()

if __name__ == '__main__':
    main()
