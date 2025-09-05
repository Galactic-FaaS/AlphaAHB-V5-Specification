#!/usr/bin/env python3
"""
AlphaAHB V5 Security Analyzer
Developed and Maintained by GLCTC Corp.

Comprehensive security analysis, vulnerability detection, and threat assessment
for AlphaAHB V5 ISA code and systems.
"""

import sys
import os
import argparse
import json
import re
import hashlib
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass, asdict
from enum import Enum
import ast
import subprocess

class SecurityThreat(Enum):
    """Security threat enumeration"""
    BUFFER_OVERFLOW = "buffer_overflow"
    STACK_OVERFLOW = "stack_overflow"
    HEAP_OVERFLOW = "heap_overflow"
    FORMAT_STRING = "format_string"
    INTEGER_OVERFLOW = "integer_overflow"
    RACE_CONDITION = "race_condition"
    DEADLOCK = "deadlock"
    PRIVILEGE_ESCALATION = "privilege_escalation"
    MEMORY_LEAK = "memory_leak"
    UAF = "use_after_free"
    DOUBLE_FREE = "double_free"
    INJECTION = "injection"
    SIDE_CHANNEL = "side_channel"
    SPECTRE = "spectre"
    MELTDOWN = "meltdown"

class Severity(Enum):
    """Severity level enumeration"""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFO = "info"

@dataclass
class SecurityVulnerability:
    """Security vulnerability representation"""
    threat_type: SecurityThreat
    severity: Severity
    location: str
    line_number: int
    description: str
    code_snippet: str
    cwe_id: str
    remediation: str
    confidence: float

@dataclass
class SecurityReport:
    """Security analysis report"""
    filename: str
    vulnerabilities: List[SecurityVulnerability]
    risk_score: float
    summary: Dict[str, int]
    recommendations: List[str]

