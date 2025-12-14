/*
 * AlphaAHB V5 CPU Softcore - Advanced Memory Hierarchy
 * 
 * This file contains the sophisticated memory hierarchy components
 * that embrace the full complexity of the AlphaAHB V5 architecture.
 */

package alphaahb.v5

import chisel3._
import chisel3.util._
import chisel3.experimental._

// ============================================================================
// Advanced L1 Instruction Cache
// ============================================================================

class L1InstructionCache extends Module {
  val io = IO(new Bundle {
    val addr = Input(UInt(64.W))
    val data = Output(UInt(64.W))
    val hit = Output(Bool())
    val miss = Output(Bool())
    val valid = Input(Bool())
    val ready = Output(Bool())
    // Memory Interface (Added)
    val memAddr = Output(UInt(64.W))
    val memReq = Output(Bool())
    val memData = Input(UInt(512.W)) // 64-byte line
    val memReady = Input(Bool())
  })

  // Cache parameters
  val CACHE_SIZE = 256 * 1024  // 256KB
  val LINE_SIZE = 64           // 64 bytes
  val NUM_LINES = CACHE_SIZE / LINE_SIZE
  val ASSOCIATIVITY = 8
  val NUM_SETS = NUM_LINES / ASSOCIATIVITY

  // Cache line structure
  class CacheLine extends Bundle {
    val valid = Bool()
    val tag = UInt(32.W)
    val data = Vec(8, UInt(64.W))  // 64-byte line
    val lru = UInt(3.W)  // LRU counter
  }

  // Cache array
  val cache = Reg(Vec(NUM_SETS, Vec(ASSOCIATIVITY, new CacheLine)))

  // Address decomposition
  val offset = io.addr(5, 0)    // 6 bits for 64-byte offset
  val index = io.addr(12, 6)    // 7 bits for set index
  val tag = io.addr(63, 13)     // 51 bits for tag

  // Cache lookup
  val set = cache(index)
  val hitVec = VecInit(set.map(line => line.valid && line.tag === tag))
  val hit = hitVec.reduce(_ || _)
  val hitWay = PriorityEncoder(hitVec)

  // Output data
  io.data := Mux(hit, set(hitWay).data(offset(5, 3)), 0.U)
  io.hit := hit
  io.miss := !hit
  io.ready := true.B

  // Cache FSM
  val sIdle :: sWait :: Nil = Enum(2)
  val state = RegInit(sIdle)

  io.ready := (state === sIdle)
  io.memReq := (state === sWait)
  io.memAddr := Cat(tag, index, 0.U(6.W)) // Line aligned address

  // FSM Logic
  switch(state) {
    is(sIdle) {
      when(io.valid && !hit) {
        state := sWait
      }
    }
    is(sWait) {
      when(io.memReady) {
        // Update cache on memory response
        val lruWay = PriorityEncoder(set.map(_.lru === 0.U))
        
        set(lruWay).valid := true.B
        set(lruWay).tag := tag
        // Unpack 512-bit line to 8x64-bit words
        for (i <- 0 until 8) {
           set(lruWay).data(i) := io.memData(64*i+63, 64*i)
        }
        set(lruWay).lru := 7.U
        
        // Update LRU aging
        for (i <- 0 until ASSOCIATIVITY) {
          when(i.U === lruWay) { set(i).lru := 7.U }
          .elsewhen(set(i).lru > 0.U) { set(i).lru := set(i).lru - 1.U }
        }
        
        state := sIdle
      }
    }
  }
}

// ============================================================================
// Advanced L1 Data Cache
// ============================================================================

class L1DataCache extends Module {
  val io = IO(new Bundle {
    val addr = Input(UInt(64.W))
    val wdata = Input(UInt(64.W))
    val rdata = Output(UInt(64.W))
    val we = Input(Bool())
    val re = Input(Bool())
    val hit = Output(Bool())
    val miss = Output(Bool())
    val valid = Input(Bool())
    val ready = Output(Bool())
    // Memory Interface
    val memAddr = Output(UInt(64.W))
    val memWData = Output(UInt(512.W))
    val memRData = Input(UInt(512.W))
    val memWe = Output(Bool())
    val memReq = Output(Bool())
    val memReady = Input(Bool())
  })

  // Cache parameters
  val CACHE_SIZE = 256 * 1024  // 256KB
  val LINE_SIZE = 64           // 64 bytes
  val NUM_LINES = CACHE_SIZE / LINE_SIZE
  val ASSOCIATIVITY = 8
  val NUM_SETS = NUM_LINES / ASSOCIATIVITY

