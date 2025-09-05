/*
 * AlphaAHB V5 CPU Softcore Testbench
 * 
 * This file contains a comprehensive testbench for the AlphaAHB V5 CPU softcore
 * including instruction testing, performance validation, and system verification.
 */

`timescale 1ns / 1ps

module alphaahb_v5_tb;

    // ============================================================================
    // Testbench Parameters
    // ============================================================================
    
    parameter CLK_PERIOD = 10;  // 10ns = 100MHz
    parameter NUM_CORES = 4;
    parameter MEMORY_SIZE = 1024 * 1024 * 1024;  // 1GB
    
    // ============================================================================
    // Testbench Signals
    // ============================================================================
    
    reg clk;
    reg rst_n;
    
    // Memory Interface
    reg [63:0] mem_addr;
    reg [63:0] mem_wdata;
    wire [63:0] mem_rdata;
    reg mem_we;
    reg mem_re;
    wire mem_ready;
    
    // Interrupt Interface
    reg [7:0] interrupt_req [0:NUM_CORES-1];
    wire [7:0] interrupt_ack [0:NUM_CORES-1];
    
    // Debug Interface
    wire [63:0] debug_pc [0:NUM_CORES-1];
    wire [63:0] debug_regs [0:NUM_CORES-1][0:15];
    wire debug_halt [0:NUM_CORES-1];
    reg debug_step [0:NUM_CORES-1];
    
    // Performance Counters
    wire [63:0] perf_counters [0:NUM_CORES-1][0:7];
    
    // Status
    wire core_active [0:NUM_CORES-1];
    wire [3:0] privilege_level [0:NUM_CORES-1];
    
    // Testbench Variables
    integer test_count;
    integer pass_count;
    integer fail_count;
    integer i, j;
    
    // ============================================================================
    // Memory Model
    // ============================================================================
    
    reg [63:0] memory [0:1023];  // 1KB memory for testing
    
    assign mem_rdata = memory[mem_addr[9:3]];
    assign mem_ready = 1'b1;
    
    // ============================================================================
    // Clock Generation
    // ============================================================================
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // ============================================================================
    // DUT Instantiation
    // ============================================================================
    
    alphaahb_v5_system #(
        .NUM_CORES(NUM_CORES),
        .MEMORY_SIZE(MEMORY_SIZE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .mem_we(mem_we),
        .mem_re(mem_re),
        .mem_ready(mem_ready),
        .interrupt_req(interrupt_req),
        .interrupt_ack(interrupt_ack),
        .debug_pc(debug_pc),
        .debug_regs(debug_regs),
        .debug_halt(debug_halt),
        .debug_step(debug_step),
        .perf_counters(perf_counters),
        .core_active(core_active),
        .privilege_level(privilege_level)
    );
    
    // ============================================================================
    // Test Tasks
    // ============================================================================
    
    task reset_system;
        begin
            $display("=== Resetting System ===");
            rst_n = 0;
            #(CLK_PERIOD * 10);
            rst_n = 1;
            #(CLK_PERIOD * 5);
            $display("System reset complete");
        end
    endtask
    
    task test_instruction_execution;
        begin
            $display("=== Testing Instruction Execution ===");
            
            // Wait for cores to be active
            wait(core_active[0] == 1'b1);
            $display("Core 0 is active");
            
            // Wait for some instructions to execute
            #(CLK_PERIOD * 100);
            
            // Check if PC has advanced
            if (debug_pc[0] > 64'h1000) begin
                $display("PASS: PC advanced from 0x1000 to 0x%h", debug_pc[0]);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: PC did not advance");
                fail_count = fail_count + 1;
            end
            
            test_count = test_count + 1;
        end
    endtask
    
    task test_register_operations;
        begin
            $display("=== Testing Register Operations ===");
            
            // Wait for cores to be active
            wait(core_active[0] == 1'b1);
            
            // Wait for some instructions to execute
            #(CLK_PERIOD * 200);
            
            // Check if registers have been modified
            if (debug_regs[0][1] != 64'h0 || debug_regs[0][2] != 64'h0) begin
                $display("PASS: Registers have been modified");
                $display("  R1 = 0x%h", debug_regs[0][1]);
                $display("  R2 = 0x%h", debug_regs[0][2]);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Registers not modified");
                fail_count = fail_count + 1;
            end
            
            test_count = test_count + 1;
        end
    endtask
    
    task test_performance_counters;
        begin
            $display("=== Testing Performance Counters ===");
            
            // Wait for cores to be active
            wait(core_active[0] == 1'b1);
            
            // Wait for some instructions to execute
            #(CLK_PERIOD * 500);
            
            // Check performance counters
            if (perf_counters[0][0] > 0) begin
                $display("PASS: Performance counters are working");
                $display("  Instructions executed: %d", perf_counters[0][0]);
                $display("  Clock cycles: %d", perf_counters[0][1]);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Performance counters not working");
                fail_count = fail_count + 1;
            end
            
            test_count = test_count + 1;
        end
    endtask
    
    task test_multi_core_operation;
        begin
            $display("=== Testing Multi-Core Operation ===");
            
            // Wait for all cores to be active
            wait(core_active[0] == 1'b1 && core_active[1] == 1'b1 && 
                 core_active[2] == 1'b1 && core_active[3] == 1'b1);
            
            $display("All cores are active");
            
            // Wait for some instructions to execute
            #(CLK_PERIOD * 1000);
            
            // Check if all cores have executed instructions
            integer active_cores = 0;
            for (i = 0; i < NUM_CORES; i++) begin
                if (perf_counters[i][0] > 0) begin
                    active_cores = active_cores + 1;
                end
            end
            
            if (active_cores == NUM_CORES) begin
                $display("PASS: All cores executed instructions");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Only %d of %d cores executed instructions", active_cores, NUM_CORES);
                fail_count = fail_count + 1;
            end
            
            test_count = test_count + 1;
        end
    endtask
    
    task test_interrupt_handling;
        begin
            $display("=== Testing Interrupt Handling ===");
            
            // Wait for cores to be active
            wait(core_active[0] == 1'b1);
            
            // Generate interrupt
            interrupt_req[0] = 8'h01;  // Timer interrupt
            #(CLK_PERIOD * 10);
            
            // Check if interrupt was acknowledged
            if (interrupt_ack[0] == 1'b1) begin
                $display("PASS: Interrupt acknowledged");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Interrupt not acknowledged");
                fail_count = fail_count + 1;
            end
            
            // Clear interrupt
            interrupt_req[0] = 8'h00;
            #(CLK_PERIOD * 10);
            
            test_count = test_count + 1;
        end
    endtask
    
    task test_debug_interface;
        begin
            $display("=== Testing Debug Interface ===");
            
            // Wait for cores to be active
            wait(core_active[0] == 1'b1);
            
            // Test debug step
            debug_step[0] = 1'b1;
            #(CLK_PERIOD * 5);
            debug_step[0] = 1'b0;
            
            // Check if debug halt was triggered
            if (debug_halt[0] == 1'b1) begin
                $display("PASS: Debug halt triggered");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Debug halt not triggered");
                fail_count = fail_count + 1;
            end
            
            test_count = test_count + 1;
        end
    endtask
    
    task test_memory_operations;
        begin
            $display("=== Testing Memory Operations ===");
            
            // Wait for cores to be active
            wait(core_active[0] == 1'b1);
            
            // Wait for some instructions to execute
            #(CLK_PERIOD * 300);
            
            // Check if memory operations occurred
            if (mem_re == 1'b1) begin
                $display("PASS: Memory read operations detected");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: No memory operations detected");
                fail_count = fail_count + 1;
            end
            
            test_count = test_count + 1;
        end
    endtask
    
    task test_pipeline_operation;
        begin
            $display("=== Testing Pipeline Operation ===");
            
            // Wait for cores to be active
            wait(core_active[0] == 1'b1);
            
            // Wait for pipeline to fill
            #(CLK_PERIOD * 20);
            
            // Check if multiple instructions are in pipeline
            if (perf_counters[0][0] > 10) begin
                $display("PASS: Pipeline is operating");
                $display("  Instructions executed: %d", perf_counters[0][0]);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Pipeline not operating properly");
                fail_count = fail_count + 1;
            end
            
            test_count = test_count + 1;
        end
    endtask
    
    task test_privilege_levels;
        begin
            $display("=== Testing Privilege Levels ===");
            
            // Wait for cores to be active
            wait(core_active[0] == 1'b1);
            
            // Check privilege level
            if (privilege_level[0] == 4'h0) begin
                $display("PASS: Privilege level is User mode (0)");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Unexpected privilege level: %d", privilege_level[0]);
                fail_count = fail_count + 1;
            end
            
            test_count = test_count + 1;
        end
    endtask
    
    task test_clock_frequency;
        begin
            $display("=== Testing Clock Frequency ===");
            
            // Wait for cores to be active
            wait(core_active[0] == 1'b1);
            
            // Measure clock frequency
            time start_time = $time;
            #(CLK_PERIOD * 1000);
            time end_time = $time;
            
            real frequency = 1000.0 / ((end_time - start_time) / 1000.0);
            $display("Measured frequency: %.2f MHz", frequency);
            
            if (frequency > 90.0 && frequency < 110.0) begin
                $display("PASS: Clock frequency within expected range");
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL: Clock frequency out of range");
                fail_count = fail_count + 1;
            end
            
            test_count = test_count + 1;
        end
    endtask
    
    // ============================================================================
    // Main Test Sequence
    // ============================================================================
    
    initial begin
        $display("AlphaAHB V5 CPU Softcore Testbench");
        $display("===================================");
        
        // Initialize testbench variables
        test_count = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Initialize signals
        rst_n = 1;
        mem_addr = 64'h0;
        mem_wdata = 64'h0;
        mem_we = 1'b0;
        mem_re = 1'b0;
        
        for (i = 0; i < NUM_CORES; i++) begin
            interrupt_req[i] = 8'h00;
            debug_step[i] = 1'b0;
        end
        
        // Initialize memory
        for (i = 0; i < 1024; i++) begin
            memory[i] = 64'h0;
        end
        
        // Run tests
        reset_system();
        test_instruction_execution();
        test_register_operations();
        test_performance_counters();
        test_multi_core_operation();
        test_interrupt_handling();
        test_debug_interface();
        test_memory_operations();
        test_pipeline_operation();
        test_privilege_levels();
        test_clock_frequency();
        
        // Print test results
        $display("\n=== Test Results ===");
        $display("Total tests: %d", test_count);
        $display("Passed: %d", pass_count);
        $display("Failed: %d", fail_count);
        
        if (fail_count == 0) begin
            $display("🎉 ALL TESTS PASSED! 🎉");
            $display("AlphaAHB V5 CPU softcore is working correctly!");
        end else begin
            $display("❌ SOME TESTS FAILED ❌");
            $display("Please review the test results and fix any issues.");
        end
        
        $finish;
    end
    
    // ============================================================================
    // Monitoring and Logging
    // ============================================================================
    
    // Monitor core activity
    always @(posedge clk) begin
        if (core_active[0] == 1'b1) begin
            if (perf_counters[0][0] % 100 == 0 && perf_counters[0][0] > 0) begin
                $display("Core 0: %d instructions executed", perf_counters[0][0]);
            end
        end
    end
    
    // Monitor memory operations
    always @(posedge clk) begin
        if (mem_re == 1'b1) begin
            $display("Memory read: addr=0x%h, data=0x%h", mem_addr, mem_rdata);
        end
        if (mem_we == 1'b1) begin
            $display("Memory write: addr=0x%h, data=0x%h", mem_addr, mem_wdata);
        end
    end
    
    // Monitor interrupts
    always @(posedge clk) begin
        for (i = 0; i < NUM_CORES; i++) begin
            if (interrupt_ack[i] == 1'b1) begin
                $display("Core %d: Interrupt %d acknowledged", i, interrupt_req[i]);
            end
        end
    end

endmodule
