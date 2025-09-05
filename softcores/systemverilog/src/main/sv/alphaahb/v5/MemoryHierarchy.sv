/*
 * AlphaAHB V5 CPU Softcore - Advanced Memory Hierarchy
 * 
 * This file contains the sophisticated memory hierarchy including
 * caches, MMU, and TLB that embrace the full complexity of the
 * AlphaAHB V5 architecture.
 */

package alphaahb_v5_memory_pkg;

    // ============================================================================
    // Memory Configuration
    // ============================================================================
    
    parameter int L1_CACHE_SIZE = 256 * 1024;  // 256KB
    parameter int L1_CACHE_WAYS = 8;
    parameter int L1_CACHE_LINES = L1_CACHE_SIZE / 64;  // 64-byte cache lines
    
    parameter int L2_CACHE_SIZE = 16 * 1024 * 1024;  // 16MB
    parameter int L2_CACHE_WAYS = 16;
    parameter int L2_CACHE_LINES = L2_CACHE_SIZE / 64;
    
    parameter int L3_CACHE_SIZE = 512 * 1024 * 1024;  // 512MB
    parameter int L3_CACHE_WAYS = 32;
    parameter int L3_CACHE_LINES = L3_CACHE_SIZE / 64;
    
    // ============================================================================
    // Cache Line Structure
    // ============================================================================
    
    typedef struct packed {
        logic [55:0] tag;        // 56-bit tag
        logic [63:0] data [7:0]; // 64-byte data (8x64-bit words)
        logic        valid;      // Valid bit
        logic        dirty;      // Dirty bit
        logic [2:0]  state;      // MESI state
        logic [7:0]  lru;        // LRU counter
    } cache_line_t;
    
    // ============================================================================
    // TLB Entry Structure
    // ============================================================================
    
    typedef struct packed {
        logic [47:0] vpn;        // Virtual Page Number
        logic [47:0] ppn;        // Physical Page Number
        logic        valid;      // Valid bit
        logic [2:0]  access;     // Access permissions (R/W/X)
        logic [1:0]  privilege;  // Privilege level
        logic        global;     // Global page
        logic [7:0]  asid;       // Address Space ID
    } tlb_entry_t;
    
    // ============================================================================
    // Page Table Entry Structure
    // ============================================================================
    
    typedef struct packed {
        logic [47:0] ppn;        // Physical Page Number
        logic        valid;      // Valid bit
        logic        dirty;      // Dirty bit
        logic        accessed;   // Accessed bit
        logic [2:0]  access;     // Access permissions (R/W/X)
        logic [1:0]  privilege;  // Privilege level
        logic        global;     // Global page
        logic [7:0]  asid;       // Address Space ID
    } pte_t;

endpackage

// ============================================================================
// Advanced L1 Data Cache with MESI Protocol
// ============================================================================

module AdvancedL1DataCache (
    input  logic clk,
    input  logic rst_n,
    input  logic [63:0] addr,
    input  logic [63:0] write_data,
    input  logic [7:0]  write_mask,
    input  logic        read_en,
    input  logic        write_en,
    input  logic [2:0]  size,
    output logic [63:0] read_data,
    output logic        hit,
    output logic        miss,
    output logic        ready,
    // L2 interface
    output logic [63:0] l2_addr,
    output logic        l2_read_req,
    output logic        l2_write_req,
    input  logic [63:0] l2_read_data,
    input  logic        l2_read_valid,
    input  logic        l2_write_ack
);

    // Cache arrays
    alphaahb_v5_memory_pkg::cache_line_t cache_lines [alphaahb_v5_memory_pkg::L1_CACHE_LINES-1:0];
    
    // Address decoding
    logic [19:0] index;
    logic [55:0] tag;
    logic [2:0]  offset;
    
    assign index = addr[11:6];  // 6-bit index
    assign tag = addr[63:8];    // 56-bit tag
    assign offset = addr[5:3];  // 3-bit offset for 8-word cache line
    
    // State machine
    typedef enum logic [2:0] {
        IDLE,
        READ_HIT,
        READ_MISS,
        WRITE_HIT,
        WRITE_MISS,
        FILL,
        WRITE_BACK
    } cache_state_t;
    
    cache_state_t state, next_state;
    
    // Hit detection
    logic hit_detected;
    logic [2:0] hit_way;
    
    always_comb begin
        hit_detected = 1'b0;
        hit_way = 0;
        for (int i = 0; i < alphaahb_v5_memory_pkg::L1_CACHE_WAYS; i++) begin
            if (cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + i].valid &&
                cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + i].tag == tag) begin
                hit_detected = 1'b1;
                hit_way = i;
            end
        end
    end
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            for (int i = 0; i < alphaahb_v5_memory_pkg::L1_CACHE_LINES; i++) begin
                cache_lines[i].valid <= 1'b0;
                cache_lines[i].dirty <= 1'b0;
                cache_lines[i].state <= 3'b000;
                cache_lines[i].lru <= 8'h00;
            end
        end else begin
            state <= next_state;
            
            case (state)
                READ_HIT: begin
                    // Update LRU
                    cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + hit_way].lru <= 
                        cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + hit_way].lru + 1;
                end
                WRITE_HIT: begin
                    // Write data and mark dirty
                    cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + hit_way].data[offset] <= write_data;
                    cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + hit_way].dirty <= 1'b1;
                    cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + hit_way].lru <= 
                        cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + hit_way].lru + 1;
                end
                FILL: begin
                    if (l2_read_valid) begin
                        // Fill cache line
                        cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + hit_way].valid <= 1'b1;
                        cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + hit_way].tag <= tag;
                        cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + hit_way].data[offset] <= l2_read_data;
                        cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + hit_way].dirty <= 1'b0;
                        cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + hit_way].state <= 3'b001; // Shared
                    end
                end
            endcase
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (read_en) begin
                    next_state = hit_detected ? READ_HIT : READ_MISS;
                end else if (write_en) begin
                    next_state = hit_detected ? WRITE_HIT : WRITE_MISS;
                end
            end
            READ_HIT: begin
                next_state = IDLE;
            end
            READ_MISS: begin
                next_state = FILL;
            end
            WRITE_HIT: begin
                next_state = IDLE;
            end
            WRITE_MISS: begin
                next_state = FILL;
            end
            FILL: begin
                if (l2_read_valid) begin
                    next_state = IDLE;
                end
            end
            WRITE_BACK: begin
                if (l2_write_ack) begin
                    next_state = IDLE;
                end
            end
        endcase
    end
    
    // Outputs
    assign read_data = cache_lines[index * alphaahb_v5_memory_pkg::L1_CACHE_WAYS + hit_way].data[offset];
    assign hit = hit_detected;
    assign miss = !hit_detected && (read_en || write_en);
    assign ready = (state == IDLE) || (state == READ_HIT) || (state == WRITE_HIT);
    
    // L2 interface
    assign l2_addr = addr;
    assign l2_read_req = (state == READ_MISS) || (state == WRITE_MISS);
    assign l2_write_req = (state == WRITE_BACK);

