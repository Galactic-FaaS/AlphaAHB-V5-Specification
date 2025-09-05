#!/bin/bash

# AlphaAHB V5 ISA Test Suite Runner
# This script compiles and runs all test suites for the AlphaAHB V5 ISA

echo "AlphaAHB V5 ISA Test Suite Runner"
echo "================================="

# Set compiler flags
CC=gcc
CFLAGS="-Wall -Wextra -O2 -std=c99"
LDFLAGS="-lm"

# Test directories
TEST_DIR="tests"
BUILD_DIR="build"
RESULTS_DIR="results"

# Create directories
mkdir -p $BUILD_DIR
mkdir -p $RESULTS_DIR

# Function to compile and run a test
run_test() {
    local test_name=$1
    local test_file=$2
    local executable=$3
    
    echo "Compiling $test_name..."
    $CC $CFLAGS -o $BUILD_DIR/$executable $test_file $LDFLAGS
    
    if [ $? -eq 0 ]; then
        echo "Running $test_name..."
        $BUILD_DIR/$executable > $RESULTS_DIR/${test_name}.log 2>&1
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo "✓ $test_name PASSED"
        else
            echo "✗ $test_name FAILED (exit code: $exit_code)"
            echo "  See $RESULTS_DIR/${test_name}.log for details"
        fi
        
        return $exit_code
    else
        echo "✗ $test_name COMPILATION FAILED"
        return 1
    fi
}

# Function to run performance benchmarks
run_benchmark() {
    local benchmark_name=$1
    local benchmark_file=$2
    local executable=$3
    
    echo "Compiling $benchmark_name..."
    $CC $CFLAGS -o $BUILD_DIR/$executable $benchmark_file $LDFLAGS
    
    if [ $? -eq 0 ]; then
        echo "Running $benchmark_name..."
        $BUILD_DIR/$executable > $RESULTS_DIR/${benchmark_name}.log 2>&1
        local exit_code=$?
        
        if [ $exit_code -eq 0 ]; then
            echo "✓ $benchmark_name COMPLETED"
            echo "  Results saved to $RESULTS_DIR/${benchmark_name}.log"
        else
            echo "✗ $benchmark_name FAILED (exit code: $exit_code)"
            echo "  See $RESULTS_DIR/${benchmark_name}.log for details"
        fi
        
        return $exit_code
    else
        echo "✗ $benchmark_name COMPILATION FAILED"
        return 1
    fi
}

# Initialize counters
total_tests=0
passed_tests=0
failed_tests=0

echo "Starting test execution..."
echo ""

# Run instruction tests
echo "=== Instruction Tests ==="
run_test "Instruction Tests" "$TEST_DIR/instruction-tests.c" "instruction-tests"
if [ $? -eq 0 ]; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

echo ""

# Run IEEE 754 compliance tests
echo "=== IEEE 754 Compliance Tests ==="
run_test "IEEE 754 Compliance" "$TEST_DIR/ieee754-compliance.c" "ieee754-compliance"
if [ $? -eq 0 ]; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

echo ""

# Run performance benchmarks
echo "=== Performance Benchmarks ==="
run_benchmark "Performance Benchmarks" "$TEST_DIR/performance-benchmarks.c" "performance-benchmarks"
if [ $? -eq 0 ]; then
    ((passed_tests++))
else
    ((failed_tests++))
fi
((total_tests++))

echo ""

# Generate test summary
echo "=== Test Summary ==="
echo "Total tests: $total_tests"
echo "Passed: $passed_tests"
echo "Failed: $failed_tests"

if [ $failed_tests -eq 0 ]; then
    echo ""
    echo "🎉 ALL TESTS PASSED! 🎉"
    echo "AlphaAHB V5 ISA is ready for implementation."
    exit 0
else
    echo ""
    echo "❌ SOME TESTS FAILED ❌"
    echo "Please review the test results and fix any issues."
    exit 1
fi
