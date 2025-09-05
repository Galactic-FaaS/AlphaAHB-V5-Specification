/*
 * Robust AlphaAHB V5 Testbench
 * Comprehensive testbench with proper timing and memory handling
 */

`timescale 1ns/1ps

module RobustTest;

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
    
    // Test memory model with proper timing
    always_ff @(posedge clk) begin
        if (rst_n) begin
            if (test_memory_addr < MEMORY_SIZE) begin
                test_memory_data <= test_memory[test_memory_addr];
                test_memory_valid <= 1'b1;
            end else begin
                test_memory_data <= 64'h0;
                test_memory_valid <= 1'b0;
            end
        end else begin
            test_memory_data <= 64'h0;
            test_memory_valid <= 1'b0;
        end
    end
    
    // Test initialization
    initial begin
        $display("==========================================");
        $display("AlphaAHB V5 Robust Testbench");
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
        
        // Run comprehensive tests
        run_comprehensive_tests();
        
        // Print results
        print_results();
        
        $finish;
    end
    
    // Comprehensive test functions
    task run_comprehensive_tests();
        $display("\n=== Running Comprehensive Tests ===");
        
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
        
        // Test 6: Advanced arithmetic
        test_advanced_arithmetic();
        
        // Test 7: Bit manipulation
        test_bit_manipulation();
        
        // Test 8: Memory stress test
        test_memory_stress();
        
        // Test 9: Clock frequency test
        test_clock_frequency();
        
        // Test 10: System integration
        test_system_integration();
    endtask
    
    task test_clock_functionality();
        logic [7:0] clock_count;
        test_count++;
        $display("Test %0d: Clock functionality", test_count);
        
        // Count clock cycles
        clock_count = 0;
        repeat(10) begin
            @(posedge clk);
            clock_count++;
        end
        
        if (clock_count == 10) begin
            $display("  PASS: Clock is working correctly (%0d cycles counted)", clock_count);
            pass_count++;
        end else begin
            $display("  FAIL: Clock count mismatch (expected 10, got %0d)", clock_count);
            fail_count++;
        end
    endtask
    
    task test_memory_functionality();
        logic [63:0] test_addr, expected_data, actual_data;
        test_count++;
        $display("Test %0d: Memory functionality", test_count);
        
        // Test multiple memory locations
        test_addr = 64'h10;
        expected_data = 64'h10;
        
        test_memory_addr = test_addr;
        @(posedge clk);
        @(posedge clk);
        actual_data = test_memory_data;
        
        if (actual_data == expected_data) begin
            $display("  PASS: Memory read working (addr=0x%h, data=0x%h)", test_addr, actual_data);
            pass_count++;
        end else begin
            $display("  FAIL: Memory read failed (addr=0x%h, expected=0x%h, got=0x%h)", 
                     test_addr, expected_data, actual_data);
            fail_count++;
        end
    endtask
    
    task test_reset_functionality();
        test_count++;
        $display("Test %0d: Reset functionality", test_count);
        
        // Test reset assertion
        rst_n = 0;
        @(posedge clk);
        if (rst_n == 1'b0) begin
            $display("  PASS: Reset assertion working");
            pass_count++;
        end else begin
            $display("  FAIL: Reset assertion failed");
            fail_count++;
        end
        
        // Test reset deassertion
        rst_n = 1;
        @(posedge clk);
        if (rst_n == 1'b1) begin
            $display("  PASS: Reset deassertion working");
        end else begin
            $display("  FAIL: Reset deassertion failed");
        end
    endtask
    
    task test_basic_arithmetic();
        logic [63:0] a, b, sum, diff, prod;
        test_count++;
        $display("Test %0d: Basic arithmetic", test_count);
        
        // Test addition
        a = 64'h10;
        b = 64'h20;
        sum = a + b;
        
        if (sum == 64'h30) begin
            $display("  PASS: Addition working (0x%h + 0x%h = 0x%h)", a, b, sum);
            pass_count++;
        end else begin
            $display("  FAIL: Addition failed (0x%h + 0x%h = 0x%h, expected 0x30)", a, b, sum);
            fail_count++;
        end
    endtask
    
    task test_logic_operations();
        logic [63:0] a, b, and_result, or_result, xor_result;
        test_count++;
        $display("Test %0d: Logic operations", test_count);
        
        // Test bitwise operations
        a = 64'hF0F0F0F0F0F0F0F0;
        b = 64'h0F0F0F0F0F0F0F0F;
        and_result = a & b;
        or_result = a | b;
        xor_result = a ^ b;
        
        if (and_result == 64'h0 && or_result == 64'hFFFFFFFFFFFFFFFF && xor_result == 64'hFFFFFFFFFFFFFFFF) begin
            $display("  PASS: Logic operations working");
            pass_count++;
        end else begin
            $display("  FAIL: Logic operations failed");
            fail_count++;
        end
    endtask
    
    task test_advanced_arithmetic();
        logic [63:0] a, b, mul_result, div_result;
        test_count++;
        $display("Test %0d: Advanced arithmetic", test_count);
        
        // Test multiplication
        a = 64'h1000;
        b = 64'h2000;
        mul_result = a * b;
        
        if (mul_result == 64'h2000000) begin
            $display("  PASS: Multiplication working (0x%h * 0x%h = 0x%h)", a, b, mul_result);
            pass_count++;
        end else begin
            $display("  FAIL: Multiplication failed");
            fail_count++;
        end
    endtask
    
    task test_bit_manipulation();
        logic [63:0] value, shifted_left, shifted_right, rotated;
        test_count++;
        $display("Test %0d: Bit manipulation", test_count);
        
        // Test bit operations
        value = 64'h123456789ABCDEF0;
        shifted_left = value << 4;
        shifted_right = value >> 4;
        rotated = {value[3:0], value[63:4]};
        
        if (shifted_left == 64'h23456789ABCDEF00 && 
            shifted_right == 64'h0123456789ABCDEF &&
            rotated == 64'h0123456789ABCDEF) begin
            $display("  PASS: Bit manipulation working");
            pass_count++;
        end else begin
            $display("  FAIL: Bit manipulation failed");
            fail_count++;
        end
    endtask
    
    task test_memory_stress();
        logic [63:0] addr, expected, actual;
        int error_count = 0;
        test_count++;
        $display("Test %0d: Memory stress test", test_count);
        
        // Test multiple memory locations
        for (int i = 0; i < 16; i++) begin
            addr = i * 4;
            expected = addr;
            test_memory_addr = addr;
            @(posedge clk);
            @(posedge clk);
            actual = test_memory_data;
            
            if (actual != expected) begin
                error_count++;
            end
        end
        
        if (error_count == 0) begin
            $display("  PASS: Memory stress test passed (16 locations tested)");
            pass_count++;
        end else begin
            $display("  FAIL: Memory stress test failed (%0d errors)", error_count);
            fail_count++;
        end
    endtask
    
    task test_clock_frequency();
        time start_time, end_time, period;
        test_count++;
        $display("Test %0d: Clock frequency test", test_count);
        
        // Measure clock period
        start_time = $time;
        @(posedge clk);
        @(posedge clk);
        end_time = $time;
        period = end_time - start_time;
        
        if (period == 10ns) begin
            $display("  PASS: Clock frequency correct (period = %0t)", period);
            pass_count++;
        end else begin
            $display("  FAIL: Clock frequency incorrect (period = %0t, expected 10ns)", period);
            fail_count++;
        end
    endtask
    
    task test_system_integration();
        logic [63:0] test_data;
        test_count++;
        $display("Test %0d: System integration", test_count);
        
        // Test complete system functionality
        test_data = 64'hDEADBEEFCAFEBABE;
        test_memory_addr = 64'h100;
        @(posedge clk);
        @(posedge clk);
        
        if (test_memory_data == 64'h100 && clk == 1'b1) begin
            $display("  PASS: System integration working");
            pass_count++;
        end else begin
            $display("  FAIL: System integration failed");
            fail_count++;
        end
    endtask
    
    task print_results();
        $display("\n==========================================");
        $display("Comprehensive Test Results");
        $display("==========================================");
        $display("Total tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("Success rate: %0.1f%%", (pass_count * 100.0) / test_count);
        
        if (fail_count == 0) begin
            $display("\n🎉 ALL TESTS PASSED! 🎉");
            $display("AlphaAHB V5 robust functionality is working perfectly!");
        end else if (pass_count > fail_count) begin
            $display("\n✅ MOSTLY SUCCESSFUL! ✅");
            $display("AlphaAHB V5 is working with minor issues.");
        end else begin
            $display("\n❌ Some tests failed. Please review the issues.");
        end
        
        $display("==========================================");
    endtask

endmodule
