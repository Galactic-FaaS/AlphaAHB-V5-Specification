/*
 * AlphaAHB V5 CPU Softcore - Main Core Module
 * 
 * This is the top-level module that integrates all the sophisticated
 * components of the AlphaAHB V5 architecture, embracing full complexity.
 */

`include "ExecutionUnits.sv"
`include "VectorAIUnits.sv"
`include "MemoryHierarchy.sv"
`include "PipelineControl.sv"

// Package definitions
package alphaahb_v5_pkg;
    typedef struct packed {
        logic [63:0] data;
        logic [3:0]  opcode;
        logic [3:0]  funct;
        logic [5:0]  rd, rs1, rs2;
        logic [63:0] immediate;
    } instruction_t;
    
    typedef struct packed {
        logic zero;
        logic carry;
        logic overflow;
        logic negative;
    } alu_flags_t;
endpackage

package alphaahb_v5_vector_pkg;
    typedef logic [511:0] vector_512_t;
    typedef logic [511:0] ai_vector_t;
endpackage

module AlphaAHBV5Core (
    // Clock and reset
    input  logic clk,
    input  logic rst_n,
    
    // Core configuration
    input  logic [2:0]  core_id,
    input  logic [1:0]  thread_id,
    input  logic [31:0] config_reg,
    
    // Instruction fetch interface
    output logic [63:0] if_addr,
    output logic        if_req,
    input  logic [63:0] if_data,
    input  logic        if_valid,
    
    // Data memory interface
    output logic [63:0] mem_addr,
    output logic [63:0] mem_write_data,
    output logic [7:0]  mem_write_mask,
    output logic        mem_read_req,
    output logic        mem_write_req,
    input  logic [63:0] mem_read_data,
    input  logic        mem_read_valid,
    input  logic        mem_write_ack,
    
    // Interrupt interface
    input  logic [7:0]  interrupt_req,
    output logic        interrupt_ack,
    
    // Debug interface
    output logic [63:0] debug_pc,
    output logic [63:0] debug_regs [63:0],
    output logic [31:0] debug_flags,
    output logic        debug_halt,
    
    // Performance counters
    output logic [31:0] perf_inst_retired,
    output logic [31:0] perf_cycles,
    output logic [31:0] perf_cache_misses,
    output logic [31:0] perf_branch_mispredicts
);

    // ============================================================================
    // Internal Signals
    // ============================================================================
    
    // Register file
    logic [63:0] gpr [63:0];           // General purpose registers
    logic [31:0] fpr [63:0];           // Floating-point registers
    alphaahb_v5_vector_pkg::vector_512_t vpr [31:0];  // Vector registers
    
    // Special purpose registers
    logic [63:0] pc;                   // Program counter
    logic [63:0] sp;                   // Stack pointer
    logic [63:0] fp;                   // Frame pointer
    logic [63:0] lr;                   // Link register
    logic [31:0] flags;                // Status flags
    logic [31:0] core_id_reg;          // Core ID register
    logic [31:0] thread_id_reg;        // Thread ID register
    
    // Pipeline stages
    logic [63:0] fetch_pc;
    logic [63:0] decode_pc;
    logic [63:0] execute_pc;
    logic [63:0] memory_pc;
    logic [63:0] writeback_pc;
    
    // Instruction decoding
    alphaahb_v5_pkg::instruction_t current_inst;
    logic [3:0]  opcode;
    logic [3:0]  funct;
    logic [5:0]  rd, rs1, rs2;
    logic [63:0] immediate;
    logic [63:0] rs1_data, rs2_data, rs3_data;
    logic        rs1_ready, rs2_ready;
    
    // Execution units
    logic [63:0] alu_result;
    alphaahb_v5_pkg::alu_flags_t alu_flags;
    logic [31:0] fpu_result;
    logic        fpu_invalid, fpu_overflow, fpu_underflow, fpu_inexact, fpu_div_zero;
    alphaahb_v5_vector_pkg::vector_512_t vector_result;
    logic        vector_valid, vector_exception;
    alphaahb_v5_vector_pkg::ai_vector_t ai_result;
    logic        ai_valid, ai_exception;
    
    // Memory hierarchy
    logic [63:0] l1_read_data;
    logic        l1_hit, l1_miss, l1_ready;
    logic [47:0] physical_addr;
    logic        mmu_valid, page_fault, tlb_miss;
    
    // Pipeline control
    logic [63:0] predicted_target;
    logic        predicted_taken, prediction_valid;
    alphaahb_v5_pipeline_pkg::reservation_station_entry_t issued_inst;
    logic        issue_valid;
    alphaahb_v5_pipeline_pkg::reorder_buffer_entry_t commit_inst;
    logic        commit_valid;
    alphaahb_v5_pipeline_pkg::load_store_queue_entry_t lsq_commit_inst;
    logic        lsq_commit_valid;
    
    // Control signals
    logic        fetch_en, decode_en, execute_en, memory_en, writeback_en;
    logic        pipeline_stall, pipeline_flush;
    logic        exception_occurred;
    logic [3:0]  exception_code;
    
    // Performance counters
    logic [31:0] inst_retired_count;
    logic [31:0] cycle_count;
    logic [31:0] cache_miss_count;
    logic [31:0] branch_mispredict_count;
    
    // ============================================================================
    // Instantiate Advanced Components
    // ============================================================================
    
    // Advanced Integer ALU
    AdvancedIntegerALU alu_inst (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .funct(funct),
        .result(alu_result),
        .flags(alu_flags)
    );
    
    // Advanced Floating-Point Unit
    AdvancedFloatingPointUnit fpu_inst (
        .rs1_data(rs1_data[31:0]),
        .rs2_data(rs2_data[31:0]),
        .rs3_data(rs3_data[31:0]), // Added Accumulator operand
        .funct(funct),
        .rounding_mode(flags[2:0]),
        .result(fpu_result),
        .invalid(fpu_invalid),
        .overflow(fpu_overflow),
        .underflow(fpu_underflow),
        .inexact(fpu_inexact),
        .divide_by_zero(fpu_div_zero)
    );
    
    // Advanced Vector Unit
    AdvancedVectorUnit vector_inst (
        .v1_data(vpr[rs1[4:0]]),
        .v2_data(vpr[rs2[4:0]]),
        .funct(funct),
        .mask(immediate[7:0]),
        .result(vector_result),
        .valid(vector_valid),
        .exception(vector_exception)
    );
    
    // AI/ML input selection based on instruction encoding
    // Bits [47:32] of immediate specify weight buffer address
    // Bits [31:16] of immediate specify bias register
    // Bits [15:0] of immediate specify operation config
    logic [511:0] ai_state_data;
    logic [511:0] ai_input_data;
    logic [511:0] ai_weight_data;
    logic [511:0] ai_bias_data;
    
    assign ai_input_data = vpr[rs1[4:0]];         // Input from vector register rs1 (full 512 bits)
    assign ai_weight_data = vpr[rs2[4:0]];        // Weights from vector register rs2 (full 512 bits)
    assign ai_bias_data = {8{gpr[immediate[21:16]]}};  // Bias replicated from GPR (8x64 = 512 bits)
    assign ai_state_data = vpr[rd[4:0]];          // State/Accumulator from destination register
    
    AdvancedAIMLUnit ai_inst (
        .clk(clk),
        .rst_n(rst_n),
        .input_data(ai_input_data),   // Real input from vector register
        .weight_data(ai_weight_data), // Real weights from vector register
        .bias_data(ai_bias_data),     // Real bias from general purpose register
        .state_data(ai_state_data),   // Real state from destination register
        .funct(funct),
        .config(immediate[7:0]),
        .result(ai_result),
        .valid(ai_valid),
        .exception(ai_exception)
    );
    
    // Advanced L1 Data Cache
    AdvancedL1DataCache l1_cache_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(mem_addr),
        .write_data(mem_write_data),
        .write_mask(mem_write_mask),
        .read_en(mem_read_req),
        .write_en(mem_write_req),
        .size(3'b011),  // 64-bit access
        .read_data(l1_read_data),
        .hit(l1_hit),
        .miss(l1_miss),
        .ready(l1_ready)
    );
    
    // TLB Control Signals
    logic tlb_write_enable;
    alphaahb_v5_memory_pkg::tlb_entry_t tlb_write_data;
    
    // Cast RS1/RS2 data to TLB entry format (simplified mapping for core injection)
    // Assuming rs1_data contains VPN/ASID and rs2_data contains PPN/Flags
    // For this hardening, we assume specific packing.
    assign tlb_write_data.vpn = rs1_data[63:12]; // Virtual Page Number
    assign tlb_write_data.ppn = rs2_data[47:0];  // Physical Page Number
    assign tlb_write_data.valid = 1'b1;
    assign tlb_write_data.privilege = rs2_data[63:62]; // Priv Level
    
    // Advanced Memory Management Unit
    AdvancedMMU mmu_inst (
        .clk(clk),
        .rst_n(rst_n),
        .virtual_addr(mem_addr),
        .privilege_level(flags[1:0]),
        .access_type(3'b001),  // Read access
        .physical_addr(physical_addr),
        .valid(mmu_valid),
        .page_fault(page_fault),
        .tlb_miss(tlb_miss),
        .tlb_update(tlb_write_enable), // Driven by System Op
        .tlb_entry(tlb_write_data),    // Driven by Register Data
        .pte_addr(),
        .pte_read_req(),
        .pte_data(0),
        .pte_read_valid(1'b0)
    );
    
    // Advanced Branch Predictor with proper feedback loop
    // Branch outcome feedback comes from execute stage comparison
    logic        branch_actually_taken;
    logic [63:0] branch_actual_target;
    logic        branch_update_valid;
    
    // Determine if branch was actually taken based on execute stage results
    always_comb begin
        branch_actually_taken = 1'b0;
        branch_actual_target = execute_pc + 8;  // Default: fall through
        branch_update_valid = 1'b0;
        
        // Check if current instruction in execute stage is a branch
        if (opcode == 4'h3) begin  // Branch opcode
            case (funct)
                4'h0: branch_actually_taken = alu_flags.zero;              // BEQ
                4'h1: branch_actually_taken = !alu_flags.zero;             // BNE
                4'h2: branch_actually_taken = alu_flags.negative;          // BLT
                4'h3: branch_actually_taken = !alu_flags.negative;         // BGE
                4'h4: branch_actually_taken = !alu_flags.negative && !alu_flags.zero; // BGT
                4'h5: branch_actually_taken = alu_flags.negative || alu_flags.zero;   // BLE
                4'hC: branch_actually_taken = alu_flags.carry;             // BC
                4'hD: branch_actually_taken = alu_flags.overflow;          // BO
                default: branch_actually_taken = 1'b0;
            endcase
            branch_actual_target = rs1_data + immediate;  // Branch target
            branch_update_valid = execute_en;
        end
    end
    
    AdvancedBranchPredictor branch_predictor_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pc(pc),
        .branch_taken(branch_actually_taken),     // Real branch outcome from execute
        .actual_target(branch_actual_target),     // Real branch target
        .update(branch_update_valid),             // Update predictor on branch retirement
        .predicted_target(predicted_target),
        .predicted_taken(predicted_taken),
        .prediction_valid(prediction_valid)
    );
    
    // Advanced Reservation Station
    AdvancedReservationStation reservation_station_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pc(pc),
        .opcode(opcode),
        .funct(funct),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .immediate(immediate),
        .rs1_ready(rs1_ready),
        .rs2_ready(rs2_ready),
        .issue_en(execute_en),
        .inst_type(alphaahb_v5_pipeline_pkg::INT_ALU),
        .full(),
        .empty(),
        .issued_inst(issued_inst),
        .issue_valid(issue_valid)
    );
    
    // Advanced Reorder Buffer
    AdvancedReorderBuffer reorder_buffer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pc(pc),
        .rd(rd),
        .result(alu_result),
        .exception(exception_occurred),
        .exception_code(exception_code),
        .inst_type(alphaahb_v5_pipeline_pkg::INT_ALU),
        .allocate_en(decode_en),
        .commit_en(writeback_en),
        .full(),
        .empty(),
        .commit_inst(commit_inst),
        .commit_valid(commit_valid)
    );
    
    // Advanced Load/Store Queue Wires
    logic [63:0] lsq_mem_addr;
    logic [63:0] lsq_mem_wdata;
    logic [7:0]  lsq_mem_mask;
    logic        lsq_mem_load;
    logic        lsq_mem_store;
    logic [4:0]  lsq_mem_tag;
    logic        lsq_mem_valid;
    
    // Advanced Load/Store Queue
    AdvancedLoadStoreQueue load_store_queue_inst (
        .clk(clk),
        .rst_n(rst_n),
        .pc(pc),
        .addr(mem_addr_buffer), // Input from Execute stage (allocation addr)
        .data(mem_wdata_buffer), // Input from Execute stage (store data)
        .mask(mem_mask_buffer),
        .is_load(mem_read_req_alloc), // Allocation request type
        .is_store(mem_write_req_alloc),
        .allocate_en(decode_en), // Allocate on Decode
        .commit_en(writeback_en), // Retire on Writeback
        .mem_op_complete(l1_hit || !l1_miss), // Ack when L1 accepts or hits
        .mem_op_tag(lsq_mem_tag), // Tag of the op currently interacting with memory
        
        .full(), // Should stall decode if full
        .empty(),
        .commit_inst(lsq_commit_inst),
        .commit_valid(lsq_commit_valid),
        
        // Memory Issue Interface
        .mem_issue_addr(lsq_mem_addr),
        .mem_issue_data(lsq_mem_wdata),
        .mem_issue_mask(lsq_mem_mask),
        .mem_issue_load(lsq_mem_load),
        .mem_issue_store(lsq_mem_store),
        .mem_issue_tag(lsq_mem_tag), // Output tag to Memory System
        .mem_issue_valid(lsq_mem_valid),
        .mem_issue_ready(!pipeline_stall) // Cache ready to accept?
    );
    
    // ============================================================================
    // Instruction Fetch Stage
    // ============================================================================
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fetch_pc <= 64'h1000;  // Start address
            if_req <= 1'b0;
        end else if (fetch_en && !pipeline_stall) begin
            if_req <= 1'b1;
            if_addr <= fetch_pc;
            fetch_pc <= predicted_taken ? predicted_target : fetch_pc + 8;
        end else begin
            if_req <= 1'b0;
        end
    end
    
    // ============================================================================
    // Instruction Decode Stage
    // ============================================================================
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decode_pc <= 0;
            current_inst <= 0;
        end else if (decode_en && !pipeline_stall) begin
            decode_pc <= fetch_pc;
            current_inst <= if_data;
            
            // Decode instruction fields according to AlphaAHB V5 encoding
            opcode <= if_data[63:60];
            funct <= if_data[59:56];
            rs2 <= if_data[55:52];
            rs1 <= if_data[51:48];
            immediate <= {{48{if_data[47]}}, if_data[47:32]};  // Sign extend 16-bit immediate
            
            // Destination register decoding varies by instruction type:
            // R-type (opcode 0x0-0x2): rd is bits [53:48]
            // I-type (opcode 0x3-0x5): rd is bits [53:48], immediate in [47:32]
            // V-type (opcode 0x6-0x7): vd is bits [53:48]
            // A-type (opcode 0x8-0x9): ad is bits [53:48]
            case (if_data[63:60])  // opcode
                4'h0, 4'h1, 4'h2: rd <= if_data[53:48];  // R-type: rd field
                4'h3: rd <= 6'h0;                         // Branch: no destination
                4'h4, 4'h5: rd <= if_data[53:48];        // Load/Store: rd field
                4'h6, 4'h7: rd <= {1'b0, if_data[52:48]}; // Vector: vd (5-bit)
                4'h8, 4'h9: rd <= {2'b0, if_data[51:48]}; // AI/ML: ad (4-bit)
                default: rd <= if_data[53:48];           // Default extraction
            endcase
            
            // Read register data
            rs1_data <= gpr[if_data[51:48]];
            rs2_data <= gpr[if_data[55:52]];
            rs3_data <= gpr[if_data[53:48]]; // Read destination (accumulator) for FMA

            rs1_ready <= 1'b1;
            rs2_ready <= 1'b1;
        end
    end
    
    // ============================================================================
    // Execute Stage
    // ============================================================================
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            execute_pc <= 0;
        end else if (execute_en && !pipeline_stall) begin
            execute_pc <= decode_pc;
            
            // Execute based on instruction type
            case (opcode)
                4'h1: begin // Integer operations
                    // ALU result already computed
                end
                4'h6: begin // Floating-point operations
                    // FPU result already computed
                end
                4'h7: begin // Vector operations
                    // Vector result already computed
                end
                4'h8: begin // AI/ML operations
                    // AI result already computed
                end
                4'h9: begin // SYSTEM Operations (TLB, CSR, etc)
                    if (funct == 4'h1) begin // TLB Write Instruction
                        tlb_write_req <= 1'b1; // Signal to writeback/commit stage
                    end
                end
                default: begin
                    // Other operations
                end
            endcase
        end else begin
            tlb_write_req <= 1'b0;
        end
    end
    
    logic tlb_write_req; // Pipeline reg
    
    // ============================================================================
    // Memory Stage
    // ============================================================================
    
    // Rename the pipeline vars to _alloc
    logic mem_write_req_alloc;
    logic mem_read_req_alloc; // Added missing decl
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            memory_pc <= 0;
            mem_read_req_alloc <= 1'b0; // Reset internal alloc signals
            mem_write_req_alloc <= 1'b0;
        end else if (memory_en && !pipeline_stall) begin
            memory_pc <= execute_pc;
            
            // Memory Stage: Now driven by LSQ for allocation
            if (opcode == 4'h4) begin // Load
                 mem_read_req_alloc <= 1'b1;
                 mem_addr_buffer <= rs1_data + immediate; // Need buffer, can't drive output mem_addr
                 mem_write_req_alloc <= 1'b0;
            end else if (opcode == 4'h5) begin // Store
                 mem_write_req_alloc <= 1'b1;
                 mem_addr_buffer <= rs1_data + immediate;
                 mem_wdata_buffer <= rs2_data;
                 mem_read_req_alloc <= 1'b0;
            end else begin
                 mem_read_req_alloc <= 1'b0;
                 mem_write_req_alloc <= 1'b0;
            end
        end else begin
             // Hold or clear? If pipeline stall, hold.
             // If not stall but no valid instruction (bubble), clear.
             // Logic above handles "memory_en" which usually implies valid.
        end
    end
    
    // Internal buffers for inputs to LSQ (since ports used to be outputs)
    logic [63:0] mem_addr_buffer; 
    logic [63:0] mem_wdata_buffer;
    logic [7:0]  mem_mask_buffer;
    assign mem_mask_buffer = 8'hFF; // Constant for now

    // Wire LSQ outputs to Core Memory Interface (Ports)
    assign mem_addr       = lsq_mem_addr;
    assign mem_write_data = lsq_mem_wdata;
    assign mem_write_mask = lsq_mem_mask; // Or lsq output
    assign mem_read_req   = lsq_mem_valid && lsq_mem_load;
    assign mem_write_req  = lsq_mem_valid && lsq_mem_store;
    
endmodule
