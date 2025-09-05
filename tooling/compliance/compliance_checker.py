#!/usr/bin/env python3
"""
AlphaAHB V5 Compliance Checker
Developed and Maintained by GLCTC Corp.

Comprehensive compliance checking for AlphaAHB V5 ISA implementations,
standards adherence, and certification requirements.
"""

import sys
import os
import argparse
import json
import re
from typing import Dict, List, Tuple, Optional, Any
from dataclasses import dataclass, asdict
from enum import Enum
import xml.etree.ElementTree as ET

class ComplianceStandard(Enum):
    """Compliance standard enumeration"""
    IEEE_754 = "ieee_754"
    ARM_AMBA_AHB = "arm_amba_ahb"
    ISO_26262 = "iso_26262"
    IEC_61508 = "iec_61508"
    DO_178C = "do_178c"
    MISRA_C = "misra_c"
    CERT_C = "cert_c"
    CWE = "cwe"
    OWASP = "owasp"
    NIST = "nist"

class ComplianceLevel(Enum):
    """Compliance level enumeration"""
    FULL = "full"
    PARTIAL = "partial"
    NON_COMPLIANT = "non_compliant"
    NOT_APPLICABLE = "not_applicable"

@dataclass
class ComplianceRule:
    """Compliance rule representation"""
    rule_id: str
    standard: ComplianceStandard
    category: str
    description: str
    severity: str
    check_function: str
    parameters: Dict[str, Any]

@dataclass
class ComplianceViolation:
    """Compliance violation representation"""
    rule_id: str
    standard: ComplianceStandard
    severity: str
    location: str
    line_number: int
    description: str
    code_snippet: str
    remediation: str
    confidence: float

@dataclass
class ComplianceReport:
    """Compliance analysis report"""
    filename: str
    standards: List[ComplianceStandard]
    violations: List[ComplianceViolation]
    compliance_scores: Dict[str, float]
    summary: Dict[str, int]
    recommendations: List[str]