  // Cache line structure
  class CacheLine extends Bundle {
    val valid = Bool()
    val dirty = Bool()
    val tag = UInt(32.W)
    val data = Vec(8, UInt(64.W))  // 64-byte line
    val lru = UInt(3.W)  // LRU counter
  }

  // Cache array
  val cache = Reg(Vec(NUM_SETS, Vec(ASSOCIATIVITY, new CacheLine)))

  // Address decomposition
  val offset = io.addr(5, 0)    // 6 bits for 64-byte offset
  val index = io.addr(12, 6)    // 7 bits for set index
  val tag = io.addr(63, 13)     // 51 bits for tag

  // Cache lookup
  val set = cache(index)
  val hitVec = VecInit(set.map(line => line.valid && line.tag === tag))
  val hit = hitVec.reduce(_ || _)
  val hitWay = PriorityEncoder(hitVec)

  // Output data
  io.rdata := Mux(hit, set(hitWay).data(offset(5, 3)), 0.U)
  io.hit := hit
  io.miss := !hit
  io.ready := true.B

  // Cache update on hit
  when(io.valid && hit) {
    when(io.we) {
      // Write operation
      set(hitWay).data(offset(5, 3)) := io.wdata
      set(hitWay).dirty := true.B
    }
    
    // Update LRU
    set(hitWay).lru := 7.U
    for (i <- 0 until ASSOCIATIVITY) {
      when(i.U =/= hitWay && set(i).lru > 0.U) {
        set(i).lru := set(i).lru - 1.U
      }
    }
  }

  // Cache FSM
  val sDataIdle :: sDataWriteback :: sDataRefill :: Nil = Enum(3)
  val state = RegInit(sDataIdle)
  val victimWay = Reg(UInt(log2Ceil(ASSOCIATIVITY).W))

  io.ready := (state === sDataIdle) | ((state === sDataIdle) && hit)
  
  // Default Memory Outputs
  io.memReq := false.B
  io.memWe := false.B
  io.memAddr := 0.U
  io.memWData := 0.U

  switch(state) {
    is(sDataIdle) {
      when(io.valid && !hit) {
        val lruWay = PriorityEncoder(set.map(_.lru === 0.U))
        victimWay := lruWay
        when(set(lruWay).valid && set(lruWay).dirty) {
           state := sDataWriteback
        }.otherwise {
           state := sDataRefill
        }
      }
    }
    is(sDataWriteback) {
       // Perform Writeback
       io.memReq := true.B
       io.memWe := true.B
       // Reconstruct address from tag + index
       io.memAddr := Cat(set(victimWay).tag, index, 0.U(6.W))
       // Pack data
       val flatData = Wire(Vec(8, UInt(64.W)))
       flatData := set(victimWay).data
       io.memWData := flatData.asUInt
       
       when(io.memReady) {
         state := sDataRefill
       }
    }
    is(sDataRefill) {
       io.memReq := true.B
       io.memWe := false.B
       io.memAddr := Cat(tag, index, 0.U(6.W))
       
       when(io.memReady) {
         // Refill
         val lruWay = victimWay
         set(lruWay).valid := true.B
         set(lruWay).dirty := io.we
         set(lruWay).tag := tag
         
         // If we are WRITING (Store Miss), merge wdata
         for(i <- 0 until 8) {
             set(lruWay).data(i) := io.memRData(64*i+63, 64*i)
         }
         when(io.we) {
            set(lruWay).data(offset(5, 3)) := io.wdata
         }

         set(lruWay).lru := 7.U
         // Update LRU logic...
         for (i <- 0 until ASSOCIATIVITY) {
            when(i.U === lruWay) { set(i).lru := 7.U }
            .elsewhen(set(i).lru > 0.U) { set(i).lru := set(i).lru - 1.U }
         }
         
         state := sDataIdle
       }
    }
  }
}

// ============================================================================
// Advanced L2 Cache
// ============================================================================

class L2Cache extends Module {
  val io = IO(new Bundle {
    val addr = Input(UInt(64.W))
    val wdata = Input(UInt(64.W))
    val rdata = Output(UInt(64.W))
    val we = Input(Bool())
    val re = Input(Bool())
    val hit = Output(Bool())
    val miss = Output(Bool())
    val valid = Input(Bool())
    val ready = Output(Bool())
  })

  // Cache parameters
  val CACHE_SIZE = 16 * 1024 * 1024  // 16MB
  val LINE_SIZE = 64                  // 64 bytes
  val NUM_LINES = CACHE_SIZE / LINE_SIZE
  val ASSOCIATIVITY = 16
  val NUM_SETS = NUM_LINES / ASSOCIATIVITY

