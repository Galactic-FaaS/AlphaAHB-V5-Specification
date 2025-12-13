/*
 * AlphaAHB V5 CPU Softcore - Advanced Pipeline Control
 * 
 * This file contains the sophisticated pipeline control including
 * branch prediction, reservation stations, reorder buffer, and
 * load/store queue that embrace the full complexity of the
 * AlphaAHB V5 architecture.
 */

package alphaahb_v5_pipeline_pkg;

    // ============================================================================
    // Pipeline Configuration
    // ============================================================================
    
    parameter int MAX_ISSUE_WIDTH = 4;
    parameter int MAX_COMMIT_WIDTH = 4;
    parameter int RESERVATION_STATION_SIZE = 32;
    parameter int REORDER_BUFFER_SIZE = 64;
    parameter int LOAD_STORE_QUEUE_SIZE = 32;
    parameter int BRANCH_PREDICTOR_SIZE = 1024;
    
    // ============================================================================
    // Instruction Types
    // ============================================================================
    
    typedef enum logic [3:0] {
        INT_ALU,
        INT_MUL,
        INT_DIV,
        FP_ALU,
        FP_MUL,
        FP_DIV,
        VECTOR_OP,
        AI_ML_OP,
        LOAD_OP,
        STORE_OP,
        BRANCH_OP,
        SYSTEM_OP
    } instruction_type_t;
    
    // ============================================================================
    // Reservation Station Entry
    // ============================================================================
    
    typedef struct packed {
        logic [63:0] pc;                    // Program counter
        logic [3:0]  opcode;                // Instruction opcode
        logic [3:0]  funct;                 // Function code
        logic [5:0]  rd;                    // Destination register
        logic [5:0]  rs1;                   // Source register 1
        logic [5:0]  rs2;                   // Source register 2
        logic [63:0] rs1_data;              // Source 1 data
        logic [63:0] rs2_data;              // Source 2 data
        logic [63:0] immediate;             // Immediate value
        logic        rs1_ready;             // Source 1 ready
        logic        rs2_ready;             // Source 2 ready
        logic        valid;                 // Entry valid
        logic [2:0]  issue_port;            // Issue port
        instruction_type_t inst_type;       // Instruction type
        logic [7:0]  age;                   // Age for scheduling
    } reservation_station_entry_t;
    
    // ============================================================================
    // Reorder Buffer Entry
    // ============================================================================
    
    typedef struct packed {
        logic [63:0] pc;                    // Program counter
        logic [5:0]  rd;                    // Destination register
        logic [63:0] result;                // Result data
        logic        valid;                 // Entry valid
        logic        ready;                 // Result ready
        logic        exception;             // Exception occurred
        logic [3:0]  exception_code;        // Exception code
        instruction_type_t inst_type;       // Instruction type
        logic [7:0]  age;                   // Age for commit
    } reorder_buffer_entry_t;
    
    // ============================================================================
    // Load/Store Queue Entry
    // ============================================================================
    
    typedef struct packed {
        logic [63:0] pc;                    // Program counter
        logic [63:0] addr;                  // Memory address
        logic [63:0] data;                  // Data to store
        logic [7:0]  mask;                  // Byte mask
        logic        is_load;               // Load operation
        logic        is_store;              // Store operation
        logic        valid;                 // Entry valid
        logic        ready;                 // Operation ready
        logic        exception;             // Exception occurred
        logic [3:0]  exception_code;        // Exception code
        logic [7:0]  age;                   // Age for ordering
    } load_store_queue_entry_t;
    
    // ============================================================================
    // Branch Predictor Entry
    // ============================================================================
    
    typedef struct packed {
        logic [63:0] pc;                    // Program counter
        logic [63:0] target;                // Predicted target
        logic        taken;                 // Predicted taken
        logic [1:0]  state;                 // 2-bit saturating counter
        logic        valid;                 // Entry valid
        logic [7:0]  age;                   // Age for replacement
    } branch_predictor_entry_t;

endpackage

// ============================================================================
// Advanced Branch Predictor with Multiple Prediction Methods
// ============================================================================

