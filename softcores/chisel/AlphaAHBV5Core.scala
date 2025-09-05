//> using scala "2.13.12"
//> using dep "org.chipsalliance::chisel:6.7.0"
//> using plugin "org.chipsalliance:::chisel-plugin:6.7.0"
//> using options "-unchecked", "-deprecation", "-language:reflectiveCalls", "-feature", "-Xcheckinit", "-Xfatal-warnings", "-Ywarn-dead-code", "-Ywarn-unused", "-Ymacro-annotations"

import chisel3._
import chisel3.util._
import _root_.circt.stage.ChiselStage

// AlphaAHB V5 CPU Core - Chisel Implementation
class AlphaAHBV5Core extends Module {
  val io = IO(new Bundle {
    // Clock and Reset
    val clk = Input(Clock())
    val rst_n = Input(Bool())
    
    // Instruction Memory Interface
    val imem_addr = Output(UInt(64.W))
    val imem_data = Input(UInt(64.W))
    val imem_valid = Input(Bool())
    
    // Data Memory Interface
    val dmem_addr = Output(UInt(64.W))
    val dmem_data_out = Output(UInt(64.W))
    val dmem_data_in = Input(UInt(64.W))
    val dmem_we = Output(Bool())
    val dmem_valid = Input(Bool())
    
    // Register File Interface
    val reg_read_addr1 = Output(UInt(8.W))
    val reg_read_addr2 = Output(UInt(8.W))
    val reg_read_data1 = Output(UInt(64.W))
    val reg_read_data2 = Output(UInt(64.W))
    val reg_write_addr = Output(UInt(8.W))
    val reg_write_data = Output(UInt(64.W))
    val reg_write_en = Output(Bool())
    
    // Control Signals
    val stall = Input(Bool())
    val flush = Input(Bool())
    val pc = Output(UInt(64.W))
    val instruction = Output(UInt(64.W))
    
    // Status
    val valid = Output(Bool())
    val ready = Output(Bool())
  })
  
  // Program Counter
  val pc_reg = RegInit(0.U(64.W))
  val pc_next = pc_reg + 4.U
  
  // Instruction Register
  val instruction_reg = RegInit(0.U(64.W))
  
  // Control Unit
  val control_unit = Module(new ControlUnit)
  control_unit.io.instruction := instruction_reg
  control_unit.io.stall := io.stall
  control_unit.io.flush := io.flush
  
  // Register File
  val register_file = Module(new RegisterFile)
  register_file.io.clk := io.clk
  register_file.io.rst_n := io.rst_n
  register_file.io.read_addr1 := io.reg_read_addr1
  register_file.io.read_addr2 := io.reg_read_addr2
  register_file.io.write_addr := io.reg_write_addr
  register_file.io.write_data := io.reg_write_data
  register_file.io.write_en := io.reg_write_en
  
  // ALU
  val alu = Module(new ALU)
  alu.io.operand1 := register_file.io.read_data1
  alu.io.operand2 := register_file.io.read_data2
  alu.io.operation := control_unit.io.alu_op
  
  // Pipeline Registers
  val if_id_reg = RegInit(0.U(64.W))
  val id_ex_reg = RegInit(0.U(64.W))
  val ex_mem_reg = RegInit(0.U(64.W))
  val mem_wb_reg = RegInit(0.U(64.W))
  
  // Outputs
  io.imem_addr := pc_reg
  io.instruction := instruction_reg
  io.pc := pc_reg
  io.valid := control_unit.io.valid
  io.ready := control_unit.io.ready
  
  
  // Memory connections
  io.dmem_addr := alu.io.result
  io.dmem_data_out := register_file.io.read_data2
  io.dmem_we := control_unit.io.mem_write
  
  // Control signals
  io.reg_read_addr1 := control_unit.io.reg_read_addr1
  io.reg_read_addr2 := control_unit.io.reg_read_addr2
  io.reg_write_addr := control_unit.io.reg_write_addr
  io.reg_write_data := alu.io.result
  io.reg_write_en := control_unit.io.reg_write_en
  