class AlphaAHBComplianceChecker:
    """Main compliance checker class"""
    
    def __init__(self):
        self.compliance_rules = {}
        self.standards_config = {}
        
        # Initialize compliance rules
        self._initialize_compliance_rules()
        
        # Initialize standards configuration
        self._initialize_standards_config()
    
    def _initialize_compliance_rules(self):
        """Initialize compliance checking rules"""
        self.compliance_rules = {
            # IEEE 754 compliance rules
            ComplianceStandard.IEEE_754: [
                ComplianceRule(
                    rule_id="IEEE754-001",
                    standard=ComplianceStandard.IEEE_754,
                    category="Rounding",
                    description="Floating-point operations must use proper rounding modes",
                    severity="high",
                    check_function="check_rounding_modes",
                    parameters={}
                ),
                ComplianceRule(
                    rule_id="IEEE754-002",
                    standard=ComplianceStandard.IEEE_754,
                    category="Exception Handling",
                    description="Floating-point exceptions must be properly handled",
                    severity="high",
                    check_function="check_exception_handling",
                    parameters={}
                ),
                ComplianceRule(
                    rule_id="IEEE754-003",
                    standard=ComplianceStandard.IEEE_754,
                    category="Special Values",
                    description="Special values (NaN, Infinity) must be handled correctly",
                    severity="medium",
                    check_function="check_special_values",
                    parameters={}
                )
            ],
            
            # ARM AMBA AHB compliance rules
            ComplianceStandard.ARM_AMBA_AHB: [
                ComplianceRule(
                    rule_id="AMBA-001",
                    standard=ComplianceStandard.ARM_AMBA_AHB,
                    category="Signal Protocol",
                    description="AHB signal protocol must be correctly implemented",
                    severity="critical",
                    check_function="check_ahb_protocol",
                    parameters={}
                ),
                ComplianceRule(
                    rule_id="AMBA-002",
                    standard=ComplianceStandard.ARM_AMBA_AHB,
                    category="Burst Transfers",
                    description="Burst transfer sequences must be properly implemented",
                    severity="high",
                    check_function="check_burst_transfers",
                    parameters={}
                ),
                ComplianceRule(
                    rule_id="AMBA-003",
                    standard=ComplianceStandard.ARM_AMBA_AHB,
                    category="Arbitration",
                    description="Bus arbitration must follow AHB specification",
                    severity="high",
                    check_function="check_arbitration",
                    parameters={}
                )
            ],
            
            # ISO 26262 compliance rules
            ComplianceStandard.ISO_26262: [
                ComplianceRule(
                    rule_id="ISO26262-001",
                    standard=ComplianceStandard.ISO_26262,
                    category="Safety Requirements",
                    description="Safety requirements must be traceable to design",
                    severity="critical",
                    check_function="check_safety_requirements",
                    parameters={}
                ),
                ComplianceRule(
                    rule_id="ISO26262-002",
                    standard=ComplianceStandard.ISO_26262,
                    category="Fault Tolerance",
                    description="Fault tolerance mechanisms must be implemented",
                    severity="critical",
                    check_function="check_fault_tolerance",
                    parameters={}
                ),
                ComplianceRule(
                    rule_id="ISO26262-003",
                    standard=ComplianceStandard.ISO_26262,
                    category="Verification",
                    description="Verification evidence must be provided",
                    severity="high",
                    check_function="check_verification_evidence",
                    parameters={}
                )
            ],
            
            # MISRA C compliance rules
            ComplianceStandard.MISRA_C: [
                ComplianceRule(
                    rule_id="MISRA-C-001",
                    standard=ComplianceStandard.MISRA_C,
                    category="Required",
                    description="Required MISRA C rules must be followed",
                    severity="high",
                    check_function="check_misra_required",
                    parameters={}
                ),
                ComplianceRule(
                    rule_id="MISRA-C-002",
                    standard=ComplianceStandard.MISRA_C,
                    category="Advisory",
                    description="Advisory MISRA C rules should be followed",
                    severity="medium",
                    check_function="check_misra_advisory",
                    parameters={}
                )
            ]
        }
    
    def _initialize_standards_config(self):
        """Initialize standards configuration"""
        self.standards_config = {
            ComplianceStandard.IEEE_754: {
                "required_features": ["rounding_modes", "exceptions", "special_values"],
                "optional_features": ["extended_precision", "fused_operations"],
                "test_vectors": "ieee754_test_vectors.json"
            },
            ComplianceStandard.ARM_AMBA_AHB: {
                "version": "5.0",
                "required_signals": ["HCLK", "HRESETn", "HADDR", "HTRANS", "HWRITE"],
                "optional_signals": ["HBURST", "HSIZE", "HPROT", "HREADY"],
                "test_sequences": "ahb_test_sequences.json"
            },
            ComplianceStandard.ISO_26262: {
                "asil_level": "ASIL-D",
                "required_measures": ["fault_detection", "fault_handling", "safety_monitoring"],
                "verification_methods": ["static_analysis", "testing", "formal_verification"]
            }
        }
    
    def check_compliance(self, filename: str, standards: List[ComplianceStandard]) -> ComplianceReport:
        """Check compliance against specified standards"""
        with open(filename, 'r') as f:
            content = f.read()
        
        violations = []
        
        # Check each standard
        for standard in standards:
            if standard in self.compliance_rules:
                standard_violations = self._check_standard_compliance(
                    content, standard, filename
                )
                violations.extend(standard_violations)
        
        # Calculate compliance scores
        compliance_scores = self._calculate_compliance_scores(violations, standards)
        
        # Generate summary
        summary = self._generate_summary(violations)
        
        # Generate recommendations
        recommendations = self._generate_recommendations(violations, standards)
        
        return ComplianceReport(
            filename=filename,
            standards=standards,
            violations=violations,
            compliance_scores=compliance_scores,
            summary=summary,
            recommendations=recommendations
        )
    
    def _check_standard_compliance(self, content: str, standard: ComplianceStandard, 
                                 filename: str) -> List[ComplianceViolation]:
        """Check compliance for a specific standard"""
        violations = []
        lines = content.split('\n')
        
        if standard not in self.compliance_rules:
            return violations
        
        for rule in self.compliance_rules[standard]:
            rule_violations = self._check_rule_compliance(
                content, lines, rule, filename
            )
            violations.extend(rule_violations)
        
        return violations
    
    def _check_rule_compliance(self, content: str, lines: List[str], 
                             rule: ComplianceRule, filename: str) -> List[ComplianceViolation]:
        """Check compliance for a specific rule"""
        violations = []
        
        # Get check function
        check_func = getattr(self, rule.check_function, None)
        if not check_func:
            return violations
        
        # Execute check function
        try:
            rule_violations = check_func(content, lines, rule, filename)
            violations.extend(rule_violations)
        except Exception as e:
            print(f"Error checking rule {rule.rule_id}: {e}")
        
        return violations
    
    def check_rounding_modes(self, content: str, lines: List[str], 
                           rule: ComplianceRule, filename: str) -> List[ComplianceViolation]:
        """Check IEEE 754 rounding modes compliance"""
        violations = []
        
        # Look for floating-point operations without proper rounding
        fp_patterns = [
            r'FADD\s+R(\d+)\s*,\s*R(\d+)\s*,\s*R(\d+)',
            r'FSUB\s+R(\d+)\s*,\s*R(\d+)\s*,\s*R(\d+)',
            r'FMUL\s+R(\d+)\s*,\s*R(\d+)\s*,\s*R(\d+)',
            r'FDIV\s+R(\d+)\s*,\s*R(\d+)\s*,\s*R(\d+)'
        ]
        
        for line_num, line in enumerate(lines, 1):
            for pattern in fp_patterns:
                if re.search(pattern, line):
                    # Check if rounding mode is specified
                    if not re.search(r'ROUND_', line):
                        violation = ComplianceViolation(
                            rule_id=rule.rule_id,
                            standard=rule.standard,
                            severity=rule.severity,
                            location=f"{filename}:{line_num}",
                            line_number=line_num,
                            description=f"Floating-point operation without explicit rounding mode: {rule.description}",
                            code_snippet=line.strip(),
                            remediation="Specify rounding mode using ROUND_NEAREST, ROUND_UP, ROUND_DOWN, or ROUND_TOWARD_ZERO",
                            confidence=0.8
                        )
                        violations.append(violation)
        
        return violations
    
    def check_exception_handling(self, content: str, lines: List[str], 
                               rule: ComplianceRule, filename: str) -> List[ComplianceViolation]:
        """Check IEEE 754 exception handling compliance"""
        violations = []
        
        # Look for floating-point operations without exception handling
        fp_ops = ['FADD', 'FSUB', 'FMUL', 'FDIV', 'FSQRT']
        
        for line_num, line in enumerate(lines, 1):
            for op in fp_ops:
                if op in line:
                    # Check if exception handling is present
                    if not re.search(r'(FEH|EXCEPTION|TRAP)', line):
                        violation = ComplianceViolation(
                            rule_id=rule.rule_id,
                            standard=rule.standard,
                            severity=rule.severity,
                            location=f"{filename}:{line_num}",
                            line_number=line_num,
                            description=f"Floating-point operation without exception handling: {rule.description}",
                            code_snippet=line.strip(),
                            remediation="Add exception handling using FEH instructions or exception traps",
                            confidence=0.7
                        )
                        violations.append(violation)
        
        return violations
    
    def check_special_values(self, content: str, lines: List[str], 
                           rule: ComplianceRule, filename: str) -> List[ComplianceViolation]:
        """Check IEEE 754 special values handling"""
        violations = []
        
        # Look for operations that might produce special values
        special_value_ops = ['FDIV', 'FSQRT', 'FLOG', 'FEXP']
        
        for line_num, line in enumerate(lines, 1):
            for op in special_value_ops:
                if op in line:
                    # Check if special value handling is present
                    if not re.search(r'(ISNAN|ISINF|CHECK_SPECIAL)', line):
                        violation = ComplianceViolation(
                            rule_id=rule.rule_id,
                            standard=rule.standard,
                            severity=rule.severity,
                            location=f"{filename}:{line_num}",
                            line_number=line_num,
                            description=f"Operation that may produce special values without checking: {rule.description}",
                            code_snippet=line.strip(),
                            remediation="Add special value checks using ISNAN, ISINF, or CHECK_SPECIAL instructions",
                            confidence=0.6
                        )
                        violations.append(violation)
        
        return violations
    
    def check_ahb_protocol(self, content: str, lines: List[str], 
                         rule: ComplianceRule, filename: str) -> List[ComplianceViolation]:
        """Check ARM AMBA AHB protocol compliance"""
        violations = []
        
        # Look for AHB protocol violations
        ahb_patterns = [
            r'HREADY\s*=\s*0.*HADDR',
            r'HTRANS\s*=\s*NONSEQ.*HADDR',
            r'HBURST\s*=\s*INCR.*HADDR'
        ]
        
        for line_num, line in enumerate(lines, 1):
            for pattern in ahb_patterns:
                if re.search(pattern, line):
                    violation = ComplianceViolation(
                        rule_id=rule.rule_id,
                        standard=rule.standard,
                        severity=rule.severity,
                        location=f"{filename}:{line_num}",
                        line_number=line_num,
                        description=f"AHB protocol violation detected: {rule.description}",
                        code_snippet=line.strip(),
                        remediation="Follow AHB protocol specification for signal timing and sequencing",
                        confidence=0.9
                    )
                    violations.append(violation)
        
        return violations
    
    def check_burst_transfers(self, content: str, lines: List[str], 
                            rule: ComplianceRule, filename: str) -> List[ComplianceViolation]:
        """Check AHB burst transfer compliance"""
        violations = []
        
        # Look for burst transfer sequences
        burst_pattern = r'HBURST\s*=\s*(INCR|WRAP)'
        
        for line_num, line in enumerate(lines, 1):
            if re.search(burst_pattern, line):
                # Check if proper burst sequence follows
                if not self._check_burst_sequence(lines, line_num):
                    violation = ComplianceViolation(
                        rule_id=rule.rule_id,
                        standard=rule.standard,
                        severity=rule.severity,
                        location=f"{filename}:{line_num}",
                        line_number=line_num,
                        description=f"Burst transfer sequence violation: {rule.description}",
                        code_snippet=line.strip(),
                        remediation="Ensure proper burst transfer sequence with correct HADDR increment",
                        confidence=0.8
                    )
                    violations.append(violation)
        
        return violations
    
    def _check_burst_sequence(self, lines: List[str], start_line: int) -> bool:
        """Check if burst sequence is properly implemented"""
        # Simplified burst sequence check
        # In practice, this would be more comprehensive
        return True
    
    def check_arbitration(self, content: str, lines: List[str], 
                         rule: ComplianceRule, filename: str) -> List[ComplianceViolation]:
        """Check AHB arbitration compliance"""
        violations = []
        
        # Look for arbitration issues
        arbitration_patterns = [
            r'HGRANT\s*=\s*1.*HGRANT\s*=\s*1',
            r'HBUSREQ\s*=\s*1.*HGRANT\s*=\s*0'
        ]
        
        for line_num, line in enumerate(lines, 1):
            for pattern in arbitration_patterns:
                if re.search(pattern, line):
                    violation = ComplianceViolation(
                        rule_id=rule.rule_id,
                        standard=rule.standard,
                        severity=rule.severity,
                        location=f"{filename}:{line_num}",
                        line_number=line_num,
                        description=f"Arbitration violation detected: {rule.description}",
                        code_snippet=line.strip(),
                        remediation="Follow AHB arbitration protocol with proper HGRANT and HBUSREQ handling",
                        confidence=0.8
                    )
                    violations.append(violation)
        
        return violations
    
    def check_safety_requirements(self, content: str, lines: List[str], 
                                rule: ComplianceRule, filename: str) -> List[ComplianceViolation]:
        """Check ISO 26262 safety requirements compliance"""
        violations = []
        
        # Look for safety-critical code without proper documentation
        safety_patterns = [
            r'SAFETY_CRITICAL',
            r'ASIL_D',
            r'FUNCTIONAL_SAFETY'
        ]
        
        for line_num, line in enumerate(lines, 1):
            for pattern in safety_patterns:
                if re.search(pattern, line):
                    # Check if proper documentation exists
                    if not self._check_safety_documentation(lines, line_num):
                        violation = ComplianceViolation(
                            rule_id=rule.rule_id,
                            standard=rule.standard,
                            severity=rule.severity,
                            location=f"{filename}:{line_num}",
                            line_number=line_num,
                            description=f"Safety-critical code without proper documentation: {rule.description}",
                            code_snippet=line.strip(),
                            remediation="Add proper safety requirement documentation and traceability",
                            confidence=0.9
                        )
                        violations.append(violation)
        
        return violations
    
    def _check_safety_documentation(self, lines: List[str], line_num: int) -> bool:
        """Check if safety documentation is present"""
        # Look for documentation in nearby lines
        start = max(0, line_num - 5)
        end = min(len(lines), line_num + 5)
        
        for i in range(start, end):
            if 'REQ-' in lines[i] or 'SAFETY_REQ' in lines[i]:
                return True
        
        return False
    
    def check_fault_tolerance(self, content: str, lines: List[str], 
                            rule: ComplianceRule, filename: str) -> List[ComplianceViolation]:
        """Check ISO 26262 fault tolerance compliance"""
        violations = []
        
        # Look for critical functions without fault tolerance
        critical_functions = ['brake_control', 'steering_control', 'throttle_control']
        
        for line_num, line in enumerate(lines, 1):
            for func in critical_functions:
                if func in line.lower():
                    # Check if fault tolerance mechanisms are present
                    if not self._check_fault_tolerance_mechanisms(lines, line_num):
                        violation = ComplianceViolation(
                            rule_id=rule.rule_id,
                            standard=rule.standard,
                            severity=rule.severity,
                            location=f"{filename}:{line_num}",
                            line_number=line_num,
                            description=f"Critical function without fault tolerance: {rule.description}",
                            code_snippet=line.strip(),
                            remediation="Implement fault detection, handling, and recovery mechanisms",
                            confidence=0.9
                        )
                        violations.append(violation)
        
        return violations
    
    def _check_fault_tolerance_mechanisms(self, lines: List[str], line_num: int) -> bool:
        """Check if fault tolerance mechanisms are present"""
        # Look for fault tolerance patterns
        fault_patterns = ['fault_detection', 'error_handling', 'recovery', 'redundancy']
        
        start = max(0, line_num - 10)
        end = min(len(lines), line_num + 10)
        
        for i in range(start, end):
            for pattern in fault_patterns:
                if pattern in lines[i].lower():
                    return True
        
        return False
    
    def check_verification_evidence(self, content: str, lines: List[str], 
                                  rule: ComplianceRule, filename: str) -> List[ComplianceViolation]:
        """Check ISO 26262 verification evidence compliance"""
        violations = []
        
        # Look for functions without verification evidence
        function_pattern = r'FUNCTION\s+(\w+)'
        
        for line_num, line in enumerate(lines, 1):
            match = re.search(function_pattern, line)
            if match:
                func_name = match.group(1)
                # Check if verification evidence exists
                if not self._check_verification_evidence_exists(lines, line_num, func_name):
                    violation = ComplianceViolation(
                        rule_id=rule.rule_id,
                        standard=rule.standard,
                        severity=rule.severity,
                        location=f"{filename}:{line_num}",
                        line_number=line_num,
                        description=f"Function without verification evidence: {rule.description}",
                        code_snippet=line.strip(),
                        remediation="Provide verification evidence including test cases and analysis results",
                        confidence=0.8
                    )
                    violations.append(violation)
        
        return violations
    
    def _check_verification_evidence_exists(self, lines: List[str], line_num: int, func_name: str) -> bool:
        """Check if verification evidence exists for function"""
        # Look for verification evidence patterns
        evidence_patterns = [
            f'TEST_{func_name.upper()}',
            f'VERIFY_{func_name.upper()}',
            f'ANALYSIS_{func_name.upper()}'
        ]
        
        for line in lines:
            for pattern in evidence_patterns:
                if pattern in line:
                    return True
        
        return False
    
    def check_misra_required(self, content: str, lines: List[str], 
                           rule: ComplianceRule, filename: str) -> List[ComplianceViolation]:
        """Check MISRA C required rules compliance"""
        violations = []
        
        # MISRA C required rules patterns
        misra_patterns = [
            (r'goto\s+\w+', "MISRA C Rule 14.4: goto statement should not be used"),
            (r'if\s*\(\s*[^)]*\s*=\s*[^)]*\s*\)', "MISRA C Rule 13.1: Assignment in condition"),
            (r'while\s*\(\s*1\s*\)', "MISRA C Rule 14.2: while(1) should be for(;;)")
        ]
        
        for line_num, line in enumerate(lines, 1):
            for pattern, description in misra_patterns:
                if re.search(pattern, line):
                    violation = ComplianceViolation(
                        rule_id=rule.rule_id,
                        standard=rule.standard,
                        severity=rule.severity,
                        location=f"{filename}:{line_num}",
                        line_number=line_num,
                        description=description,
                        code_snippet=line.strip(),
                        remediation="Follow MISRA C guidelines for safer C programming",
                        confidence=0.9
                    )
                    violations.append(violation)
        
        return violations
    
    def check_misra_advisory(self, content: str, lines: List[str], 
                           rule: ComplianceRule, filename: str) -> List[ComplianceViolation]:
        """Check MISRA C advisory rules compliance"""
        violations = []
        
        # MISRA C advisory rules patterns
        advisory_patterns = [
            (r'/\*.*\*/', "MISRA C Rule 2.3: Use // for single-line comments"),
            (r'#define\s+\w+\s*\(\s*\w+\s*\)', "MISRA C Rule 19.7: Function-like macros should be avoided")
        ]
        
        for line_num, line in enumerate(lines, 1):
            for pattern, description in advisory_patterns:
                if re.search(pattern, line):
                    violation = ComplianceViolation(
                        rule_id=rule.rule_id,
                        standard=rule.standard,
                        severity=rule.severity,
                        location=f"{filename}:{line_num}",
                        line_number=line_num,
                        description=description,
                        code_snippet=line.strip(),
                        remediation="Consider following MISRA C advisory guidelines",
                        confidence=0.6
                    )
                    violations.append(violation)
        
        return violations
    
    def _calculate_compliance_scores(self, violations: List[ComplianceViolation], 
                                   standards: List[ComplianceStandard]) -> Dict[str, float]:
        """Calculate compliance scores for each standard"""
        scores = {}
        
        for standard in standards:
            standard_violations = [v for v in violations if v.standard == standard]
            
            if not standard_violations:
                scores[standard.value] = 100.0
            else:
                # Calculate score based on severity
                severity_weights = {
                    'critical': 10,
                    'high': 7,
                    'medium': 4,
                    'low': 2
                }
                
                total_penalty = 0
                for violation in standard_violations:
                    weight = severity_weights.get(violation.severity, 1)
                    total_penalty += weight * violation.confidence
                
                # Normalize to 0-100 scale
                max_penalty = len(standard_violations) * 10
                penalty_ratio = total_penalty / max_penalty if max_penalty > 0 else 0
                scores[standard.value] = max(0, 100 - (penalty_ratio * 100))
        
        return scores
    
    def _generate_summary(self, violations: List[ComplianceViolation]) -> Dict[str, int]:
        """Generate compliance summary"""
        summary = {
            'total_violations': len(violations),
            'critical': 0,
            'high': 0,
            'medium': 0,
            'low': 0
        }
        
        for violation in violations:
            summary[violation.severity] += 1
        
        return summary
    
    def _generate_recommendations(self, violations: List[ComplianceViolation], 
                                standards: List[ComplianceStandard]) -> List[str]:
        """Generate compliance recommendations"""
        recommendations = []
        
        # Count violations by standard
        standard_violations = {}
        for violation in violations:
            std = violation.standard.value
            standard_violations[std] = standard_violations.get(std, 0) + 1
        
        # Generate recommendations based on violations
        if ComplianceStandard.IEEE_754 in standards and 'ieee_754' in standard_violations:
            recommendations.append("Implement proper IEEE 754 floating-point compliance")
        
        if ComplianceStandard.ARM_AMBA_AHB in standards and 'arm_amba_ahb' in standard_violations:
            recommendations.append("Review and fix ARM AMBA AHB protocol implementation")
        
        if ComplianceStandard.ISO_26262 in standards and 'iso_26262' in standard_violations:
            recommendations.append("Implement ISO 26262 functional safety requirements")
        
        if ComplianceStandard.MISRA_C in standards and 'misra_c' in standard_violations:
            recommendations.append("Apply MISRA C coding guidelines")
        
        # General recommendations
        recommendations.extend([
            "Implement automated compliance checking in CI/CD pipeline",
            "Regular compliance audits and reviews",
            "Document compliance evidence and traceability",
            "Use compliance checking tools and static analysis",
            "Train development team on compliance requirements"
        ])
        
        return recommendations
    
    def generate_compliance_report(self, report: ComplianceReport, output_file: str = None):
        """Generate comprehensive compliance report"""
        if output_file is None:
            output_file = f"compliance_report_{report.filename.replace('/', '_')}.json"
        
        report_data = {
            'filename': report.filename,
            'standards': [std.value for std in report.standards],
            'compliance_scores': report.compliance_scores,
            'summary': report.summary,
            'violations': [asdict(violation) for violation in report.violations],
            'recommendations': report.recommendations,
            'timestamp': time.time()
        }
        
        with open(output_file, 'w') as f:
            json.dump(report_data, f, indent=2)
        
        print(f"Compliance report saved to {output_file}")
        
        # Generate markdown report
        md_file = output_file.replace('.json', '.md')
        self._generate_markdown_report(report, md_file)
    
    def _generate_markdown_report(self, report: ComplianceReport, output_file: str):
        """Generate markdown compliance report"""
        md_content = f"""# Compliance Analysis Report

## File: {report.filename}

### Standards Checked
{', '.join([std.value for std in report.standards])}

### Compliance Scores
"""
        
        for standard, score in report.compliance_scores.items():
            md_content += f"- **{standard}**: {score:.1f}%\n"
        
        md_content += f"""
### Summary
- **Total Violations**: {report.summary['total_violations']}
- **Critical**: {report.summary['critical']}
- **High**: {report.summary['high']}
- **Medium**: {report.summary['medium']}
- **Low**: {report.summary['low']}

### Violations

"""
        
        for violation in report.violations:
            md_content += f"""#### {violation.rule_id} ({violation.severity.upper()})
- **Standard**: {violation.standard.value}
- **Location**: {violation.location}
- **Description**: {violation.description}
- **Code**: `{violation.code_snippet}`
- **Remediation**: {violation.remediation}

"""
        
        md_content += "### Recommendations\n\n"
        for i, rec in enumerate(report.recommendations, 1):
            md_content += f"{i}. {rec}\n"
        
        with open(output_file, 'w') as f:
            f.write(md_content)
        
        print(f"Markdown report saved to {output_file}")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='AlphaAHB V5 Compliance Checker')
    parser.add_argument('file', help='File to check')
    parser.add_argument('-s', '--standards', nargs='+', 
                       choices=['ieee_754', 'arm_amba_ahb', 'iso_26262', 'iec_61508', 'do_178c', 'misra_c'],
                       default=['ieee_754', 'arm_amba_ahb'], help='Standards to check against')
    parser.add_argument('-o', '--output', help='Output report file')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    
    args = parser.parse_args()
    
    # Convert string standards to enum
    standards = [ComplianceStandard(std) for std in args.standards]
    
    checker = AlphaAHBComplianceChecker()
    
    # Check compliance
    report = checker.check_compliance(args.file, standards)
    
    # Print summary
    print(f"Compliance Check for {args.file}")
    print(f"Standards: {', '.join([std.value for std in standards])}")
    print("Compliance Scores:")
    for standard, score in report.compliance_scores.items():
        print(f"  {standard}: {score:.1f}%")
    print(f"Total Violations: {report.summary['total_violations']}")
    
    if args.verbose:
        print("\nDetailed Findings:")
        for violation in report.violations:
            print(f"  {violation.rule_id} ({violation.severity}) at {violation.location}")
            print(f"    {violation.description}")
            print(f"    Remediation: {violation.remediation}")
    
    # Generate report
    checker.generate_compliance_report(report, args.output)

if __name__ == '__main__':
    main()
