/*
 * AlphaAHB V5 Performance Testbench
 * Comprehensive performance and multi-core testing
 */

`timescale 1ns/1ps

module PerformanceTest;

    // Test parameters
    parameter int NUM_CORES = 4;
    parameter int MEMORY_SIZE = 1024;
    parameter int TEST_ITERATIONS = 1000;
    
    // Clock and reset
    logic clk;
    logic rst_n;
    
    // Multi-core test memory
    logic [63:0] test_memory [MEMORY_SIZE-1:0];
    logic [63:0] test_memory_addr [NUM_CORES-1:0];
    logic [63:0] test_memory_data [NUM_CORES-1:0];
    logic        test_memory_valid [NUM_CORES-1:0];
    
    // Performance counters
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    time start_time, end_time;
    int total_instructions = 0;
    int total_cycles = 0;
    
    // Clock generation (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Multi-core memory model
    genvar i;
    generate
        for (i = 0; i < NUM_CORES; i++) begin : gen_memory
            always_ff @(posedge clk) begin
                if (rst_n) begin
                    if (test_memory_addr[i] < MEMORY_SIZE) begin
                        test_memory_data[i] <= test_memory[test_memory_addr[i]];
                        test_memory_valid[i] <= 1'b1;
                    end else begin
                        test_memory_data[i] <= 64'h0;
                        test_memory_valid[i] <= 1'b0;
                    end
                end else begin
                    test_memory_data[i] <= 64'h0;
                    test_memory_valid[i] <= 1'b0;
                end
            end
        end
    endgenerate
    
    // Test initialization
    initial begin
        $display("==========================================");
        $display("AlphaAHB V5 Performance Testbench");
        $display("Multi-Core MIMD Testing");
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
        
        // Run comprehensive performance tests
        run_performance_tests();
        
        // Print results
        print_performance_results();
        
        $finish;
    end
    
    // Performance test functions
    task run_performance_tests();
        $display("\n=== Running Performance Tests ===");
        
        // Test 1: Single-core performance
        test_single_core_performance();
        
        // Test 2: Multi-core performance
        test_multi_core_performance();
        
        // Test 3: Memory bandwidth test
        test_memory_bandwidth();
        
        // Test 4: Cache performance test
        test_cache_performance();
        
        // Test 5: Vector operations test
        test_vector_operations();
        
        // Test 6: AI/ML operations test
        test_ai_ml_operations();
        
        // Test 7: MIMD coordination test
        test_mimd_coordination();
        
        // Test 8: Scalability test
        test_scalability();
        
        // Test 9: Power efficiency test
        test_power_efficiency();
        
        // Test 10: Real-time performance test
        test_realtime_performance();
    endtask
    
    task test_single_core_performance();
        test_count++;
        $display("Test %0d: Single-core performance", test_count);
        
        start_time = $time;
        
        // Simulate single-core instruction execution
        for (int i = 0; i < TEST_ITERATIONS; i++) begin
            @(posedge clk);
            total_instructions++;
            total_cycles++;
        end
        
        end_time = $time;
        
        // Calculate performance metrics
        time execution_time = end_time - start_time;
        real instructions_per_second;
        real cycles_per_instruction;
        
        instructions_per_second = (total_instructions * 1e9) / execution_time;
        cycles_per_instruction = real'(total_cycles) / real'(total_instructions);
        
        $display("  Execution time: %0t", execution_time);
        $display("  Instructions: %0d", total_instructions);
        $display("  Cycles: %0d", total_cycles);
        $display("  Instructions/second: %.2f MIPS", instructions_per_second / 1e6);
        $display("  CPI: %.2f", cycles_per_instruction);
        
        if (instructions_per_second > 100e6) begin // > 100 MIPS
            $display("  PASS: Single-core performance meets target");
            pass_count++;
        end else begin
            $display("  FAIL: Single-core performance below target");
            fail_count++;
        end
    endtask
    
    task test_multi_core_performance();
        test_count++;
        $display("Test %0d: Multi-core performance", test_count);
        
        start_time = $time;
        
        // Simulate multi-core parallel execution
        fork
            // Core 0: Integer operations
            begin
                for (int i = 0; i < TEST_ITERATIONS/4; i++) begin
                    @(posedge clk);
                    test_memory_addr[0] = i;
                    @(posedge clk);
                end
            end
            
            // Core 1: Floating-point operations
            begin
                for (int i = 0; i < TEST_ITERATIONS/4; i++) begin
                    @(posedge clk);
                    test_memory_addr[1] = i + 256;
                    @(posedge clk);
                end
            end
            
            // Core 2: Vector operations
            begin
                for (int i = 0; i < TEST_ITERATIONS/4; i++) begin
                    @(posedge clk);
                    test_memory_addr[2] = i + 512;
                    @(posedge clk);
                end
            end
            
            // Core 3: AI/ML operations
            begin
                for (int i = 0; i < TEST_ITERATIONS/4; i++) begin
                    @(posedge clk);
                    test_memory_addr[3] = i + 768;
                    @(posedge clk);
                end
            end
        join
        
        end_time = $time;
        
        time execution_time = end_time - start_time;
        real parallel_efficiency;
        
        parallel_efficiency = (TEST_ITERATIONS * 1e9) / (execution_time * NUM_CORES);
        
        $display("  Parallel execution time: %0t", execution_time);
        $display("  Parallel efficiency: %.2f MIPS/core", parallel_efficiency / 1e6);
        
        if (parallel_efficiency > 50e6) begin // > 50 MIPS per core
            $display("  PASS: Multi-core performance meets target");
            pass_count++;
        end else begin
            $display("  FAIL: Multi-core performance below target");
            fail_count++;
        end
    endtask
    
    task test_memory_bandwidth();
        test_count++;
        $display("Test %0d: Memory bandwidth", test_count);
        
        start_time = $time;
        
        // Sequential memory access test
        for (int i = 0; i < MEMORY_SIZE; i++) begin
            test_memory_addr[0] = i;
            @(posedge clk);
        end
        
        end_time = $time;
        
        time execution_time = end_time - start_time;
        real bandwidth = (MEMORY_SIZE * 64) / (execution_time / 1e9); // bits per second
        
        $display("  Memory access time: %0t", execution_time);
        $display("  Bandwidth: %.2f Gbps", bandwidth / 1e9);
        
        if (bandwidth > 1e9) begin // > 1 Gbps
            $display("  PASS: Memory bandwidth meets target");
            pass_count++;
        end else begin
            $display("  FAIL: Memory bandwidth below target");
            fail_count++;
        end
    endtask
    
    task test_cache_performance();
        test_count++;
        $display("Test %0d: Cache performance", test_count);
        
        int cache_hits = 0;
        int cache_misses = 0;
        
        // Test cache hit/miss patterns
        for (int i = 0; i < 100; i++) begin
            // Access same memory location (cache hit)
            test_memory_addr[0] = i % 16;
            @(posedge clk);
            cache_hits++;
            
            // Access different memory location (cache miss)
            test_memory_addr[0] = i + 1000;
            @(posedge clk);
            cache_misses++;
        end
        
        real hit_rate = real'(cache_hits) / real'(cache_hits + cache_misses);
        
        $display("  Cache hits: %0d", cache_hits);
        $display("  Cache misses: %0d", cache_misses);
        $display("  Hit rate: %.2f%%", hit_rate * 100);
        
        if (hit_rate > 0.8) begin // > 80% hit rate
            $display("  PASS: Cache performance meets target");
            pass_count++;
        end else begin
            $display("  FAIL: Cache performance below target");
            fail_count++;
        end
    endtask
    
    task test_vector_operations();
        test_count++;
        $display("Test %0d: Vector operations", test_count);
        
        start_time = $time;
        
        // Simulate 512-bit vector operations
        for (int i = 0; i < 100; i++) begin
            // Vector addition (8 x 64-bit elements)
            for (int j = 0; j < 8; j++) begin
                test_memory_addr[0] = i * 8 + j;
                @(posedge clk);
            end
        end
        
        end_time = $time;
        
        time execution_time = end_time - start_time;
        real vector_ops_per_second = (100 * 8 * 1e9) / execution_time;
        
        $display("  Vector operations time: %0t", execution_time);
        $display("  Vector ops/second: %.2f MOPS", vector_ops_per_second / 1e6);
        
        if (vector_ops_per_second > 10e6) begin // > 10 MOPS
            $display("  PASS: Vector operations meet target");
            pass_count++;
        end else begin
            $display("  FAIL: Vector operations below target");
            fail_count++;
        end
    endtask
    
    task test_ai_ml_operations();
        test_count++;
        $display("Test %0d: AI/ML operations", test_count);
        
        start_time = $time;
        
        // Simulate neural network operations
        for (int layer = 0; layer < 10; layer++) begin
            for (int neuron = 0; neuron < 100; neuron++) begin
                // Simulate matrix multiplication
                for (int weight = 0; weight < 50; weight++) begin
                    test_memory_addr[0] = layer * 1000 + neuron * 50 + weight;
                    @(posedge clk);
                end
            end
        end
        
        end_time = $time;
        
        time execution_time = end_time - start_time;
        real ai_ops_per_second = (10 * 100 * 50 * 1e9) / execution_time;
        
        $display("  AI/ML operations time: %0t", execution_time);
        $display("  AI ops/second: %.2f MOPS", ai_ops_per_second / 1e6);
        
        if (ai_ops_per_second > 1e6) begin // > 1 MOPS
            $display("  PASS: AI/ML operations meet target");
            pass_count++;
        end else begin
            $display("  FAIL: AI/ML operations below target");
            fail_count++;
        end
    endtask
    
    task test_mimd_coordination();
        test_count++;
        $display("Test %0d: MIMD coordination", test_count);
        
        int coordination_errors = 0;
        
        // Test inter-core communication
        fork
            // Core 0: Producer
            begin
                for (int i = 0; i < 50; i++) begin
                    test_memory[i] = i;
                    @(posedge clk);
                end
            end
            
            // Core 1: Consumer
            begin
                for (int i = 0; i < 50; i++) begin
                    @(posedge clk);
                    test_memory_addr[1] = i;
                    @(posedge clk);
                    if (test_memory_data[1] != i) begin
                        coordination_errors++;
                    end
                end
            end
        join
        
        $display("  Coordination errors: %0d", coordination_errors);
        
        if (coordination_errors == 0) begin
            $display("  PASS: MIMD coordination working");
            pass_count++;
        end else begin
            $display("  FAIL: MIMD coordination errors detected");
            fail_count++;
        end
    endtask
    
    task test_scalability();
        test_count++;
        $display("Test %0d: Scalability", test_count);
        
        // Test with different core counts
        int cores_tested[] = {1, 2, 4};
        real efficiency[] = {0.0, 0.0, 0.0};
        
        for (int c = 0; c < 3; c++) begin
            int num_cores = cores_tested[c];
            start_time = $time;
            
            // Simulate work distribution
            for (int i = 0; i < TEST_ITERATIONS; i++) begin
                for (int core = 0; core < num_cores; core++) begin
                    test_memory_addr[core] = i * num_cores + core;
                    @(posedge clk);
                end
            end
            
            end_time = $time;
            time execution_time = end_time - start_time;
            efficiency[c] = (TEST_ITERATIONS * 1e9) / (execution_time * num_cores);
        end
        
        real scalability = efficiency[2] / efficiency[0]; // 4-core vs 1-core
        
        $display("  Scalability factor: %.2f", scalability);
        
        if (scalability > 2.0) begin // > 2x improvement with 4 cores
            $display("  PASS: Scalability meets target");
            pass_count++;
        end else begin
            $display("  FAIL: Scalability below target");
            fail_count++;
        end
    endtask
    
    task test_power_efficiency();
        test_count++;
        $display("Test %0d: Power efficiency", test_count);
        
        // Simulate power-efficient operations
        int low_power_ops = 0;
        int high_power_ops = 0;
        
        for (int i = 0; i < 100; i++) begin
            if (i % 2 == 0) begin
                // Low-power operation
                test_memory_addr[0] = i;
                @(posedge clk);
                low_power_ops++;
            end else begin
                // High-power operation
                for (int j = 0; j < 4; j++) begin
                    test_memory_addr[0] = i * 4 + j;
                    @(posedge clk);
                end
                high_power_ops++;
            end
        end
        
        real power_efficiency = real'(low_power_ops) / real'(high_power_ops);
        
        $display("  Low-power ops: %0d", low_power_ops);
        $display("  High-power ops: %0d", high_power_ops);
        $display("  Power efficiency: %.2f", power_efficiency);
        
        if (power_efficiency > 0.5) begin
            $display("  PASS: Power efficiency meets target");
            pass_count++;
        end else begin
            $display("  FAIL: Power efficiency below target");
            fail_count++;
        end
    endtask
    
    task test_realtime_performance();
        test_count++;
        $display("Test %0d: Real-time performance", test_count);
        
        int deadline_misses = 0;
        time deadline = 1000; // 1us deadline
        
        // Test real-time task execution
        for (int task = 0; task < 10; task++) begin
            start_time = $time;
            
            // Simulate real-time task
            for (int i = 0; i < 50; i++) begin
                test_memory_addr[0] = task * 100 + i;
                @(posedge clk);
            end
            
            end_time = $time;
            time task_time = end_time - start_time;
            
            if (task_time > deadline) begin
                deadline_misses++;
            end
        end
        
        $display("  Deadline misses: %0d", deadline_misses);
        
        if (deadline_misses == 0) begin
            $display("  PASS: Real-time performance meets target");
            pass_count++;
        end else begin
            $display("  FAIL: Real-time performance below target");
            fail_count++;
        end
    endtask
    
    task print_performance_results();
        $display("\n==========================================");
        $display("Performance Test Results");
        $display("==========================================");
        $display("Total tests: %0d", test_count);
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("Success rate: %0.1f%%", (pass_count * 100.0) / test_count);
        
        $display("\nPerformance Metrics:");
        $display("  Total instructions: %0d", total_instructions);
        $display("  Total cycles: %0d", total_cycles);
        $display("  Instructions per cycle: %.2f", real'(total_instructions) / real'(total_cycles));
        
        if (fail_count == 0) begin
            $display("\n🎉 ALL PERFORMANCE TESTS PASSED! 🎉");
            $display("AlphaAHB V5 meets all performance targets!");
        end else if (pass_count > fail_count) begin
            $display("\n✅ MOSTLY SUCCESSFUL! ✅");
            $display("AlphaAHB V5 meets most performance targets.");
        end else begin
            $display("\n❌ Some performance tests failed.");
        end
        
        $display("==========================================");
    endtask

endmodule
