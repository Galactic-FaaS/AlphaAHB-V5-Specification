#!/usr/bin/env python3
"""
AlphaAHB V5 IDE Integration Tools
Developed and Maintained by GLCTC Corp.

Integration tools for popular IDEs and development environments.
"""

import sys
import os
import json
from typing import Dict, List
from pathlib import Path

class IDEIntegration:
    """IDE integration utilities"""
    
    def __init__(self):
        self.ide_configs = {}
        self._initialize_configs()
    
    def _initialize_configs(self):
        """Initialize IDE configurations"""
        self.ide_configs = {
            'vscode': {
                'extensions': ['alphaahb-v5', 'assembly', 'hexdump'],
                'settings': {
                    'files.associations': {
                        '*.s': 'assembly',
                        '*.asm': 'assembly'
                    }
                }
            },
            'vim': {
                'syntax': 'alphaahb.vim',
                'ftdetect': 'alphaahb.vim'
            },
            'emacs': {
                'mode': 'alphaahb-mode.el'
            }
        }
    
    def generate_vscode_config(self, project_dir: str):
        """Generate VS Code configuration"""
        vscode_dir = Path(project_dir) / '.vscode'
        vscode_dir.mkdir(exist_ok=True)
        
        # Settings
        settings = {
            "files.associations": {
                "*.s": "assembly",
                "*.asm": "assembly"
            },
            "editor.tabSize": 4,
            "editor.insertSpaces": False
        }
        
        with open(vscode_dir / 'settings.json', 'w') as f:
            json.dump(settings, f, indent=2)
        
        # Tasks
        tasks = {
            "version": "2.0.0",
            "tasks": [
                {
                    "label": "Build AlphaAHB V5",
                    "type": "shell",
                    "command": "make",
                    "group": "build"
                },
                {
                    "label": "Simulate",
                    "type": "shell",
                    "command": "alphaahb-sim",
                    "group": "test"
                }
            ]
        }
        
        with open(vscode_dir / 'tasks.json', 'w') as f:
            json.dump(tasks, f, indent=2)
        
        print(f"VS Code configuration generated in {vscode_dir}")

def main():
    """Main function"""
    integration = IDEIntegration()
    
    if len(sys.argv) > 1:
        project_dir = sys.argv[1]
        integration.generate_vscode_config(project_dir)
    else:
        print("Usage: python ide_integration.py <project_directory>")

if __name__ == '__main__':
    main()
