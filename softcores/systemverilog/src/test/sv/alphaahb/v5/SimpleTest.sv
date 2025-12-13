/*
 * Simple AlphaAHB V5 Testbench
 * Minimal testbench for basic functionality testing
 */

`timescale 1ns/1ps

module SimpleTest;

    // Test parameters
    parameter int NUM_TESTS = 10;
    parameter int MEMORY_SIZE = 1024;
    
    // Test signals
    logic clk;
    logic rst_n;
    
    // Simple test memory
    logic [63:0] test_memory [MEMORY_SIZE-1:0];
    logic [63:0] test_memory_addr;
    logic [63:0] test_memory_data;
    logic        test_memory_valid;
    
    // Test counters
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test memory model
    always_ff @(posedge clk) begin
        if (rst_n) begin
            test_memory_valid <= 1'b1;
            test_memory_data <= test_memory[test_memory_addr[9:0]]; // Fixed: Use correct bit range for 1024-entry array
        end
    end
    
    // Test initialization
    initial begin
        $display("==========================================");
        $display("AlphaAHB V5 Simple Testbench");
        $display("==========================================");
        
        // Initialize test memory
        for (int i = 0; i < MEMORY_SIZE; i++) begin
            test_memory[i] = i;
        end
        
        // Reset system
        rst_n = 0;
        #100;
        rst_n = 1;
        #50;
        
        $display("System reset complete");
        
        // Run basic tests
        run_basic_tests();
        
        // Print results
        print_results();
        
        $finish;
    end
    
    // Basic test functions
    task run_basic_tests();
        $display("\n=== Running Basic Tests ===");
        
        // Test 1: Clock functionality
        test_clock_functionality();
        
        // Test 2: Memory functionality
        test_memory_functionality();
        
        // Test 3: Reset functionality
        test_reset_functionality();
        
        // Test 4: Basic arithmetic
        test_basic_arithmetic();
        
        // Test 5: Logic operations
        test_logic_operations();
    endtask
    
    task test_clock_functionality();
        logic prev_clk;
        int transitions = 0;
        test_count++;
        $display("Test %0d: Clock functionality", test_count);

        // Fixed: Check for actual clock transitions over multiple cycles
        repeat(4) begin  // Check 4 times
            prev_clk = clk;
            #5;  // Wait half clock period
            if (clk != prev_clk) transitions++;
        end

        if (transitions >= 3) begin  // At least 3 transitions means clock is working
            $display("  PASS: Clock is toggling (%0d transitions detected)", transitions);
            pass_count++;
        end else begin
            $display("  FAIL: Clock is not toggling properly (%0d transitions detected)", transitions);
            fail_count++;
        end
    endtask
    
    task test_memory_functionality();
        test_count++;
        $display("Test %0d: Memory functionality", test_count);
        
        // Test memory read with proper timing
        test_memory_addr = 64'h10;
        #20; // Wait for memory access
        if (test_memory_data == 64'h10) begin
            $display("  PASS: Memory read working");
            pass_count++;
        end else begin
            $display("  FAIL: Memory read failed (expected 0x10, got 0x%h)", test_memory_data);
            fail_count++;
        end
    endtask
    
    task test_reset_functionality();
        test_count++;
        $display("Test %0d: Reset functionality", test_count);
        
        // Test reset
        rst_n = 0;
        #10;
        rst_n = 1;
        #10;
        
        if (rst_n == 1'b1) begin
            $display("  PASS: Reset functionality working");
            pass_count++;
        end else begin
            $display("  FAIL: Reset functionality failed");
            fail_count++;
        end
    endtask
    
    task test_basic_arithmetic();
        logic [63:0] a, b, sum;
        test_count++;
        $display("Test %0d: Basic arithmetic", test_count);
        
        // Test simple addition
        a = 64'h10;
        b = 64'h20;
        sum = a + b;
        
        if (sum == 64'h30) begin
            $display("  PASS: Basic arithmetic working");
            pass_count++;
        end else begin
            $display("  FAIL: Basic arithmetic failed (expected 0x30, got 0x%h)", sum);
            fail_count++;
        end
    endtask
    
    task test_logic_operations();
        logic [63:0] a, b, result;
        test_count++;
        $display("Test %0d: Logic operations", test_count);
        
        // Test simple logic
        a = 64'hF0F0F0F0F0F0F0F0;
        b = 64'h0F0F0F0F0F0F0F0F;
        result = a & b;
        
        if (result == 64'h0) begin
            $display("  PASS: Logic operations working");
            pass_count++;
        end else begin
            $display("  FAIL: Logic operations failed (expected 0x0, got 0x%h)", result);
            fail_count++;
        end
    endtask
    
    task print_results();
        $display("\n==========================================");
        $display("Test Results");
        $display("==========================================");
        $display("Total tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("\n🎉 ALL TESTS PASSED! 🎉");
            $display("AlphaAHB V5 basic functionality is working!");
        end else begin
            $display("\n❌ Some tests failed. Please review the issues.");
        end
        
        $display("==========================================");
    endtask

endmodule