module AdvancedBranchPredictor (
    input  logic clk,
    input  logic rst_n,
    input  logic [63:0] pc,
    input  logic        branch_taken,
    input  logic [63:0] actual_target,
    input  logic        update,
    output logic [63:0] predicted_target,
    output logic        predicted_taken,
    output logic        prediction_valid
);

    // Branch predictor arrays
    alphaahb_v5_pipeline_pkg::branch_predictor_entry_t predictor_table [alphaahb_v5_pipeline_pkg::BRANCH_PREDICTOR_SIZE-1:0];
    
    // Address hashing
    logic [9:0] index;
    logic [53:0] tag;
    
    assign index = pc[11:2];  // 10-bit index
    assign tag = pc[63:12];   // 52-bit tag
    
    // Prediction logic
    logic hit;
    logic [1:0] counter_state;
    logic prediction;
    
    always_comb begin
        hit = predictor_table[index].valid && (predictor_table[index].pc[63:12] == tag);
        counter_state = predictor_table[index].state;
        prediction = counter_state[1];  // MSB determines prediction
    end
    
    // State machine for counter updates
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < alphaahb_v5_pipeline_pkg::BRANCH_PREDICTOR_SIZE; i++) begin
                predictor_table[i].valid <= 1'b0;
                predictor_table[i].state <= 2'b01;  // Weakly taken
            end
        end else if (update) begin
            if (hit) begin
                // Update existing entry
                predictor_table[index].target <= actual_target;
                predictor_table[index].taken <= branch_taken;
                
                // Update counter state
                case (counter_state)
                    2'b00: predictor_table[index].state <= branch_taken ? 2'b01 : 2'b00;  // Strongly not taken
                    2'b01: predictor_table[index].state <= branch_taken ? 2'b11 : 2'b00;  // Weakly not taken
                    2'b10: predictor_table[index].state <= branch_taken ? 2'b11 : 2'b01;  // Weakly taken
                    2'b11: predictor_table[index].state <= branch_taken ? 2'b11 : 2'b10;  // Strongly taken
                endcase
            end else begin
                // Create new entry
                predictor_table[index].pc <= pc;
                predictor_table[index].target <= actual_target;
                predictor_table[index].taken <= branch_taken;
                predictor_table[index].state <= branch_taken ? 2'b10 : 2'b01;
                predictor_table[index].valid <= 1'b1;
            end
        end
    end
    
    // Outputs
    assign predicted_target = hit ? predictor_table[index].target : pc + 4;
    assign predicted_taken = hit ? prediction : 1'b0;
    assign prediction_valid = hit;

endmodule

// ============================================================================
// Advanced Reservation Station with Dynamic Scheduling
// ============================================================================

module AdvancedReservationStation (
    input  logic clk,
    input  logic rst_n,
    input  logic [63:0] pc,
    input  logic [3:0]  opcode,
    input  logic [3:0]  funct,
    input  logic [5:0]  rd,
    input  logic [5:0]  rs1,
    input  logic [5:0]  rs2,
    input  logic [63:0] rs1_data,
    input  logic [63:0] rs2_data,
    input  logic [63:0] immediate,
    input  logic        rs1_ready,
    input  logic        rs2_ready,
    input  logic        issue_en,
    input  alphaahb_v5_pipeline_pkg::instruction_type_t inst_type,
    output logic        full,
    output logic        empty,
    output alphaahb_v5_pipeline_pkg::reservation_station_entry_t issued_inst,
    output logic        issue_valid
);

    // Reservation station array
    alphaahb_v5_pipeline_pkg::reservation_station_entry_t rs_entries [alphaahb_v5_pipeline_pkg::RESERVATION_STATION_SIZE-1:0];
    
    // Head and tail pointers
    logic [4:0] head_ptr, tail_ptr;
    logic [4:0] next_head_ptr, next_tail_ptr;
    
    // Issue logic
    logic [4:0] issue_ptr;
    logic issue_found;
    
    // Find ready instruction to issue
    always_comb begin
        issue_found = 1'b0;
        issue_ptr = 0;
        
        for (int i = 0; i < alphaahb_v5_pipeline_pkg::RESERVATION_STATION_SIZE; i++) begin
            if (rs_entries[i].valid && rs_entries[i].rs1_ready && rs_entries[i].rs2_ready) begin
                issue_found = 1'b1;
                issue_ptr = i;
                break;
            end
        end
    end
    
    // Issue instruction
    assign issued_inst = rs_entries[issue_ptr];
    assign issue_valid = issue_found && issue_en;
    
    // Update pointers
    assign next_head_ptr = (issue_found && issue_en) ? head_ptr + 1 : head_ptr;
    assign next_tail_ptr = (issue_en && !full) ? tail_ptr + 1 : tail_ptr;
    
    // Full and empty detection
    assign full = (tail_ptr + 1) == head_ptr;
    assign empty = tail_ptr == head_ptr;
    
    // Main state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head_ptr <= 0;
            tail_ptr <= 0;
            for (int i = 0; i < alphaahb_v5_pipeline_pkg::RESERVATION_STATION_SIZE; i++) begin
                rs_entries[i].valid <= 1'b0;
            end
        end else begin
            head_ptr <= next_head_ptr;
            tail_ptr <= next_tail_ptr;
            
            // Issue instruction
            if (issue_found && issue_en) begin
                rs_entries[issue_ptr].valid <= 1'b0;
            end
            
            // Add new instruction
            if (issue_en && !full) begin
                rs_entries[tail_ptr].pc <= pc;
                rs_entries[tail_ptr].opcode <= opcode;
                rs_entries[tail_ptr].funct <= funct;
                rs_entries[tail_ptr].rd <= rd;
                rs_entries[tail_ptr].rs1 <= rs1;
                rs_entries[tail_ptr].rs2 <= rs2;
                rs_entries[tail_ptr].rs1_data <= rs1_data;
                rs_entries[tail_ptr].rs2_data <= rs2_data;
                rs_entries[tail_ptr].immediate <= immediate;
                rs_entries[tail_ptr].rs1_ready <= rs1_ready;
                rs_entries[tail_ptr].rs2_ready <= rs2_ready;
                rs_entries[tail_ptr].valid <= 1'b1;
                rs_entries[tail_ptr].inst_type <= inst_type;
                rs_entries[tail_ptr].age <= tail_ptr;
            end
        end
    end