  // Register file data outputs
  io.reg_read_data1 := register_file.io.read_data1
  io.reg_read_data2 := register_file.io.read_data2
  
  // Pipeline logic
  when(!io.stall) {
    pc_reg := pc_next
    instruction_reg := io.imem_data
    if_id_reg := instruction_reg
    id_ex_reg := if_id_reg
    ex_mem_reg := id_ex_reg
    mem_wb_reg := ex_mem_reg
  }
}

// Control Unit
class ControlUnit extends Module {
  val io = IO(new Bundle {
    val instruction = Input(UInt(64.W))
    val stall = Input(Bool())
    val flush = Input(Bool())
    val alu_op = Output(UInt(4.W))
    val reg_read_addr1 = Output(UInt(8.W))
    val reg_read_addr2 = Output(UInt(8.W))
    val reg_write_addr = Output(UInt(8.W))
    val reg_write_en = Output(Bool())
    val mem_write = Output(Bool())
    val valid = Output(Bool())
    val ready = Output(Bool())
  })
  
  // Decode instruction
  val opcode = io.instruction(63, 58)
  val rs1 = io.instruction(57, 50)
  val rs2 = io.instruction(49, 42)
  val rd = io.instruction(41, 34)
  
  // Control signals
  io.alu_op := MuxCase(0.U, Seq(
    (opcode === "b000000".U) -> 0.U,  // ADD
    (opcode === "b000001".U) -> 1.U,  // SUB
    (opcode === "b000010".U) -> 2.U,  // AND
    (opcode === "b000011".U) -> 3.U,  // OR
    (opcode === "b000100".U) -> 4.U   // XOR
  ))
  
  io.reg_read_addr1 := rs1
  io.reg_read_addr2 := rs2
  io.reg_write_addr := rd
  io.reg_write_en := !io.stall && !io.flush
  io.mem_write := opcode === "b001000".U  // STORE
  io.valid := !io.stall
  io.ready := true.B
}

// Register File
class RegisterFile extends Module {
  val io = IO(new Bundle {
    val clk = Input(Clock())
    val rst_n = Input(Bool())
    val read_addr1 = Input(UInt(8.W))
    val read_addr2 = Input(UInt(8.W))
    val write_addr = Input(UInt(8.W))
    val write_data = Input(UInt(64.W))
    val write_en = Input(Bool())
    val read_data1 = Output(UInt(64.W))
    val read_data2 = Output(UInt(64.W))
  })
  
  // 256 registers (8-bit address)
  val registers = Mem(256, UInt(64.W))
  
  // Read ports
  io.read_data1 := registers(io.read_addr1)
  io.read_data2 := registers(io.read_addr2)
  
  // Write port
  when(io.write_en) {
    registers(io.write_addr) := io.write_data
  }
}

// ALU
class ALU extends Module {
  val io = IO(new Bundle {
    val operand1 = Input(UInt(64.W))
    val operand2 = Input(UInt(64.W))
    val operation = Input(UInt(4.W))
    val result = Output(UInt(64.W))
  })
  
  io.result := MuxCase(0.U, Seq(
    (io.operation === 0.U) -> (io.operand1 + io.operand2),  // ADD
    (io.operation === 1.U) -> (io.operand1 - io.operand2),  // SUB
    (io.operation === 2.U) -> (io.operand1 & io.operand2),  // AND
    (io.operation === 3.U) -> (io.operand1 | io.operand2),  // OR
    (io.operation === 4.U) -> (io.operand1 ^ io.operand2)   // XOR
  ))
}

// Test Harness
object Main extends App {
  println("Generating AlphaAHB V5 Core SystemVerilog...")
  
  val verilog = ChiselStage.emitSystemVerilog(
    gen = new AlphaAHBV5Core,
    firtoolOpts = Array("-disable-all-randomization", "-strip-debug-info")
  )
  
  println(verilog)
  println("AlphaAHB V5 Core SystemVerilog generation complete!")
}
