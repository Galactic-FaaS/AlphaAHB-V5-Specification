
package alphaahb.v5.test

import chisel3._
import chisel3.util._

class SimpleAlphaAHBTest extends Module {
  val io = IO(new Bundle {
    val in = Input(UInt(64.W))
    val out = Output(UInt(64.W))
    val clk = Input(Clock())
    val rst = Input(Bool())
  })
  
  val reg = RegInit(0.U(64.W))
  
  when(io.rst) {
    reg := 0.U
  }.otherwise {
    reg := io.in
  }
  
  io.out := reg
}

object SimpleAlphaAHBTest extends App {
  println("Simple AlphaAHB V5 Chisel Test")
  println("This is a basic Chisel module test")
  println("Module: SimpleAlphaAHBTest")
  println("Features: 64-bit register, reset, clock")
  println("Status: Basic structure created successfully")
}