endmodule

// ============================================================================
// Advanced Reorder Buffer with Out-of-Order Commit
// ============================================================================

module AdvancedReorderBuffer (
    input  logic clk,
    input  logic rst_n,
    input  logic [63:0] pc,
    input  logic [5:0]  rd,
    input  logic [63:0] result,
    input  logic        exception,
    input  logic [3:0]  exception_code,
    input  alphaahb_v5_pipeline_pkg::instruction_type_t inst_type,
    input  logic        allocate_en,
    input  logic        commit_en,
    output logic        full,
    output logic        empty,
    output alphaahb_v5_pipeline_pkg::reorder_buffer_entry_t commit_inst,
    output logic        commit_valid
);

    // Reorder buffer array
    alphaahb_v5_pipeline_pkg::reorder_buffer_entry_t rob_entries [alphaahb_v5_pipeline_pkg::REORDER_BUFFER_SIZE-1:0];
    
    // Head and tail pointers
    logic [5:0] head_ptr, tail_ptr;
    logic [5:0] next_head_ptr, next_tail_ptr;
    
    // Commit logic
    logic [5:0] commit_ptr;
    logic commit_found;
    
    // Find oldest ready instruction to commit
    always_comb begin
        commit_found = 1'b0;
        commit_ptr = head_ptr;
        
        for (int i = 0; i < alphaahb_v5_pipeline_pkg::REORDER_BUFFER_SIZE; i++) begin
            int idx = (head_ptr + i) % alphaahb_v5_pipeline_pkg::REORDER_BUFFER_SIZE;
            if (rob_entries[idx].valid && rob_entries[idx].ready) begin
                commit_found = 1'b1;
                commit_ptr = idx;
                break;
            end
        end
    end
    
    // Commit instruction
    assign commit_inst = rob_entries[commit_ptr];
    assign commit_valid = commit_found && commit_en;
    
    // Update pointers
    assign next_head_ptr = (commit_found && commit_en) ? (head_ptr + 1) % alphaahb_v5_pipeline_pkg::REORDER_BUFFER_SIZE : head_ptr;
    assign next_tail_ptr = (allocate_en && !full) ? (tail_ptr + 1) % alphaahb_v5_pipeline_pkg::REORDER_BUFFER_SIZE : tail_ptr;
    
    // Full and empty detection
    assign full = ((tail_ptr + 1) % alphaahb_v5_pipeline_pkg::REORDER_BUFFER_SIZE) == head_ptr;
    assign empty = tail_ptr == head_ptr;
    
    // Main state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head_ptr <= 0;
            tail_ptr <= 0;
            for (int i = 0; i < alphaahb_v5_pipeline_pkg::REORDER_BUFFER_SIZE; i++) begin
                rob_entries[i].valid <= 1'b0;
            end
        end else begin
            head_ptr <= next_head_ptr;
            tail_ptr <= next_tail_ptr;
            
            // Commit instruction
            if (commit_found && commit_en) begin
                rob_entries[commit_ptr].valid <= 1'b0;
            end
            
            // Allocate new entry
            if (allocate_en && !full) begin
                rob_entries[tail_ptr].pc <= pc;
                rob_entries[tail_ptr].rd <= rd;
                rob_entries[tail_ptr].result <= result;
                rob_entries[tail_ptr].valid <= 1'b1;
                rob_entries[tail_ptr].ready <= 1'b0;
                rob_entries[tail_ptr].exception <= exception;
                rob_entries[tail_ptr].exception_code <= exception_code;
                rob_entries[tail_ptr].inst_type <= inst_type;
                rob_entries[tail_ptr].age <= tail_ptr;
            end
            
            // Update result when available
            if (result != 0) begin
                for (int i = 0; i < alphaahb_v5_pipeline_pkg::REORDER_BUFFER_SIZE; i++) begin
                    if (rob_entries[i].valid && !rob_entries[i].ready && rob_entries[i].rd == rd) begin
                        rob_entries[i].result <= result;
                        rob_entries[i].ready <= 1'b1;
                    end
                end
            end
        end
    end