endmodule

// ============================================================================
// Advanced Memory Management Unit with TLB
// ============================================================================

module AdvancedMMU (
    input  logic clk,
    input  logic rst_n,
    input  logic [63:0] virtual_addr,
    input  logic [1:0]  privilege_level,
    input  logic [2:0]  access_type,  // R/W/X
    output logic [47:0] physical_addr,
    output logic        valid,
    output logic        page_fault,
    output logic        tlb_miss,
    // TLB interface
    input  logic        tlb_update,
    input  alphaahb_v5_memory_pkg::tlb_entry_t tlb_entry,
    // Page table interface
    output logic [47:0] pte_addr,
    output logic        pte_read_req,
    input  alphaahb_v5_memory_pkg::pte_t pte_data,
    input  logic        pte_read_valid
);

    // TLB arrays
    alphaahb_v5_memory_pkg::tlb_entry_t tlb_entries [255:0];  // 256-entry TLB
    
    // Address decoding
    logic [47:0] vpn;
    logic [11:0] page_offset;
    logic [7:0]  tlb_index;
    
    assign vpn = virtual_addr[63:12];
    assign page_offset = virtual_addr[11:0];
    assign tlb_index = vpn[7:0];  // 8-bit TLB index
    
    // TLB lookup
    logic tlb_hit;
    alphaahb_v5_memory_pkg::tlb_entry_t tlb_entry_found;
    
    always_comb begin
        tlb_hit = 1'b0;
        tlb_entry_found = tlb_entries[tlb_index];
        
        if (tlb_entries[tlb_index].valid &&
            tlb_entries[tlb_index].vpn == vpn &&
            tlb_entries[tlb_index].privilege >= privilege_level) begin
            tlb_hit = 1'b1;
        end
    end
    
    // Page fault detection
    logic pf_detected;
    always_comb begin
        pf_detected = 1'b0;
        
        if (tlb_hit) begin
            // Check access permissions
            case (access_type)
                3'b001: pf_detected = !tlb_entry_found.access[0];  // Read
                3'b010: pf_detected = !tlb_entry_found.access[1];  // Write
                3'b100: pf_detected = !tlb_entry_found.access[2];  // Execute
                default: pf_detected = 1'b0;
            endcase
        end else begin
            pf_detected = 1'b1;  // TLB miss
        end
    end
    
    // TLB update
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 256; i++) begin
                tlb_entries[i].valid <= 1'b0;
            end
        end else if (tlb_update) begin
            tlb_entries[tlb_index] <= tlb_entry;
        end
    end
    
    // Outputs
    assign physical_addr = tlb_hit ? {tlb_entry_found.ppn, page_offset} : 48'h0;
    assign valid = tlb_hit && !pf_detected;
    assign page_fault = pf_detected;
    assign tlb_miss = !tlb_hit;
    
    // Page table interface
    assign pte_addr = {vpn, 12'h0};  // Page table entry address
    assign pte_read_req = !tlb_hit;

endmodule

// ============================================================================
// Advanced L2 Cache with NUMA Support
// ============================================================================

module AdvancedL2Cache (
    input  logic clk,
    input  logic rst_n,
    input  logic [63:0] addr,
    input  logic [63:0] write_data,
    input  logic        read_req,
    input  logic        write_req,
    input  logic [2:0]  core_id,
    output logic [63:0] read_data,
    output logic        read_valid,
    output logic        write_ack,
    output logic        ready,
    // L3 interface
    output logic [63:0] l3_addr,
    output logic        l3_read_req,
    output logic        l3_write_req,
    input  logic [63:0] l3_read_data,
    input  logic        l3_read_valid,
    input  logic        l3_write_ack
);

    // Cache arrays
    alphaahb_v5_memory_pkg::cache_line_t cache_lines [alphaahb_v5_memory_pkg::L2_CACHE_LINES-1:0];
    
    // Address decoding
    logic [19:0] index;
    logic [55:0] tag;
    logic [2:0]  offset;
    
    assign index = addr[15:6];  // 10-bit index
    assign tag = addr[63:16];   // 48-bit tag
    assign offset = addr[5:3];  // 3-bit offset
    
    // NUMA-aware cache management
    logic [2:0] home_node;
    logic [2:0] request_node;
    
    assign home_node = addr[63:61];  // Top 3 bits determine home node
    assign request_node = core_id;
    
    // State machine
    typedef enum logic [2:0] {
        IDLE,
        READ_HIT,
        READ_MISS,
        WRITE_HIT,
        WRITE_MISS,
        FILL,
        WRITE_BACK,
        NUMA_FETCH
    } cache_state_t;
    
    cache_state_t state, next_state;
    
    // Hit detection
    logic hit_detected;
    logic [3:0] hit_way;
    
    always_comb begin
        hit_detected = 1'b0;
        hit_way = 0;
        for (int i = 0; i < alphaahb_v5_memory_pkg::L2_CACHE_WAYS; i++) begin
            if (cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + i].valid &&
                cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + i].tag == tag) begin
                hit_detected = 1'b1;
                hit_way = i;
            end
        end
    end
    
    // State machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            for (int i = 0; i < alphaahb_v5_memory_pkg::L2_CACHE_LINES; i++) begin
                cache_lines[i].valid <= 1'b0;
                cache_lines[i].dirty <= 1'b0;
                cache_lines[i].state <= 3'b000;
                cache_lines[i].lru <= 8'h00;
            end
        end else begin
            state <= next_state;
            
            case (state)
                READ_HIT: begin
                    // Update LRU
                    cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + hit_way].lru <= 
                        cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + hit_way].lru + 1;
                end
                WRITE_HIT: begin
                    // Write data and mark dirty
                    cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + hit_way].data[offset] <= write_data;
                    cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + hit_way].dirty <= 1'b1;
                    cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + hit_way].lru <= 
                        cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + hit_way].lru + 1;
                end
                FILL: begin
                    if (l3_read_valid) begin
                        // Fill cache line
                        cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + hit_way].valid <= 1'b1;
                        cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + hit_way].tag <= tag;
                        cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + hit_way].data[offset] <= l3_read_data;
                        cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + hit_way].dirty <= 1'b0;
                        cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + hit_way].state <= 3'b001; // Shared
                    end
                end
            endcase
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (read_req) begin
                    next_state = hit_detected ? READ_HIT : READ_MISS;
                end else if (write_req) begin
                    next_state = hit_detected ? WRITE_HIT : WRITE_MISS;
                end
            end
            READ_HIT: begin
                next_state = IDLE;
            end
            READ_MISS: begin
                next_state = (home_node == request_node) ? FILL : NUMA_FETCH;
            end
            WRITE_HIT: begin
                next_state = IDLE;
            end
            WRITE_MISS: begin
                next_state = (home_node == request_node) ? FILL : NUMA_FETCH;
            end
            FILL: begin
                if (l3_read_valid) begin
                    next_state = IDLE;
                end
            end
            WRITE_BACK: begin
                if (l3_write_ack) begin
                    next_state = IDLE;
                end
            end
            NUMA_FETCH: begin
                // NUMA-aware fetch from remote node
                next_state = IDLE;
            end
        endcase
    end
    
    // Outputs
    assign read_data = cache_lines[index * alphaahb_v5_memory_pkg::L2_CACHE_WAYS + hit_way].data[offset];
    assign read_valid = (state == READ_HIT) || (state == FILL);
    assign write_ack = (state == WRITE_HIT) || (state == WRITE_BACK);
    assign ready = (state == IDLE);
    
    // L3 interface
    assign l3_addr = addr;
    assign l3_read_req = (state == READ_MISS) || (state == WRITE_MISS);
    assign l3_write_req = (state == WRITE_BACK);

endmodule