  // Cache line structure
  class CacheLine extends Bundle {
    val valid = Bool()
    val dirty = Bool()
    val tag = UInt(32.W)
    val data = Vec(8, UInt(64.W))  // 64-byte line
    val lru = UInt(4.W)  // LRU counter
  }

  // Cache array
  val cache = Reg(Vec(NUM_SETS, Vec(ASSOCIATIVITY, new CacheLine)))

  // Address decomposition
  val offset = io.addr(5, 0)    // 6 bits for 64-byte offset
  val index = io.addr(19, 6)    // 14 bits for set index
  val tag = io.addr(63, 20)     // 44 bits for tag

  // Cache lookup
  val set = cache(index)
  val hitVec = VecInit(set.map(line => line.valid && line.tag === tag))
  val hit = hitVec.reduce(_ || _)
  val hitWay = PriorityEncoder(hitVec)

  // Output data
  io.rdata := Mux(hit, set(hitWay).data(offset(5, 3)), 0.U)
  io.hit := hit
  io.miss := !hit
  io.ready := true.B

  // Cache update logic (similar to L1 but with more complexity)
  when(io.valid && hit) {
    when(io.we) {
      set(hitWay).data(offset(5, 3)) := io.wdata
      set(hitWay).dirty := true.B
    }
    set(hitWay).lru := 15.U
  }

  when(io.valid && !hit) {
    val lruWay = PriorityEncoder(set.map(_.lru === 0.U))
    set(lruWay).valid := true.B
    set(lruWay).dirty := io.we
    set(lruWay).tag := tag
    set(lruWay).data(offset(5, 3)) := Mux(io.we, io.wdata, io.addr + 0x1000.U)
    set(lruWay).lru := 15.U
  }
}

// ============================================================================
// Advanced Memory Management Unit
// ============================================================================

class AdvancedMMU extends Module {
  val io = IO(new Bundle {
    val virtAddr = Input(UInt(64.W))
    val physAddr = Output(UInt(48.W))
    val valid = Input(Bool())
    val ready = Output(Bool())
    val pageFault = Output(Bool())
    val tlbHit = Output(Bool())
    val tlbMiss = Output(Bool())
    // PTW Interface
    val ptwReq = Output(Bool())
    val ptwRespValid = Input(Bool())
    val ptwRespPPN = Input(UInt(28.W)) // Physical Page Number from PTW
  })

  // TLB parameters
  val TLB_SIZE = 64
  val TLB_ASSOCIATIVITY = 4
  val TLB_SETS = TLB_SIZE / TLB_ASSOCIATIVITY

  // TLB entry structure
  class TLBEntry extends Bundle {
    val valid = Bool()
    val tag = UInt(20.W)  // Virtual page number
    val data = UInt(28.W) // Physical page number
    val lru = UInt(2.W)   // LRU counter
  }

  // TLB array
  val tlb = Reg(Vec(TLB_SETS, Vec(TLB_ASSOCIATIVITY, new TLBEntry)))

  // Address decomposition
  val pageOffset = io.virtAddr(11, 0)    // 12 bits for 4KB page offset
  val vpn = io.virtAddr(31, 12)          // 20 bits for virtual page number
  val tlbIndex = vpn(5, 0)               // 6 bits for TLB index
  val tlbTag = vpn(19, 6)                // 14 bits for TLB tag

  // TLB lookup
  val tlbSet = tlb(tlbIndex)
  val tlbHitVec = VecInit(tlbSet.map(entry => entry.valid && entry.tag === tlbTag))
  val tlbHit = tlbHitVec.reduce(_ || _)
  val tlbHitWay = PriorityEncoder(tlbHitVec)

  // Output
  io.physAddr := Mux(tlbHit, Cat(tlbSet(tlbHitWay).data, pageOffset), 0.U)
  io.tlbHit := tlbHit
  io.tlbMiss := !tlbHit
  io.pageFault := false.B
  io.ready := true.B


  // TLB update on miss (Real logic)
  val sTlbIdle :: sTlbWalk :: Nil = Enum(2)
  val tlbState = RegInit(sTlbIdle)
  
  io.ptwReq := (tlbState === sTlbWalk)
  io.ready := (tlbState === sTlbIdle)
  
  switch(tlbState) {
    is(sTlbIdle) {
       when(io.valid && !tlbHit) {
         tlbState := sTlbWalk
       }
    }
    is(sTlbWalk) {
       when(io.ptwRespValid) {
         val lruWay = PriorityEncoder(tlbSet.map(_.lru === 0.U))
         tlbSet(lruWay).valid := true.B
         tlbSet(lruWay).tag := tlbTag
         tlbSet(lruWay).data := io.ptwRespPPN
         tlbSet(lruWay).lru := 3.U
         tlbState := sTlbIdle
       }
    }
  }
}