endmodule

// ============================================================================
// Advanced Load/Store Queue with Memory Ordering
// ============================================================================

module AdvancedLoadStoreQueue (
    input  logic clk,
    input  logic rst_n,
    input  logic [63:0] pc,
    input  logic [63:0] addr,
    input  logic [63:0] data,
    input  logic [7:0]  mask,
    input  logic        is_load,
    input  logic        is_store,
    input  logic        allocate_en,
    input  logic        commit_en,
    input  logic        mem_op_complete, // Added: Real memory completion signal
    input  logic [4:0]  mem_op_tag,      // Added: Tag to identify completed op
    output logic        full,
    output logic        empty,
    output alphaahb_v5_pipeline_pkg::load_store_queue_entry_t commit_inst,
    output logic        commit_valid
);

    // Load/store queue array
    alphaahb_v5_pipeline_pkg::load_store_queue_entry_t lsq_entries [alphaahb_v5_pipeline_pkg::LOAD_STORE_QUEUE_SIZE-1:0];
    
    // Head and tail pointers
    logic [4:0] head_ptr, tail_ptr;
    logic [4:0] next_head_ptr, next_tail_ptr;
    
    // Commit logic
    logic [4:0] commit_ptr;
    logic commit_found;
    
    // Find oldest ready instruction to commit
    always_comb begin
        commit_found = 1'b0;
        commit_ptr = head_ptr;
        
        for (int i = 0; i < alphaahb_v5_pipeline_pkg::LOAD_STORE_QUEUE_SIZE; i++) begin
            int idx = (head_ptr + i) % alphaahb_v5_pipeline_pkg::LOAD_STORE_QUEUE_SIZE;
            if (lsq_entries[idx].valid && lsq_entries[idx].ready) begin
                commit_found = 1'b1;
                commit_ptr = idx;
                break;
            end
        end
    end
    
    // Commit instruction
    assign commit_inst = lsq_entries[commit_ptr];
    assign commit_valid = commit_found && commit_en;
    
    // Update pointers
    assign next_head_ptr = (commit_found && commit_en) ? (head_ptr + 1) % alphaahb_v5_pipeline_pkg::LOAD_STORE_QUEUE_SIZE : head_ptr;
    assign next_tail_ptr = (allocate_en && !full) ? (tail_ptr + 1) % alphaahb_v5_pipeline_pkg::LOAD_STORE_QUEUE_SIZE : tail_ptr;
    
    // Full and empty detection
    assign full = ((tail_ptr + 1) % alphaahb_v5_pipeline_pkg::LOAD_STORE_QUEUE_SIZE) == head_ptr;
    assign empty = tail_ptr == head_ptr;
    
    // Main state machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head_ptr <= 0;
            tail_ptr <= 0;
            for (int i = 0; i < alphaahb_v5_pipeline_pkg::LOAD_STORE_QUEUE_SIZE; i++) begin
                lsq_entries[i].valid <= 1'b0;
            end
        end else begin
            head_ptr <= next_head_ptr;
            tail_ptr <= next_tail_ptr;
            
            // Commit instruction
            if (commit_found && commit_en) begin
                lsq_entries[commit_ptr].valid <= 1'b0;
            end
            
            // Allocate new entry
            if (allocate_en && !full) begin
                lsq_entries[tail_ptr].pc <= pc;
                lsq_entries[tail_ptr].addr <= addr;
                lsq_entries[tail_ptr].data <= data;
                lsq_entries[tail_ptr].mask <= mask;
                lsq_entries[tail_ptr].is_load <= is_load;
                lsq_entries[tail_ptr].is_store <= is_store;
                lsq_entries[tail_ptr].valid <= 1'b1;
                lsq_entries[tail_ptr].ready <= 1'b0;
                lsq_entries[tail_ptr].exception <= 1'b0;
                lsq_entries[tail_ptr].exception_code <= 4'h0;
                lsq_entries[tail_ptr].age <= tail_ptr;
            end
            
            // Mark as ready when memory operation completes
            for (int i = 0; i < alphaahb_v5_pipeline_pkg::LOAD_STORE_QUEUE_SIZE; i++) begin
                if (lsq_entries[i].valid && !lsq_entries[i].ready) begin
                    // Real logic: Check if memory subsystem signals completion for this tag
                    if (mem_op_complete && (mem_op_tag == i[4:0])) begin
                         lsq_entries[i].ready <= 1'b1;
                    end
                end
            end
        end
    end

endmodule