class AlphaAHBSecurityAnalyzer:
    """Main security analyzer class"""
    
    def __init__(self):
        self.vulnerability_patterns = {}
        self.security_rules = {}
        self.known_vulnerabilities = {}
        
        # Initialize vulnerability patterns
        self._initialize_vulnerability_patterns()
        
        # Initialize security rules
        self._initialize_security_rules()
        
        # Initialize CWE mappings
        self._initialize_cwe_mappings()
    
    def _initialize_vulnerability_patterns(self):
        """Initialize vulnerability detection patterns"""
        self.vulnerability_patterns = {
            SecurityThreat.BUFFER_OVERFLOW: [
                r'strcpy\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)',
                r'strcat\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)',
                r'sprintf\s*\(\s*(\w+)\s*,\s*[^,]+,\s*(\w+)\s*\)',
                r'gets\s*\(\s*(\w+)\s*\)',
                r'(\w+)\s*\[\s*(\w+)\s*\]\s*=\s*[^;]+;\s*#.*overflow',
                r'LDR\s+R(\d+)\s*,\s*\[R(\d+)\s*,\s*#(\d+)\]\s*#.*buffer',
            ],
            SecurityThreat.STACK_OVERFLOW: [
                r'char\s+(\w+)\s*\[\s*(\d+)\s*\]\s*;',
                r'(\w+)\s*\[\s*(\w+)\s*\]\s*=\s*[^;]+;\s*#.*stack',
                r'PUSH\s+R(\d+)\s*#.*stack',
            ],
            SecurityThreat.HEAP_OVERFLOW: [
                r'malloc\s*\(\s*(\w+)\s*\)',
                r'calloc\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)',
                r'realloc\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)',
                r'free\s*\(\s*(\w+)\s*\)',
            ],
            SecurityThreat.FORMAT_STRING: [
                r'printf\s*\(\s*(\w+)\s*\)',
                r'fprintf\s*\(\s*[^,]+,\s*(\w+)\s*\)',
                r'sprintf\s*\(\s*[^,]+,\s*(\w+)\s*\)',
            ],
            SecurityThreat.INTEGER_OVERFLOW: [
                r'(\w+)\s*\+\s*(\w+)\s*;',
                r'(\w+)\s*\*\s*(\w+)\s*;',
                r'ADD\s+R(\d+)\s*,\s*R(\d+)\s*,\s*R(\d+)',
                r'MUL\s+R(\d+)\s*,\s*R(\d+)\s*,\s*R(\d+)',
            ],
            SecurityThreat.RACE_CONDITION: [
                r'pthread_mutex_lock\s*\(\s*(\w+)\s*\)',
                r'pthread_mutex_unlock\s*\(\s*(\w+)\s*\)',
                r'LOCK\s+(\w+)',
                r'UNLOCK\s+(\w+)',
            ],
            SecurityThreat.MEMORY_LEAK: [
                r'malloc\s*\(\s*[^)]+\s*\)\s*;',
                r'calloc\s*\(\s*[^)]+\s*\)\s*;',
                r'new\s+\w+\s*\([^)]*\)\s*;',
            ],
            SecurityThreat.UAF: [
                r'free\s*\(\s*(\w+)\s*\)\s*;.*\1',
                r'delete\s+(\w+)\s*;.*\1',
            ],
            SecurityThreat.INJECTION: [
                r'system\s*\(\s*(\w+)\s*\)',
                r'exec\s*\(\s*(\w+)\s*\)',
                r'eval\s*\(\s*(\w+)\s*\)',
                r'sql\s*=\s*[^;]+(\w+)\s*;',
            ],
            SecurityThreat.SIDE_CHANNEL: [
                r'if\s*\(\s*(\w+)\s*==\s*(\w+)\s*\)',
                r'CMP\s+R(\d+)\s*,\s*R(\d+)',
                r'JZ\s+(\w+)',
            ],
            SecurityThreat.SPECTRE: [
                r'if\s*\(\s*(\w+)\s*<\s*(\w+)\s*\)\s*{\s*(\w+)\s*\[\s*(\w+)\s*\]',
                r'JL\s+(\w+)\s*#.*spectre',
            ],
            SecurityThreat.MELTDOWN: [
                r'(\w+)\s*\[\s*(\w+)\s*\]\s*#.*meltdown',
                r'LDR\s+R(\d+)\s*,\s*\[R(\d+)\s*,\s*R(\d+)\s*\]\s*#.*meltdown',
            ]
        }
    
    def _initialize_security_rules(self):
        """Initialize security analysis rules"""
        self.security_rules = {
            'buffer_bounds_check': {
                'pattern': r'(\w+)\s*\[\s*(\w+)\s*\]',
                'check': 'bounds_check',
                'severity': Severity.HIGH
            },
            'null_pointer_check': {
                'pattern': r'(\w+)\s*=\s*NULL',
                'check': 'null_check',
                'severity': Severity.MEDIUM
            },
            'uninitialized_variable': {
                'pattern': r'(\w+)\s*;',
                'check': 'init_check',
                'severity': Severity.MEDIUM
            },
            'privilege_check': {
                'pattern': r'setuid\s*\(\s*(\w+)\s*\)',
                'check': 'privilege_check',
                'severity': Severity.CRITICAL
            },
            'crypto_weak': {
                'pattern': r'MD5\s*\(\s*(\w+)\s*\)',
                'check': 'crypto_check',
                'severity': Severity.HIGH
            }
        }
    
    def _initialize_cwe_mappings(self):
        """Initialize CWE (Common Weakness Enumeration) mappings"""
        self.cwe_mappings = {
            SecurityThreat.BUFFER_OVERFLOW: "CWE-120",
            SecurityThreat.STACK_OVERFLOW: "CWE-121",
            SecurityThreat.HEAP_OVERFLOW: "CWE-122",
            SecurityThreat.FORMAT_STRING: "CWE-134",
            SecurityThreat.INTEGER_OVERFLOW: "CWE-190",
            SecurityThreat.RACE_CONDITION: "CWE-362",
            SecurityThreat.DEADLOCK: "CWE-833",
            SecurityThreat.PRIVILEGE_ESCALATION: "CWE-269",
            SecurityThreat.MEMORY_LEAK: "CWE-401",
            SecurityThreat.UAF: "CWE-416",
            SecurityThreat.DOUBLE_FREE: "CWE-415",
            SecurityThreat.INJECTION: "CWE-94",
            SecurityThreat.SIDE_CHANNEL: "CWE-385",
            SecurityThreat.SPECTRE: "CWE-1037",
            SecurityThreat.MELTDOWN: "CWE-1037"
        }
    
    def analyze_code(self, filename: str, language: str = "c") -> SecurityReport:
        """Analyze code for security vulnerabilities"""
        with open(filename, 'r') as f:
            content = f.read()
        
        vulnerabilities = []
        
        # Analyze based on language
        if language == "c" or language == "cpp":
            vulnerabilities.extend(self._analyze_c_code(content, filename))
        elif language == "assembly":
            vulnerabilities.extend(self._analyze_assembly_code(content, filename))
        elif language == "rust":
            vulnerabilities.extend(self._analyze_rust_code(content, filename))
        
        # Calculate risk score
        risk_score = self._calculate_risk_score(vulnerabilities)
        
        # Generate summary
        summary = self._generate_summary(vulnerabilities)
        
        # Generate recommendations
        recommendations = self._generate_recommendations(vulnerabilities)
        
        return SecurityReport(
            filename=filename,
            vulnerabilities=vulnerabilities,
            risk_score=risk_score,
            summary=summary,
            recommendations=recommendations
        )
    
    def _analyze_c_code(self, content: str, filename: str) -> List[SecurityVulnerability]:
        """Analyze C/C++ code for vulnerabilities"""
        vulnerabilities = []
        lines = content.split('\n')
        
        for line_num, line in enumerate(lines, 1):
            line = line.strip()
            if not line or line.startswith('//') or line.startswith('/*'):
                continue
            
            # Check each vulnerability pattern
            for threat_type, patterns in self.vulnerability_patterns.items():
                for pattern in patterns:
                    matches = re.finditer(pattern, line, re.IGNORECASE)
                    for match in matches:
                        vulnerability = self._create_vulnerability(
                            threat_type, line_num, line, filename, match
                        )
                        if vulnerability:
                            vulnerabilities.append(vulnerability)
        
        return vulnerabilities
    
    def _analyze_assembly_code(self, content: str, filename: str) -> List[SecurityVulnerability]:
        """Analyze assembly code for vulnerabilities"""
        vulnerabilities = []
        lines = content.split('\n')
        
        for line_num, line in enumerate(lines, 1):
            line = line.strip()
            if not line or line.startswith('#') or line.startswith(';'):
                continue
            
            # Check assembly-specific patterns
            for threat_type, patterns in self.vulnerability_patterns.items():
                for pattern in patterns:
                    if re.search(pattern, line, re.IGNORECASE):
                        vulnerability = self._create_vulnerability(
                            threat_type, line_num, line, filename, None
                        )
                        if vulnerability:
                            vulnerabilities.append(vulnerability)
        
        return vulnerabilities
    
    def _analyze_rust_code(self, content: str, filename: str) -> List[SecurityVulnerability]:
        """Analyze Rust code for vulnerabilities"""
        vulnerabilities = []
        lines = content.split('\n')
        
        for line_num, line in enumerate(lines, 1):
            line = line.strip()
            if not line or line.startswith('//'):
                continue
            
            # Check Rust-specific patterns
            rust_patterns = {
                SecurityThreat.MEMORY_LEAK: [
                    r'Box::leak\s*\(\s*(\w+)\s*\)',
                    r'std::mem::forget\s*\(\s*(\w+)\s*\)',
                ],
                SecurityThreat.UNSAFE_CODE: [
                    r'unsafe\s*\{',
                    r'unsafe\s+fn\s+(\w+)',
                ]
            }
            
            for threat_type, patterns in rust_patterns.items():
                for pattern in patterns:
                    if re.search(pattern, line, re.IGNORECASE):
                        vulnerability = self._create_vulnerability(
                            threat_type, line_num, line, filename, None
                        )
                        if vulnerability:
                            vulnerabilities.append(vulnerability)
        
        return vulnerabilities
    
    def _create_vulnerability(self, threat_type: SecurityThreat, line_num: int, 
                            line: str, filename: str, match) -> Optional[SecurityVulnerability]:
        """Create vulnerability object from detection"""
        # Determine severity based on threat type
        severity_map = {
            SecurityThreat.BUFFER_OVERFLOW: Severity.CRITICAL,
            SecurityThreat.STACK_OVERFLOW: Severity.CRITICAL,
            SecurityThreat.HEAP_OVERFLOW: Severity.CRITICAL,
            SecurityThreat.FORMAT_STRING: Severity.HIGH,
            SecurityThreat.INTEGER_OVERFLOW: Severity.HIGH,
            SecurityThreat.RACE_CONDITION: Severity.MEDIUM,
            SecurityThreat.DEADLOCK: Severity.MEDIUM,
            SecurityThreat.PRIVILEGE_ESCALATION: Severity.CRITICAL,
            SecurityThreat.MEMORY_LEAK: Severity.MEDIUM,
            SecurityThreat.UAF: Severity.CRITICAL,
            SecurityThreat.DOUBLE_FREE: Severity.CRITICAL,
            SecurityThreat.INJECTION: Severity.CRITICAL,
            SecurityThreat.SIDE_CHANNEL: Severity.HIGH,
            SecurityThreat.SPECTRE: Severity.HIGH,
            SecurityThreat.MELTDOWN: Severity.HIGH
        }
        
        severity = severity_map.get(threat_type, Severity.MEDIUM)
        
        # Generate description
        description = self._generate_description(threat_type, line)
        
        # Generate remediation
        remediation = self._generate_remediation(threat_type)
        
        # Calculate confidence
        confidence = self._calculate_confidence(threat_type, line, match)
        
        return SecurityVulnerability(
            threat_type=threat_type,
            severity=severity,
            location=f"{filename}:{line_num}",
            line_number=line_num,
            description=description,
            code_snippet=line,
            cwe_id=self.cwe_mappings.get(threat_type, "CWE-000"),
            remediation=remediation,
            confidence=confidence
        )
    
    def _generate_description(self, threat_type: SecurityThreat, line: str) -> str:
        """Generate vulnerability description"""
        descriptions = {
            SecurityThreat.BUFFER_OVERFLOW: "Buffer overflow vulnerability detected. Data may be written beyond buffer boundaries.",
            SecurityThreat.STACK_OVERFLOW: "Stack overflow vulnerability detected. Local variables may overflow stack buffer.",
            SecurityThreat.HEAP_OVERFLOW: "Heap overflow vulnerability detected. Memory corruption possible.",
            SecurityThreat.FORMAT_STRING: "Format string vulnerability detected. Uncontrolled format string may lead to code execution.",
            SecurityThreat.INTEGER_OVERFLOW: "Integer overflow vulnerability detected. Arithmetic operation may overflow.",
            SecurityThreat.RACE_CONDITION: "Race condition vulnerability detected. Concurrent access may cause undefined behavior.",
            SecurityThreat.DEADLOCK: "Potential deadlock detected. Threads may wait indefinitely for resources.",
            SecurityThreat.PRIVILEGE_ESCALATION: "Privilege escalation vulnerability detected. Unauthorized privilege elevation possible.",
            SecurityThreat.MEMORY_LEAK: "Memory leak detected. Allocated memory not properly freed.",
            SecurityThreat.UAF: "Use-after-free vulnerability detected. Memory accessed after being freed.",
            SecurityThreat.DOUBLE_FREE: "Double free vulnerability detected. Memory freed multiple times.",
            SecurityThreat.INJECTION: "Code injection vulnerability detected. Uncontrolled input may execute arbitrary code.",
            SecurityThreat.SIDE_CHANNEL: "Side-channel vulnerability detected. Timing or power analysis may leak information.",
            SecurityThreat.SPECTRE: "Spectre vulnerability detected. Speculative execution may leak sensitive data.",
            SecurityThreat.MELTDOWN: "Meltdown vulnerability detected. Out-of-order execution may leak kernel data."
        }
        
        return descriptions.get(threat_type, "Security vulnerability detected.")
    
    def _generate_remediation(self, threat_type: SecurityThreat) -> str:
        """Generate remediation advice"""
        remediations = {
            SecurityThreat.BUFFER_OVERFLOW: "Use bounds-checked functions like strncpy, strncat, or snprintf. Validate input sizes.",
            SecurityThreat.STACK_OVERFLOW: "Increase stack size or use dynamic allocation. Implement stack canaries.",
            SecurityThreat.HEAP_OVERFLOW: "Validate array bounds and use safe memory management functions.",
            SecurityThreat.FORMAT_STRING: "Use format string literals or validate format strings. Avoid user-controlled format strings.",
            SecurityThreat.INTEGER_OVERFLOW: "Check for overflow before arithmetic operations. Use safe math libraries.",
            SecurityThreat.RACE_CONDITION: "Use proper synchronization primitives like mutexes or atomic operations.",
            SecurityThreat.DEADLOCK: "Implement deadlock prevention strategies like lock ordering or timeout mechanisms.",
            SecurityThreat.PRIVILEGE_ESCALATION: "Implement proper privilege checks and use principle of least privilege.",
            SecurityThreat.MEMORY_LEAK: "Ensure all allocated memory is properly freed. Use RAII or smart pointers.",
            SecurityThreat.UAF: "Set pointers to NULL after freeing. Use memory management tools to detect issues.",
            SecurityThreat.DOUBLE_FREE: "Set pointers to NULL after freeing. Use memory management tools to detect issues.",
            SecurityThreat.INJECTION: "Validate and sanitize all input. Use parameterized queries for databases.",
            SecurityThreat.SIDE_CHANNEL: "Use constant-time algorithms. Implement proper timing attack mitigations.",
            SecurityThreat.SPECTRE: "Use compiler mitigations like -mretpoline. Implement proper speculation barriers.",
            SecurityThreat.MELTDOWN: "Use CPU microcode updates. Implement proper memory isolation."
        }
        
        return remediations.get(threat_type, "Implement proper security controls.")
    
    def _calculate_confidence(self, threat_type: SecurityThreat, line: str, match) -> float:
        """Calculate detection confidence"""
        base_confidence = 0.7
        
        # Increase confidence for specific patterns
        if threat_type == SecurityThreat.BUFFER_OVERFLOW:
            if 'strcpy' in line or 'strcat' in line:
                base_confidence = 0.9
            elif 'gets' in line:
                base_confidence = 0.95
        
        elif threat_type == SecurityThreat.FORMAT_STRING:
            if 'printf' in line and not 'printf(' in line:
                base_confidence = 0.9
        
        elif threat_type == SecurityThreat.INJECTION:
            if 'system' in line or 'exec' in line:
                base_confidence = 0.9
        
        return min(base_confidence, 1.0)
    
    def _calculate_risk_score(self, vulnerabilities: List[SecurityVulnerability]) -> float:
        """Calculate overall risk score"""
        if not vulnerabilities:
            return 0.0
        
        severity_weights = {
            Severity.CRITICAL: 10,
            Severity.HIGH: 7,
            Severity.MEDIUM: 4,
            Severity.LOW: 2,
            Severity.INFO: 1
        }
        
        total_score = 0
        for vuln in vulnerabilities:
            weight = severity_weights.get(vuln.severity, 1)
            total_score += weight * vuln.confidence
        
        # Normalize to 0-100 scale
        max_possible_score = len(vulnerabilities) * 10
        risk_score = (total_score / max_possible_score) * 100 if max_possible_score > 0 else 0
        
        return min(risk_score, 100.0)
    
    def _generate_summary(self, vulnerabilities: List[SecurityVulnerability]) -> Dict[str, int]:
        """Generate vulnerability summary"""
        summary = {
            'total': len(vulnerabilities),
            'critical': 0,
            'high': 0,
            'medium': 0,
            'low': 0,
            'info': 0
        }
        
        for vuln in vulnerabilities:
            summary[vuln.severity.value] += 1
        
        return summary
    
    def _generate_recommendations(self, vulnerabilities: List[SecurityVulnerability]) -> List[str]:
        """Generate security recommendations"""
        recommendations = []
        
        # Count vulnerability types
        vuln_counts = {}
        for vuln in vulnerabilities:
            vuln_counts[vuln.threat_type] = vuln_counts.get(vuln.threat_type, 0) + 1
        
        # Generate recommendations based on findings
        if SecurityThreat.BUFFER_OVERFLOW in vuln_counts:
            recommendations.append("Implement comprehensive input validation and bounds checking")
        
        if SecurityThreat.RACE_CONDITION in vuln_counts:
            recommendations.append("Review and improve synchronization mechanisms")
        
        if SecurityThreat.MEMORY_LEAK in vuln_counts:
            recommendations.append("Implement proper memory management and leak detection")
        
        if SecurityThreat.INJECTION in vuln_counts:
            recommendations.append("Sanitize all user inputs and use parameterized queries")
        
        if SecurityThreat.SPECTRE in vuln_counts or SecurityThreat.MELTDOWN in vuln_counts:
            recommendations.append("Apply CPU microcode updates and compiler mitigations")
        
        # General recommendations
        recommendations.extend([
            "Implement static analysis in CI/CD pipeline",
            "Use memory safety tools like AddressSanitizer",
            "Regular security code reviews",
            "Keep dependencies updated",
            "Implement proper error handling"
        ])
        
        return recommendations
    
    def generate_security_report(self, report: SecurityReport, output_file: str = None):
        """Generate comprehensive security report"""
        if output_file is None:
            output_file = f"security_report_{report.filename.replace('/', '_')}.json"
        
        report_data = {
            'filename': report.filename,
            'risk_score': report.risk_score,
            'summary': report.summary,
            'vulnerabilities': [asdict(vuln) for vuln in report.vulnerabilities],
            'recommendations': report.recommendations,
            'timestamp': time.time()
        }
        
        with open(output_file, 'w') as f:
            json.dump(report_data, f, indent=2)
        
        print(f"Security report saved to {output_file}")
        
        # Generate markdown report
        md_file = output_file.replace('.json', '.md')
        self._generate_markdown_report(report, md_file)
    
    def _generate_markdown_report(self, report: SecurityReport, output_file: str):
        """Generate markdown security report"""
        md_content = f"""# Security Analysis Report

## File: {report.filename}

### Risk Score: {report.risk_score:.1f}/100

### Summary
- **Total Vulnerabilities**: {report.summary['total']}
- **Critical**: {report.summary['critical']}
- **High**: {report.summary['high']}
- **Medium**: {report.summary['medium']}
- **Low**: {report.summary['low']}
- **Info**: {report.summary['info']}

### Vulnerabilities

"""
        
        for vuln in report.vulnerabilities:
            md_content += f"""#### {vuln.threat_type.value.replace('_', ' ').title()} ({vuln.severity.value.upper()})
- **Location**: {vuln.location}
- **CWE**: {vuln.cwe_id}
- **Confidence**: {vuln.confidence:.1%}
- **Description**: {vuln.description}
- **Code**: `{vuln.code_snippet}`
- **Remediation**: {vuln.remediation}

"""
        
        md_content += "### Recommendations\n\n"
        for i, rec in enumerate(report.recommendations, 1):
            md_content += f"{i}. {rec}\n"
        
        with open(output_file, 'w') as f:
            f.write(md_content)
        
        print(f"Markdown report saved to {output_file}")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='AlphaAHB V5 Security Analyzer')
    parser.add_argument('file', help='File to analyze')
    parser.add_argument('-l', '--language', choices=['c', 'cpp', 'assembly', 'rust'], 
                       default='c', help='Programming language')
    parser.add_argument('-o', '--output', help='Output report file')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    analyzer = AlphaAHBSecurityAnalyzer()
    
    # Analyze file
    report = analyzer.analyze_code(args.file, args.language)
    
    # Print summary
    print(f"Security Analysis for {args.file}")
    print(f"Risk Score: {report.risk_score:.1f}/100")
    print(f"Vulnerabilities: {report.summary['total']}")
    print(f"  Critical: {report.summary['critical']}")
    print(f"  High: {report.summary['high']}")
    print(f"  Medium: {report.summary['medium']}")
    print(f"  Low: {report.summary['low']}")
    
    if args.verbose:
        print("\nDetailed Findings:")
        for vuln in report.vulnerabilities:
            print(f"  {vuln.threat_type.value} ({vuln.severity.value}) at {vuln.location}")
            print(f"    {vuln.description}")
            print(f"    Remediation: {vuln.remediation}")
    
    # Generate report
    analyzer.generate_security_report(report, args.output)

if __name__ == '__main__':
    main()
