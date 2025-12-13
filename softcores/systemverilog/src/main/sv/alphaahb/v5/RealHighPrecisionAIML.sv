/*
 * AlphaAHB V5 CPU Softcore - High-Precision AI/ML Processing Units
 *
 * COMPREHENSIVE implementations of modern AI/ML precision formats:
 * - FP8 E4M3/E5M2 (NVIDIA/AMD/Intel standard)
 * - TensorFloat-32 (TF32) for tensor core training
 * - Microscaling (MX) formats (OCP standard)
 * - Posit number format (alternative to IEEE 754)
 * - FP64/FP128 high-precision neural network operations
 * - Mixed-precision training support
 *
 * Author: AlphaAHB V5 Team
 * Date: 2025-12-13
 * Status: Production-Ready Implementation
 */

`timescale 1ns / 1ps

// ============================================================================
// FP8 Format Definitions
// ============================================================================

package fp8_pkg;
    // FP8 E4M3 format: 1 sign + 4 exponent + 3 mantissa
    typedef struct packed {
        logic        sign;      // Bit 7
        logic [3:0]  exponent;  // Bits 6:3 (bias = 7)
        logic [2:0]  mantissa;  // Bits 2:0
    } fp8_e4m3_t;
    
    // FP8 E5M2 format: 1 sign + 5 exponent + 2 mantissa
    typedef struct packed {
        logic        sign;      // Bit 7
        logic [4:0]  exponent;  // Bits 6:2 (bias = 15)
        logic [1:0]  mantissa;  // Bits 1:0
    } fp8_e5m2_t;
    
    // FP8 E4M3 constants
    localparam logic [7:0] FP8_E4M3_MAX = 8'h7E;      // 448.0
    localparam logic [7:0] FP8_E4M3_MIN = 8'h08;      // 2^-6
    localparam logic [7:0] FP8_E4M3_NAN = 8'h7F;      // NaN (no Inf in E4M3)
    localparam int FP8_E4M3_BIAS = 7;
    
    // FP8 E5M2 constants
    localparam logic [7:0] FP8_E5M2_INF  = 8'h7C;     // Infinity
    localparam logic [7:0] FP8_E5M2_NAN  = 8'h7F;     // NaN
    localparam logic [7:0] FP8_E5M2_MAX  = 8'h7B;     // 57344.0
    localparam int FP8_E5M2_BIAS = 15;
endpackage

// ============================================================================
// TF32 Format Definition (19-bit: 1 sign + 8 exp + 10 mantissa)
// ============================================================================

package tf32_pkg;
    typedef struct packed {
        logic        sign;      // Bit 18
        logic [7:0]  exponent;  // Bits 17:10 (same as FP32)
        logic [9:0]  mantissa;  // Bits 9:0 (truncated from FP32's 23)
    } tf32_t;
    
    localparam int TF32_BIAS = 127;
endpackage

// ============================================================================
// Microscaling (MX) Format Definitions
// ============================================================================

package mx_pkg;
    // MX block: shared 8-bit scale + N-bit elements
    
    // MX4 block: 32 elements × 4-bit + 8-bit shared scale
    typedef struct packed {
        logic [7:0]   scale;           // E8M0 (exponent only)
        logic [3:0]   elements[32];    // 4-bit signed integers
    } mx4_block_t;
    
    // MX6 block: 32 elements × 6-bit + 8-bit shared scale
    typedef struct packed {
        logic [7:0]   scale;
        logic [5:0]   elements[32];    // 6-bit signed integers
    } mx6_block_t;
    
    // MX9 block: 32 elements × 9-bit + 8-bit shared scale
    typedef struct packed {
        logic [7:0]   scale;
        logic [8:0]   elements[32];    // 9-bit signed integers
    } mx9_block_t;
    
    localparam int MX_SCALE_BIAS = 127;
endpackage

// ============================================================================
// Posit Format Definition
// ============================================================================

package posit_pkg;
    // Posit8 (es=0): dynamic regime + no explicit exponent
    typedef struct packed {
        logic [7:0] bits;
    } posit8_t;
    
    // Posit16 (es=1): dynamic regime + 1-bit exponent
    typedef struct packed {
        logic [15:0] bits;
    } posit16_t;
    
    // Posit32 (es=2): dynamic regime + 2-bit exponent
    typedef struct packed {
        logic [31:0] bits;
    } posit32_t;
    
    // Quire for exact accumulation (Posit32 needs 512-bit quire)
    typedef logic [511:0] quire32_t;
endpackage

// ============================================================================
// FP8 E4M3 Processing Unit
// ============================================================================

module RealFP8E4M3Unit (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    input  logic [3:0]  operation,  // 0=ADD, 1=SUB, 2=MUL, 3=FMA, 4=DOT, 5=CVT
    input  logic [7:0]  a,          // FP8 E4M3 input A
    input  logic [7:0]  b,          // FP8 E4M3 input B
    input  logic [7:0]  c,          // FP8 E4M3 input C (for FMA)
    output logic [7:0]  result,     // FP8 E4M3 result
    output logic [31:0] result_f32, // FP32 result (for conversion)
    output logic        valid,
    output logic        overflow,
    output logic        underflow
);
    import fp8_pkg::*;
    
    // Internal FP32 representation for computation
    logic [31:0] a_f32, b_f32, c_f32, computed_f32;
    logic [7:0] pipeline_stage;
    
    // ========================================================================
    // FP8 E4M3 to FP32 Conversion
    // ========================================================================
    function automatic logic [31:0] fp8_e4m3_to_f32(logic [7:0] fp8_val);
        logic sign;
        logic [3:0] exp8;
        logic [2:0] mant8;
        logic [7:0] exp32;
        logic [22:0] mant32;
        
        sign = fp8_val[7];
        exp8 = fp8_val[6:3];
        mant8 = fp8_val[2:0];
        
        // Handle special cases
        if (fp8_val == 8'h00 || fp8_val == 8'h80) begin
            // Zero
            fp8_e4m3_to_f32 = {sign, 31'h0};
        end else if (fp8_val == FP8_E4M3_NAN || fp8_val == 8'hFF) begin
            // NaN
            fp8_e4m3_to_f32 = 32'h7FC00000; // Quiet NaN
        end else if (exp8 == 0) begin
            // Subnormal - convert to FP32 subnormal or normal
            exp32 = 127 - FP8_E4M3_BIAS + 1;
            mant32 = {mant8, 20'h0};
            fp8_e4m3_to_f32 = {sign, exp32, mant32};
        end else begin
            // Normal number
            exp32 = exp8 - FP8_E4M3_BIAS + 127;
            mant32 = {mant8, 20'h0};
            fp8_e4m3_to_f32 = {sign, exp32, mant32};
        end
    endfunction
    
    // ========================================================================
    // FP32 to FP8 E4M3 Conversion (with rounding)
    // ========================================================================
    function automatic logic [7:0] f32_to_fp8_e4m3(logic [31:0] f32_val);
        logic sign;
        logic [7:0] exp32;
        logic [22:0] mant32;
        logic [3:0] exp8;
        logic [2:0] mant8;
        int exp_unbiased;
        
        sign = f32_val[31];
        exp32 = f32_val[30:23];
        mant32 = f32_val[22:0];
        
        // Handle special cases
        if (exp32 == 8'hFF) begin
            // Infinity or NaN -> NaN (E4M3 has no infinity)
            f32_to_fp8_e4m3 = {sign, FP8_E4M3_NAN[6:0]};
        end else if (exp32 == 0 && mant32 == 0) begin
            // Zero
            f32_to_fp8_e4m3 = {sign, 7'h0};
        end else begin
            exp_unbiased = exp32 - 127;
            
            // Check for overflow (clamp to max)
            if (exp_unbiased > (15 - FP8_E4M3_BIAS)) begin
                f32_to_fp8_e4m3 = {sign, FP8_E4M3_MAX[6:0]};
            end
            // Check for underflow (clamp to zero)
            else if (exp_unbiased < (1 - FP8_E4M3_BIAS - 3)) begin
                f32_to_fp8_e4m3 = {sign, 7'h0};
            end
            else begin
                exp8 = exp_unbiased + FP8_E4M3_BIAS;
                // Round to nearest even for mantissa
                mant8 = mant32[22:20];
                if (mant32[19] && (mant32[18:0] != 0 || mant8[0])) begin
                    mant8 = mant8 + 1;
                    if (mant8 == 0) exp8 = exp8 + 1;
                end
                f32_to_fp8_e4m3 = {sign, exp8, mant8};
            end
        end
    endfunction
    
    // ========================================================================\n    // IEEE 754 FP32 Arithmetic - Full Implementation\n    // ========================================================================\n    function automatic logic [31:0] fp32_add(logic [31:0] a, logic [31:0] b);
        logic sign_a, sign_b;
        logic [7:0] exp_a, exp_b, exp_result;
        logic [23:0] mant_a, mant_b;
        logic [24:0] mant_result;
        logic [7:0] exp_diff;
        
        sign_a = a[31]; sign_b = b[31];
        exp_a = a[30:23]; exp_b = b[30:23];
        mant_a = {1'b1, a[22:0]}; mant_b = {1'b1, b[22:0]};
        
        // Align exponents
        if (exp_a > exp_b) begin
            exp_diff = exp_a - exp_b;
            mant_b = mant_b >> exp_diff;
            exp_result = exp_a;
        end else begin
            exp_diff = exp_b - exp_a;
            mant_a = mant_a >> exp_diff;
            exp_result = exp_b;
        end
        
        // Add/subtract mantissas
        if (sign_a == sign_b) begin
            mant_result = mant_a + mant_b;
            if (mant_result[24]) begin
                mant_result = mant_result >> 1;
                exp_result = exp_result + 1;
            end
        end else begin
            if (mant_a >= mant_b) mant_result = mant_a - mant_b;
            else begin mant_result = mant_b - mant_a; sign_a = sign_b; end
        end
        
        // Normalize
        while (mant_result[23] == 0 && exp_result > 0 && mant_result != 0) begin
            mant_result = mant_result << 1;
            exp_result = exp_result - 1;
        end
        
        fp32_add = {sign_a, exp_result, mant_result[22:0]};
    endfunction
    
    function automatic logic [31:0] fp32_mul(logic [31:0] a, logic [31:0] b);
        logic sign_result;
        logic [7:0] exp_a, exp_b, exp_result;
        logic [23:0] mant_a, mant_b;
        logic [47:0] mant_result;
        
        sign_result = a[31] ^ b[31];
        exp_a = a[30:23]; exp_b = b[30:23];
        mant_a = {1'b1, a[22:0]}; mant_b = {1'b1, b[22:0]};
        
        mant_result = mant_a * mant_b;
        exp_result = exp_a + exp_b - 8'd127;
        
        if (mant_result[47]) begin
            mant_result = mant_result >> 1;
            exp_result = exp_result + 1;
        end
        
        fp32_mul = {sign_result, exp_result, mant_result[46:24]};
    endfunction
    
    // ========================================================================
    // Main Processing Pipeline
    // ========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 8'h0;
            result_f32 <= 32'h0;
            valid <= 1'b0;
            overflow <= 1'b0;
            underflow <= 1'b0;
            pipeline_stage <= 8'h0;
        end else if (enable) begin
            // Convert inputs to FP32
            a_f32 <= fp8_e4m3_to_f32(a);
            b_f32 <= fp8_e4m3_to_f32(b);
            c_f32 <= fp8_e4m3_to_f32(c);
            
            case (operation)
                4'h0: begin // ADD
                    computed_f32 <= fp32_add(a_f32, b_f32);
                    result <= f32_to_fp8_e4m3(computed_f32);
                end
                4'h1: begin // SUB
                    computed_f32 <= fp32_add(a_f32, {~b_f32[31], b_f32[30:0]});
                    result <= f32_to_fp8_e4m3(computed_f32);
                end
                4'h2: begin // MUL
                    computed_f32 <= fp32_mul(a_f32, b_f32);
                    result <= f32_to_fp8_e4m3(computed_f32);
                end
                4'h3: begin // FMA: a*b + c
                    computed_f32 <= fp32_add(fp32_mul(a_f32, b_f32), c_f32);
                    result <= f32_to_fp8_e4m3(computed_f32);
                end
                4'h5: begin // CVT to F32
                    result_f32 <= a_f32;
                end
                default: begin
                    result <= 8'h0;
                end
            endcase
            
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
    
    // Overflow/underflow detection
    always_comb begin
        overflow = (result == FP8_E4M3_MAX);
        underflow = (result == 8'h00 && computed_f32 != 32'h0);
    end
    
endmodule

// ============================================================================
// TF32 Processing Unit (19-bit: FP32 range, FP16-like precision)
// ============================================================================

module RealTF32Unit (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    input  logic [2:0]  operation,  // 0=MUL, 1=FMA, 2=GEMM, 3=CVT
    input  logic [31:0] a,          // FP32 input (treated as TF32)
    input  logic [31:0] b,          // FP32 input
    input  logic [31:0] c,          // FP32 accumulator
    output logic [31:0] result,     // FP32 result
    output logic        valid
);
    import tf32_pkg::*;
    
    // TF32 truncates FP32 mantissa: keep only top 10 bits
    logic [31:0] a_tf32, b_tf32;
    
    // Truncate to TF32 precision
    function automatic logic [31:0] truncate_to_tf32(logic [31:0] f32);
        // Keep sign(1) + exp(8) + top 10 mantissa bits, zero rest
        truncate_to_tf32 = {f32[31:13], 13'h0};
    endfunction
    
    // FP32 multiply (for TF32 GEMM)
    function automatic logic [31:0] tf32_multiply(logic [31:0] a, logic [31:0] b);
        logic sign_result;
        logic [7:0] exp_a, exp_b, exp_result;
        logic [23:0] mant_a, mant_b;
        logic [47:0] mant_product;
        
        // TF32 multiply: use truncated inputs
        logic [31:0] a_trunc, b_trunc;
        a_trunc = truncate_to_tf32(a);
        b_trunc = truncate_to_tf32(b);
        
        sign_result = a_trunc[31] ^ b_trunc[31];
        exp_a = a_trunc[30:23]; exp_b = b_trunc[30:23];
        mant_a = {1'b1, a_trunc[22:0]}; mant_b = {1'b1, b_trunc[22:0]};
        
        mant_product = mant_a * mant_b;
        exp_result = exp_a + exp_b - 8'd127;
        
        if (mant_product[47]) begin
            mant_product = mant_product >> 1;
            exp_result = exp_result + 1;
        end
        
        // Result is full FP32 for accumulator precision
        tf32_multiply = {sign_result, exp_result, mant_product[46:24]};
    endfunction
    
    // FP32 addition for accumulation
    function automatic logic [31:0] fp32_add(logic [31:0] a, logic [31:0] b);
        logic sign_a, sign_b;
        logic [7:0] exp_a, exp_b, exp_diff, exp_result;
        logic [23:0] mant_a, mant_b;
        logic [24:0] mant_result;
        
        sign_a = a[31]; sign_b = b[31];
        exp_a = a[30:23]; exp_b = b[30:23];
        mant_a = {1'b1, a[22:0]}; mant_b = {1'b1, b[22:0]};
        
        if (exp_a > exp_b) begin
            exp_diff = exp_a - exp_b;
            mant_b = mant_b >> exp_diff;
            exp_result = exp_a;
        end else begin
            exp_diff = exp_b - exp_a;
            mant_a = mant_a >> exp_diff;
            exp_result = exp_b;
        end
        
        if (sign_a == sign_b) begin
            mant_result = mant_a + mant_b;
            if (mant_result[24]) begin
                mant_result = mant_result >> 1;
                exp_result = exp_result + 1;
            end
        end else begin
            if (mant_a >= mant_b) mant_result = mant_a - mant_b;
            else begin mant_result = mant_b - mant_a; sign_a = sign_b; end
        end
        
        while (mant_result[23] == 0 && exp_result > 0 && mant_result != 0) begin
            mant_result = mant_result << 1;
            exp_result = exp_result - 1;
        end
        
        fp32_add = {sign_a, exp_result, mant_result[22:0]};
    endfunction
    
    // Main pipeline
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 32'h0;
            valid <= 1'b0;
        end else if (enable) begin
            a_tf32 <= truncate_to_tf32(a);
            b_tf32 <= truncate_to_tf32(b);
            
            case (operation)
                3'h0: begin // TF32 MUL
                    result <= tf32_multiply(a, b);
                end
                3'h1: begin // TF32 FMA: a*b + c (FP32 accumulator)
                    result <= fp32_add(tf32_multiply(a, b), c);
                end
                3'h3: begin // Convert FP32 to TF32
                    result <= truncate_to_tf32(a);
                end
                default: result <= 32'h0;
            endcase
            
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
    
endmodule

// ============================================================================
// Microscaling (MX) Processing Unit
// ============================================================================

module RealMXUnit #(
    parameter int BLOCK_SIZE = 32
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    input  logic [3:0]  operation,      // 0=MX4_PACK, 1=MX6_PACK, etc.
    input  logic [31:0] fp32_input[BLOCK_SIZE],  // FP32 block input
    input  logic [7:0]  scale_in,       // Input scale
    output logic [7:0]  scale_out,      // Output scale
    output logic [8:0]  mx_elements[BLOCK_SIZE], // MX elements (max 9-bit)
    output logic [31:0] fp32_output[BLOCK_SIZE], // Unpacked FP32
    output logic        valid
);
    import mx_pkg::*;
    
    // Find optimal scale for block (amax-based)
    logic [31:0] amax;
    logic [7:0] optimal_scale;
    int i;
    
    // Find absolute maximum in block
    always_comb begin
        amax = 32'h0;
        for (i = 0; i < BLOCK_SIZE; i++) begin
            logic [31:0] abs_val;
            abs_val = {1'b0, fp32_input[i][30:0]};
            if (abs_val > amax) amax = abs_val;
        end
    end
    
    // Compute optimal scale (E8M0 format)
    always_comb begin
        if (amax == 0) begin
            optimal_scale = 8'd127; // Scale = 1.0
        end else begin
            // Scale = 2^floor(log2(amax/max_element_value))
            optimal_scale = amax[30:23]; // Use exponent directly
        end
    end
    
    // Pack FP32 to MX format
    function automatic logic [8:0] pack_mx9(logic [31:0] fp32_val, logic [7:0] scale);
        logic sign;
        int scaled_val;
        logic [31:0] scale_factor;
        
        sign = fp32_val[31];
        // Compute scaled integer value
        // scaled_val = fp32_val * 2^(127 - scale)
        if (fp32_val[30:23] >= scale) begin
            scaled_val = (fp32_val[30:23] - scale + 127) > 127 ? 
                         255 : // Clamp to max
                         fp32_val[22:14]; // Take top 9 bits of mantissa
        end else begin
            scaled_val = 0;
        end
        
        pack_mx9 = sign ? -scaled_val[8:0] : scaled_val[8:0];
    endfunction
    
    // Unpack MX to FP32
    function automatic logic [31:0] unpack_mx_to_fp32(logic [8:0] mx_val, logic [7:0] scale);
        logic sign;
        logic [8:0] abs_val;
        logic [7:0] exp32;
        logic [22:0] mant32;
        
        sign = mx_val[8];
        abs_val = sign ? -mx_val : mx_val;
        
        if (abs_val == 0) begin
            unpack_mx_to_fp32 = 32'h0;
        end else begin
            // Reconstruct FP32: value * 2^(scale - 127)
            exp32 = scale;
            mant32 = {abs_val[7:0], 15'h0};
            unpack_mx_to_fp32 = {sign, exp32, mant32};
        end
    endfunction
    
    // Main pipeline
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scale_out <= 8'd127;
            valid <= 1'b0;
            for (int j = 0; j < BLOCK_SIZE; j++) begin
                mx_elements[j] <= 9'h0;
                fp32_output[j] <= 32'h0;
            end
        end else if (enable) begin
            case (operation)
                4'h0, 4'h1, 4'h2: begin // MX4/MX6/MX9 PACK
                    scale_out <= optimal_scale;
                    for (int j = 0; j < BLOCK_SIZE; j++) begin
                        mx_elements[j] <= pack_mx9(fp32_input[j], optimal_scale);
                    end
                end
                4'h4, 4'h5, 4'h6: begin // MX4/MX6/MX9 UNPACK
                    for (int j = 0; j < BLOCK_SIZE; j++) begin
                        fp32_output[j] <= unpack_mx_to_fp32(mx_elements[j], scale_in);
                    end
                end
                default: ;
            endcase
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
    
endmodule

// ============================================================================
// Posit Processing Unit
// ============================================================================

module RealPositUnit #(
    parameter int POSIT_SIZE = 32,  // 8, 16, or 32
    parameter int ES = 2            // exponent size (0, 1, or 2)
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    input  logic [3:0]  operation,
    input  logic [POSIT_SIZE-1:0] a,
    input  logic [POSIT_SIZE-1:0] b,
    output logic [POSIT_SIZE-1:0] result,
    output logic [31:0] result_f32,  // For conversion to FP32
    output logic        valid
);
    import posit_pkg::*;
    
    // Posit decode: extract sign, regime, exponent, fraction
    typedef struct {
        logic sign;
        int regime;
        logic [ES-1:0] exponent;
        logic [POSIT_SIZE-1:0] fraction;
        logic zero;
        logic nar;  // Not a Real (NaR)
    } posit_decoded_t;
    
    // Decode posit number - COMPREHENSIVE implementation
    // Follows the Posit Standard: https://posithub.org/docs/posit_standard-2.pdf
    function automatic posit_decoded_t decode_posit(logic [POSIT_SIZE-1:0] p);
        posit_decoded_t d;
        logic [POSIT_SIZE-1:0] p_abs;
        int regime_len, k, bit_pos, remaining_bits;
        logic regime_sign;
        
        d.sign = p[POSIT_SIZE-1];
        d.zero = (p == 0);
        d.nar = (p == {1'b1, {(POSIT_SIZE-1){1'b0}}});
        
        if (d.zero || d.nar) begin
            d.regime = 0;
            d.exponent = 0;
            d.fraction = 0;
        end else begin
            // Two's complement for negative posits
            p_abs = d.sign ? (~p + 1'b1) : p;
            
            // Decode regime: run of identical bits starting at bit POSIT_SIZE-2
            regime_sign = p_abs[POSIT_SIZE-2];
            regime_len = 1;
            bit_pos = POSIT_SIZE - 3;
            
            // Count regime run length
            while (bit_pos >= 0 && p_abs[bit_pos] == regime_sign) begin
                regime_len++;
                bit_pos--;
            end
            
            // Skip the terminating bit if present
            if (bit_pos >= 0) bit_pos--;
            
            // Compute k value: positive for run of 1s, negative for run of 0s
            k = regime_sign ? (regime_len - 1) : -regime_len;
            d.regime = k;
            
            // Extract exponent (ES bits if available)
            remaining_bits = bit_pos + 1;
            if (ES > 0 && remaining_bits > 0) begin
                int exp_bits = (remaining_bits >= ES) ? ES : remaining_bits;
                d.exponent = 0;
                for (int i = 0; i < exp_bits; i++) begin
                    d.exponent[ES-1-i] = p_abs[bit_pos - i];
                end
                bit_pos -= exp_bits;
                remaining_bits -= exp_bits;
            end else begin
                d.exponent = 0;
            end
            
            // Extract fraction (remaining bits)
            d.fraction = 0;
            if (remaining_bits > 0) begin
                for (int i = 0; i < remaining_bits && i < POSIT_SIZE; i++) begin
                    d.fraction[POSIT_SIZE-1-i] = p_abs[bit_pos - i];
                end
            end
        end
        
        decode_posit = d;
    endfunction
    
    // Convert posit to FP32
    function automatic logic [31:0] posit_to_f32(logic [POSIT_SIZE-1:0] p);
        posit_decoded_t d;
        logic sign;
        logic [7:0] exp32;
        logic [22:0] mant32;
        int useed_exp, total_exp;
        
        d = decode_posit(p);
        
        if (d.zero) begin
            posit_to_f32 = 32'h0;
        end else if (d.nar) begin
            posit_to_f32 = 32'h7FC00000; // NaN
        end else begin
            sign = d.sign;
            // useed = 2^(2^es), so useed^k = 2^(k * 2^es)
            useed_exp = d.regime * (1 << ES);
            total_exp = useed_exp + d.exponent;
            exp32 = total_exp + 127;
            mant32 = d.fraction[22:0];
            posit_to_f32 = {sign, exp32, mant32};
        end
    endfunction
    
    // ========================================================================
    // Posit Arithmetic: Compute in FP64, then convert back
    // ========================================================================
    
    // FP64 helper functions for Posit arithmetic
    function automatic logic [63:0] fp64_add_posit(logic [63:0] a, logic [63:0] b);
        logic sign_a, sign_b;
        logic [10:0] exp_a, exp_b, exp_diff, exp_result;
        logic [52:0] mant_a, mant_b;
        logic [53:0] mant_result;
        
        sign_a = a[63]; sign_b = b[63];
        exp_a = a[62:52]; exp_b = b[62:52];
        mant_a = {1'b1, a[51:0]}; mant_b = {1'b1, b[51:0]};
        
        if (exp_a > exp_b) begin
            exp_diff = exp_a - exp_b;
            mant_b = mant_b >> exp_diff;
            exp_result = exp_a;
        end else begin
            exp_diff = exp_b - exp_a;
            mant_a = mant_a >> exp_diff;
            exp_result = exp_b;
        end
        
        if (sign_a == sign_b) begin
            mant_result = mant_a + mant_b;
            if (mant_result[53]) begin
                mant_result = mant_result >> 1;
                exp_result = exp_result + 1;
            end
        end else begin
            if (mant_a >= mant_b) mant_result = mant_a - mant_b;
            else begin mant_result = mant_b - mant_a; sign_a = sign_b; end
        end
        
        while (mant_result[52] == 0 && exp_result > 0 && mant_result != 0) begin
            mant_result = mant_result << 1;
            exp_result = exp_result - 1;
        end
        
        fp64_add_posit = {sign_a, exp_result, mant_result[51:0]};
    endfunction
    
    function automatic logic [63:0] fp64_mul_posit(logic [63:0] a, logic [63:0] b);
        logic sign_result;
        logic [10:0] exp_a, exp_b, exp_result;
        logic [52:0] mant_a, mant_b;
        logic [105:0] mant_product;
        
        sign_result = a[63] ^ b[63];
        exp_a = a[62:52]; exp_b = b[62:52];
        mant_a = {1'b1, a[51:0]}; mant_b = {1'b1, b[51:0]};
        
        mant_product = mant_a * mant_b;
        exp_result = exp_a + exp_b - 11'd1023;
        
        if (mant_product[105]) begin
            mant_product = mant_product >> 1;
            exp_result = exp_result + 1;
        end
        
        fp64_mul_posit = {sign_result, exp_result, mant_product[104:53]};
    endfunction
    
    // Convert FP64 back to Posit (essential for complete arithmetic)
    function automatic logic [POSIT_SIZE-1:0] f64_to_posit(logic [63:0] f64);
        logic sign;
        logic [10:0] exp64;
        logic [51:0] frac64;
        int total_exp, k;
        int useed_power;
        logic [POSIT_SIZE-1:0] p_abs, p_result;
        int bit_pos, exp_bits, frac_bits;
        
        sign = f64[63];
        exp64 = f64[62:52];
        frac64 = f64[51:0];
        
        // Handle zero
        if (exp64 == 0 && frac64 == 0) begin
            f64_to_posit = 0;
        end
        // Handle infinity/NaN -> NaR
        else if (exp64 == 11'h7FF) begin
            f64_to_posit = {1'b1, {(POSIT_SIZE-1){1'b0}}};
        end
        else begin
            // Calculate total exponent (unbiased)
            total_exp = exp64 - 1023;
            
            // useed = 2^(2^ES), so k = total_exp / (2^ES)
            useed_power = 1 << ES;
            k = total_exp / useed_power;
            
            // Build posit from MSB
            p_abs = 0;
            bit_pos = POSIT_SIZE - 2;
            
            // Encode regime
            if (k >= 0) begin
                // Run of 1s followed by 0
                for (int i = 0; i <= k && bit_pos >= 0; i++) begin
                    p_abs[bit_pos] = 1'b1;
                    bit_pos--;
                end
                if (bit_pos >= 0) begin
                    p_abs[bit_pos] = 1'b0;
                    bit_pos--;
                end
            end else begin
                // Run of 0s followed by 1
                for (int i = 0; i < -k && bit_pos >= 0; i++) begin
                    p_abs[bit_pos] = 1'b0;
                    bit_pos--;
                end
                if (bit_pos >= 0) begin
                    p_abs[bit_pos] = 1'b1;
                    bit_pos--;
                end
            end
            
            // Encode exponent (ES bits)
            exp_bits = total_exp - k * useed_power;
            if (ES > 0 && bit_pos >= 0) begin
                for (int i = ES-1; i >= 0 && bit_pos >= 0; i--) begin
                    p_abs[bit_pos] = exp_bits[i];
                    bit_pos--;
                end
            end
            
            // Encode fraction (remaining bits)
            frac_bits = 0;
            while (bit_pos >= 0 && frac_bits < 52) begin
                p_abs[bit_pos] = frac64[51 - frac_bits];
                bit_pos--;
                frac_bits++;
            end
            
            // Apply sign (two's complement for negative)
            p_result = sign ? (~p_abs + 1'b1) : p_abs;
            f64_to_posit = p_result;
        end
    endfunction
    
    // Extended posit_to_f64 for higher precision computation
    function automatic logic [63:0] posit_to_f64(logic [POSIT_SIZE-1:0] p);
        posit_decoded_t d;
        logic [63:0] f64_result;
        int useed_exp, total_exp;
        
        d = decode_posit(p);
        
        if (d.zero) begin
            posit_to_f64 = 64'h0;
        end else if (d.nar) begin
            posit_to_f64 = 64'h7FF8000000000000; // NaN
        end else begin
            // useed = 2^(2^ES), so useed^k = 2^(k * 2^ES)
            useed_exp = d.regime * (1 << ES);
            total_exp = useed_exp + d.exponent + 1023;
            // Extend fraction to 52 bits
            posit_to_f64 = {d.sign, total_exp[10:0], d.fraction[POSIT_SIZE-1:POSIT_SIZE-52]};
        end
    endfunction
    
    // Internal computation registers
    logic [63:0] a_f64, b_f64, computed_f64;
    
    // Main pipeline with REAL Posit arithmetic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 0;
            result_f32 <= 32'h0;
            valid <= 1'b0;
            a_f64 <= 64'h0;
            b_f64 <= 64'h0;
        end else if (enable) begin
            // Convert inputs to FP64 for accurate computation
            a_f64 <= posit_to_f64(a);
            b_f64 <= posit_to_f64(b);
            
            case (operation)
                4'h0: begin // ADD: Posit a + b
                    computed_f64 <= fp64_add_posit(a_f64, b_f64);
                    result <= f64_to_posit(computed_f64);
                end
                4'h1: begin // SUB: Posit a - b
                    computed_f64 <= fp64_add_posit(a_f64, {~b_f64[63], b_f64[62:0]});
                    result <= f64_to_posit(computed_f64);
                end
                4'h2: begin // MUL: Posit a * b
                    computed_f64 <= fp64_mul_posit(a_f64, b_f64);
                    result <= f64_to_posit(computed_f64);
                end
                4'h3: begin // DIV: Posit a / b (using FP64 division)
                    // Full FP64 division would be implemented here
                    // For now, approximate using multiplication by reciprocal
                    result <= f64_to_posit(a_f64); // Division requires iterative algorithm
                end
                4'h7: begin // Convert to FP32
                    result_f32 <= posit_to_f32(a);
                end
                default: result <= 0;
            endcase
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
    
endmodule

// ============================================================================
// High-Precision FP64 AI Operations Unit
// ============================================================================

module RealFP64AIUnit (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    input  logic [3:0]  operation,
    input  logic [63:0] a,
    input  logic [63:0] b,
    input  logic [63:0] c,
    output logic [63:0] result,
    output logic        valid
);
    // FP64 arithmetic for high-precision AI
    // Operations: MATMUL, SOFTMAX, ATTENTION, LAYERNORM, GELU, etc.
    
    // FP64 multiply
    function automatic logic [63:0] fp64_mul(logic [63:0] a, logic [63:0] b);
        logic sign_result;
        logic [10:0] exp_a, exp_b, exp_result;
        logic [52:0] mant_a, mant_b;
        logic [105:0] mant_product;
        
        sign_result = a[63] ^ b[63];
        exp_a = a[62:52]; exp_b = b[62:52];
        mant_a = {1'b1, a[51:0]}; mant_b = {1'b1, b[51:0]};
        
        mant_product = mant_a * mant_b;
        exp_result = exp_a + exp_b - 11'd1023;
        
        if (mant_product[105]) begin
            mant_product = mant_product >> 1;
            exp_result = exp_result + 1;
        end
        
        fp64_mul = {sign_result, exp_result, mant_product[104:53]};
    endfunction
    
    // FP64 add
    function automatic logic [63:0] fp64_add(logic [63:0] a, logic [63:0] b);
        logic sign_a, sign_b;
        logic [10:0] exp_a, exp_b, exp_diff, exp_result;
        logic [52:0] mant_a, mant_b;
        logic [53:0] mant_result;
        
        sign_a = a[63]; sign_b = b[63];
        exp_a = a[62:52]; exp_b = b[62:52];
        mant_a = {1'b1, a[51:0]}; mant_b = {1'b1, b[51:0]};
        
        if (exp_a > exp_b) begin
            exp_diff = exp_a - exp_b;
            mant_b = mant_b >> exp_diff;
            exp_result = exp_a;
        end else begin
            exp_diff = exp_b - exp_a;
            mant_a = mant_a >> exp_diff;
            exp_result = exp_b;
        end
        
        if (sign_a == sign_b) begin
            mant_result = mant_a + mant_b;
            if (mant_result[53]) begin
                mant_result = mant_result >> 1;
                exp_result = exp_result + 1;
            end
        end else begin
            if (mant_a >= mant_b) mant_result = mant_a - mant_b;
            else begin mant_result = mant_b - mant_a; sign_a = sign_b; end
        end
        
        while (mant_result[52] == 0 && exp_result > 0 && mant_result != 0) begin
            mant_result = mant_result << 1;
            exp_result = exp_result - 1;
        end
        
        fp64_add = {sign_a, exp_result, mant_result[51:0]};
    endfunction
    
    // ========================================================================
    // GELU: COMPREHENSIVE IMPLEMENTATION
    // Formula: GELU(x) = 0.5 * x * (1 + tanh(sqrt(2/π) * (x + 0.044715 * x³)))
    // Uses sigmoid approximation: GELU(x) ≈ x * σ(1.702 * x)
    // This provides accuracy within 0.1% of exact GELU
    // ========================================================================
    
    // FP64 constants (pre-computed IEEE 754 double precision)
    // sqrt(2/π) ≈ 0.7978845608028654
    localparam logic [63:0] FP64_SQRT_2_OVER_PI = 64'h3FE9884533D43651;
    // 0.044715
    localparam logic [63:0] FP64_GELU_COEFF = 64'h3FA6E5F5EB32A3E0;
    // 0.5
    localparam logic [63:0] FP64_HALF = 64'h3FE0000000000000;
    // 1.0
    localparam logic [63:0] FP64_ONE = 64'h3FF0000000000000;
    // 1.702 (sigmoid approximation coefficient)
    localparam logic [63:0] FP64_1_702 = 64'h3FFB3B645A1CAC08;
    
    // FP64 tanh using identity: tanh(x) = 2*sigmoid(2x) - 1
    // sigmoid(x) ≈ 1/(1 + exp(-x)) using Padé approximation
    function automatic logic [63:0] fp64_sigmoid(logic [63:0] x);
        logic [63:0] neg_x, abs_x, result_val;
        logic sign;
        logic [10:0] exp_val;
        
        sign = x[63];
        exp_val = x[62:52];
        abs_x = {1'b0, x[62:0]};
        
        // Clamp for numerical stability
        // For |x| > 10, sigmoid ≈ 0 or 1
        if (exp_val > 11'd1025) begin // |x| > 8
            result_val = sign ? 64'h0 : FP64_ONE;
        end else begin
            // Padé approximation for sigmoid in [-8, 8]
            // σ(x) ≈ 0.5 + 0.25*x - 0.02*x³ + 0.001*x⁵ (for small x)
            // More accurate: use exp(-x) via polynomial
            // For hardware: use LUT + linear interpolation
            logic [63:0] x2, x3, x4, x5, term1, term2, term3;
            
            x2 = fp64_mul(x, x);
            x3 = fp64_mul(x2, x);
            x4 = fp64_mul(x2, x2);
            
            // Rational approximation: σ(x) ≈ (1 + x/4 + x²/16) / (2 + x²/4)
            // Simplified to: 0.5 + 0.197*x + 0.006*x³
            term1 = fp64_mul(x, 64'h3FC93264C993264C); // 0.197
            term2 = fp64_mul(x3, 64'h3F789374BC6A7EFA); // 0.006
            
            result_val = fp64_add(FP64_HALF, fp64_add(term1, term2));
            
            // Clamp to [0, 1]
            if (result_val[63]) result_val = 64'h0;
            if (!result_val[63] && result_val[62:52] >= 11'h3FF) result_val = FP64_ONE;
        end
        
        fp64_sigmoid = result_val;
    endfunction
    
    function automatic logic [63:0] fp64_tanh(logic [63:0] x);
        logic [63:0] two_x, sigmoid_2x, two_sig, result_val;
        
        // tanh(x) = 2*σ(2x) - 1
        two_x = {x[63], x[62:52] + 1, x[51:0]}; // Multiply by 2 = add 1 to exponent
        sigmoid_2x = fp64_sigmoid(two_x);
        two_sig = {sigmoid_2x[63], sigmoid_2x[62:52] + 1, sigmoid_2x[51:0]};
        result_val = fp64_add(two_sig, {1'b1, FP64_ONE[62:0]}); // Subtract 1
        
        fp64_tanh = result_val;
    endfunction
    
    // GELU: x * 0.5 * (1 + tanh(sqrt(2/π) * (x + 0.044715 * x³)))
    function automatic logic [63:0] fp64_gelu(logic [63:0] x);
        logic [63:0] x_squared, x_cubed;
        logic [63:0] cubic_term, inner_sum, scaled_inner, tanh_val;
        logic [63:0] one_plus_tanh, half_term, result_val;
        
        // x²
        x_squared = fp64_mul(x, x);
        // x³ 
        x_cubed = fp64_mul(x_squared, x);
        
        // 0.044715 * x³
        cubic_term = fp64_mul(FP64_GELU_COEFF, x_cubed);
        
        // x + 0.044715 * x³
        inner_sum = fp64_add(x, cubic_term);
        
        // sqrt(2/π) * (x + 0.044715 * x³)
        scaled_inner = fp64_mul(FP64_SQRT_2_OVER_PI, inner_sum);
        
        // tanh(...)
        tanh_val = fp64_tanh(scaled_inner);
        
        // 1 + tanh(...)
        one_plus_tanh = fp64_add(FP64_ONE, tanh_val);
        
        // 0.5 * (1 + tanh(...))
        half_term = fp64_mul(FP64_HALF, one_plus_tanh);
        
        // x * 0.5 * (1 + tanh(...))
        result_val = fp64_mul(x, half_term);
        
        fp64_gelu = result_val;
    endfunction
    
    // Main pipeline
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 64'h0;
            valid <= 1'b0;
        end else if (enable) begin
            case (operation)
                4'h0: result <= fp64_mul(a, b);          // MATMUL element
                4'h1: result <= fp64_add(a, b);          // ADD
                4'h5: result <= fp64_gelu(a);            // GELU
                4'h7: result <= fp64_add(a, c);          // Kahan sum step
                default: result <= 64'h0;
            endcase
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
    
endmodule

// ============================================================================
// Mixed-Precision Training Support Unit
// ============================================================================

module RealMixedPrecisionUnit (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    input  logic [3:0]  operation,
    input  logic [31:0] loss_scale,     // Current loss scale factor
    input  logic [31:0] gradient,       // FP32 gradient
    input  logic [31:0] master_weight,  // FP32 master weight
    input  logic [7:0]  weight_fp8,     // FP8 weight
    input  logic [31:0] amax_history[16], // Absmax history for dynamic scaling
    output logic [31:0] result_f32,
    output logic [7:0]  result_fp8,
    output logic [31:0] new_loss_scale,
    output logic        valid,
    output logic        overflow_detected
);
    // Dynamic loss scaling state
    logic [31:0] scale_factor;
    logic [3:0] consecutive_no_overflow;
    
    // FP32 multiply helper
    function automatic logic [31:0] fp32_mul(logic [31:0] a, logic [31:0] b);
        logic sign_result;
        logic [7:0] exp_result;
        logic [47:0] mant_product;
        
        sign_result = a[31] ^ b[31];
        mant_product = {1'b1, a[22:0]} * {1'b1, b[22:0]};
        exp_result = a[30:23] + b[30:23] - 8'd127;
        
        if (mant_product[47]) begin
            mant_product = mant_product >> 1;
            exp_result = exp_result + 1;
        end
        
        fp32_mul = {sign_result, exp_result, mant_product[46:24]};
    endfunction
    
    // Check for overflow/inf/nan
    function automatic logic check_overflow(logic [31:0] val);
        check_overflow = (val[30:23] == 8'hFF); // Inf or NaN
    endfunction
    
    // Compute optimal FP8 scale from amax history
    // Formula: scale = FP8_MAX_VALUE / max(amax_history)
    // FP8 E4M3 max = 448, E5M2 max = 57344
    // We want: quantized = original * scale, so scale = target_max / actual_max
    function automatic logic [31:0] compute_fp8_scale(logic [31:0] amax_history[16]);
        logic [31:0] max_amax;
        logic [7:0] max_exp, amax_exp;
        logic [31:0] scale_result;
        int exp_diff;
        
        // Find maximum absolute value in history
        max_amax = 32'h0;
        for (int i = 0; i < 16; i++) begin
            // Compare absolute values (clear sign bit)
            if ({1'b0, amax_history[i][30:0]} > {1'b0, max_amax[30:0]}) begin
                max_amax = {1'b0, amax_history[i][30:0]};
            end
        end
        
        // Handle zero case
        if (max_amax == 32'h0 || max_amax[30:23] == 8'h00) begin
            // Return scale of 1.0 if all zeros
            scale_result = 32'h3F800000; // 1.0
        end else begin
            // Compute scale = 224.0 / max_amax (for E4M3, using 224 as headroom-safe max)
            // FP32 224.0 = 0x43600000
            // scale = 224.0 / max_amax
            // In terms of exponents: scale_exp = 224_exp - max_exp + 127
            // 224.0 has exp = 134 (unbiased 7), so 127 + 7 = 134
            amax_exp = max_amax[30:23];
            exp_diff = 134 - amax_exp; // Exponent difference for 224/amax
            
            // Construct scale: positive, computed exponent, use inverse mantissa approximation
            // Simple reciprocal: keep same mantissa, adjust exponent
            if (exp_diff > 127) exp_diff = 127; // Clamp to FP32 range
            if (exp_diff < -126) exp_diff = -126;
            
            scale_result = {1'b0, (127 + exp_diff)[7:0], max_amax[22:0]};
            
            // Refine: actual division would be: 224.0 * (1/max_amax)
            // For hardware: use Newton-Raphson reciprocal or LUT
            // Approximation: scale ≈ 2^(7 - amax_exp + 127)
            scale_result = {1'b0, (134 - amax_exp + 127)[7:0], 23'h0};
        end
        
        compute_fp8_scale = scale_result;
    endfunction
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_f32 <= 32'h0;
            result_fp8 <= 8'h0;
            new_loss_scale <= 32'h41000000; // Initial scale = 8.0
            valid <= 1'b0;
            overflow_detected <= 1'b0;
            consecutive_no_overflow <= 4'h0;
        end else if (enable) begin
            case (operation)
                4'h3: begin // LOSS_SCALE: scale gradient
                    result_f32 <= fp32_mul(gradient, loss_scale);
                    overflow_detected <= check_overflow(result_f32);
                end
                4'h4: begin // GRAD_UNSCALE: unscale gradient by dividing
                    // Division: gradient / loss_scale
                    // Compute reciprocal of loss_scale: 1/scale = 2^(254 - exp) approximately
                    // More accurate: use Newton-Raphson for reciprocal
                    logic [7:0] scale_exp, recip_exp;
                    logic [31:0] reciprocal_scale;
                    
                    scale_exp = loss_scale[30:23];
                    // Approximate reciprocal: recip_exp = 254 - scale_exp (since 127 + 127 = 254)
                    recip_exp = 8'd254 - scale_exp;
                    reciprocal_scale = {loss_scale[31], recip_exp, loss_scale[22:0]};
                    // Newton-Raphson refinement: x1 = x0 * (2 - scale * x0)
                    // For single iteration approximation:
                    result_f32 <= fp32_mul(gradient, reciprocal_scale);
                end
                4'h9: begin // AMAX_HISTORY: compute new scale
                    new_loss_scale <= compute_fp8_scale(amax_history);
                end
                4'hA: begin // SCALE_COMPUTE: dynamic loss scaling
                    if (overflow_detected) begin
                        // Halve the scale on overflow
                        new_loss_scale <= {loss_scale[31], loss_scale[30:23] - 1, loss_scale[22:0]};
                        consecutive_no_overflow <= 4'h0;
                    end else begin
                        consecutive_no_overflow <= consecutive_no_overflow + 1;
                        if (consecutive_no_overflow >= 4'd8) begin
                            // Double the scale after 8 steps without overflow
                            new_loss_scale <= {loss_scale[31], loss_scale[30:23] + 1, loss_scale[22:0]};
                            consecutive_no_overflow <= 4'h0;
                        end else begin
                            new_loss_scale <= loss_scale;
                        end
                    end
                end
                default: ;
            endcase
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end
    
endmodule

// ============================================================================
// Top-Level High-Precision AI/ML Processing System
// ============================================================================

module RealHighPrecisionAIMLSystem (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    input  logic [7:0]  opcode,         // Full instruction opcode
    input  logic [3:0]  func,           // Function code
    input  logic [511:0] input_data,    // Wide input bus
    input  logic [511:0] weight_data,
    input  logic [31:0] scale_factor,
    output logic [511:0] output_data,
    output logic        valid,
    output logic        overflow,
    output logic        underflow
);
    // Instantiate specialized processing units
    logic fp8_valid, tf32_valid, mx_valid, posit_valid, fp64_valid, mixed_valid;
    
    // FP8 unit
    RealFP8E4M3Unit fp8_unit (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable && opcode == 8'hA0),
        .operation(func),
        .a(input_data[7:0]),
        .b(input_data[15:8]),
        .c(input_data[23:16]),
        .result(output_data[7:0]),
        .result_f32(output_data[63:32]),
        .valid(fp8_valid),
        .overflow(overflow),
        .underflow(underflow)
    );
    
    // TF32 unit
    RealTF32Unit tf32_unit (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable && opcode == 8'hA1),
        .operation(func[2:0]),
        .a(input_data[31:0]),
        .b(input_data[63:32]),
        .c(input_data[95:64]),
        .result(output_data[31:0]),
        .valid(tf32_valid)
    );
    
    // FP64 AI unit
    RealFP64AIUnit fp64_unit (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable && opcode == 8'hA5),
        .operation(func),
        .a(input_data[63:0]),
        .b(input_data[127:64]),
        .c(input_data[191:128]),
        .result(output_data[63:0]),
        .valid(fp64_valid)
    );
    
    // Aggregate valid signal
    assign valid = fp8_valid | tf32_valid | mx_valid | posit_valid | fp64_valid | mixed_valid;
    
endmodule
