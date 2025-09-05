// Alpham Target Machine TableGen Definition
// MIMD-enhanced Alpha target for modern capabilities

include "llvm/Target/Target.td"

// Alpham target definition
def Alpham : Target {
  let InstructionSet = AlphamInstrInfo;
  let AssemblyParser = AlphamAsmParser;
  let AssemblyPrinter = AlphamAsmPrinter;
  let Disassembler = AlphamDisassembler;
  let InstrInfo = AlphamInstrInfo;
  let RegisterInfo = AlphamRegisterInfo;
  let Subtarget = AlphamSubtarget;
  let FrameLowering = AlphamFrameLowering;
  let SelectionDAGInfo = AlphamSelectionDAGInfo;
  let CallingConv = [CC_Alpham];
  let CodeGenRegisters = AlphamRegs;
  let CodeGenInstrs = AlphamInstrs;
  let CodeGenPseudoLowering = AlphamPseudoLowering;
}

// Alpham target machine
def AlphamTargetMachine : TargetMachine {
  let InstructionSet = AlphamInstrInfo;
  let AssemblyPrinter = AlphamAsmPrinter;
  let Disassembler = AlphamDisassembler;
  let InstrInfo = AlphamInstrInfo;
  let RegisterInfo = AlphamRegisterInfo;
  let Subtarget = AlphamSubtarget;
  let FrameLowering = AlphamFrameLowering;
  let SelectionDAGInfo = AlphamSelectionDAGInfo;
  let CallingConv = [CC_Alpham];
  let CodeGenRegisters = AlphamRegs;
  let CodeGenInstrs = AlphamInstrs;
  let CodeGenPseudoLowering = AlphamPseudoLowering;
}

// Alpham calling conventions
def CC_Alpham : CallingConv<[
  CCIfType<[i32], CCAssignToReg<[R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15, R16, R17, R18, R19, R20, R21, R22, R23, R24, R25, R26, R27, R28, R29, R30, R31]>>
]>;

// Alpham register classes
def GPR : RegisterClass<"Alpham", [i32, i64], 32, (add
  (sequence "R%u", 0, 31)
)>;

def FPR : RegisterClass<"Alpham", [f32, f64], 32, (add
  (sequence "F%u", 0, 31)
)>;

// Vector registers (512-bit SIMD)
def VPR : RegisterClass<"Alpham", [v16i32, v8i64, v32i16, v64i8], 32, (add
  (sequence "V%u", 0, 31)
)>;

// AI/ML registers
def AIR : RegisterClass<"Alpham", [i32, i64], 32, (add
  (sequence "A%u", 0, 31)
)>;

// MIMD registers
def MIMDR : RegisterClass<"Alpham", [i32, i64], 16, (add
  (sequence "M%u", 0, 15)
)>;

// Security registers
def SECR : RegisterClass<"Alpham", [i32, i64], 16, (add
  (sequence "SEC%u", 0, 15)
)>;

// Scientific computing registers
def SCR : RegisterClass<"Alpham", [i32, i64], 16, (add
  (sequence "SCR%u", 0, 15)
)>;

// Real-time registers
def RTR : RegisterClass<"Alpham", [i32, i64], 8, (add
  (sequence "RTR%u", 0, 7)
)>;

// Debug/profiling registers
def DPR : RegisterClass<"Alpham", [i32, i64], 16, (add
  (sequence "DPR%u", 0, 15)
)>;

// Alpham instruction formats
class AlphamInst<dag outs, dag ins, string asmstr, list<dag> pattern>
    : Instruction {
  let OutOperandList = outs;
  let InOperandList = ins;
  let AsmString = asmstr;
  let Pattern = pattern;
}

// Alpham basic instructions (inherited from Alpha)
def ADD : AlphamInst<(outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2), 
                     "add $rd, $rs1, $rs2", 
                     [(set i32:$rd, (add i32:$rs1, i32:$rs2))]>;

def SUB : AlphamInst<(outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2), 
                     "sub $rd, $rs1, $rs2", 
                     [(set i32:$rd, (sub i32:$rs1, i32:$rs2))]>;

def MUL : AlphamInst<(outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2), 
                     "mul $rd, $rs1, $rs2", 
                     [(set i32:$rd, (mul i32:$rs1, i32:$rs2))]>;

def DIV : AlphamInst<(outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2), 
                     "div $rd, $rs1, $rs2", 
                     [(set i32:$rd, (sdiv i32:$rs1, i32:$rs2))]>;

// Memory instructions
def LD : AlphamInst<(outs GPR:$rd), (ins GPR:$rs1, i32:$imm), 
                    "ld $rd, $imm($rs1)", 
                    [(set i32:$rd, (load i32:$rs1))]>;

def ST : AlphamInst<(outs), (ins GPR:$rs1, GPR:$rs2, i32:$imm), 
                   "st $rs1, $imm($rs2)", 
                   [(store i32:$rs1, i32:$rs2)]>;

// Branch instructions
def BEQ : AlphamInst<(outs), (ins GPR:$rs1, GPR:$rs2, i32:$imm), 
                     "beq $rs1, $rs2, $imm", 
                     [(brcond (seteq i32:$rs1, i32:$rs2), bb:$imm))]>;

def BNE : AlphamInst<(outs), (ins GPR:$rs1, GPR:$rs2, i32:$imm), 
                     "bne $rs1, $rs2, $imm", 
                     [(brcond (setne i32:$rs1, i32:$rs2), bb:$imm))]>;

def JMP : AlphamInst<(outs), (ins GPR:$rs1), 
                     "jmp $rs1", 
                     [(br i32:$rs1)]>;

// Floating-point instructions
def FADD : AlphamInst<(outs FPR:$rd), (ins FPR:$rs1, FPR:$rs2), 
                      "fadd $rd, $rs1, $rs2", 
                      [(set f32:$rd, (fadd f32:$rs1, f32:$rs2))]>;

def FSUB : AlphamInst<(outs FPR:$rd), (ins FPR:$rs1, FPR:$rs2), 
                      "fsub $rd, $rs1, $rs2", 
                      [(set f32:$rd, (fsub f32:$rs1, f32:$rs2))]>;

def FMUL : AlphamInst<(outs FPR:$rd), (ins FPR:$rs1, FPR:$rs2), 
                      "fmul $rd, $rs1, $rs2", 
                      [(set f32:$rd, (fmul f32:$rs1, f32:$rs2))]>;

def FDIV : AlphamInst<(outs FPR:$rd), (ins FPR:$rs1, FPR:$rs2), 
                      "fdiv $rd, $rs1, $rs2", 
                      [(set f32:$rd, (fdiv f32:$rs1, f32:$rs2))]>;

// Vector instructions (512-bit SIMD)
def VADD : AlphamInst<(outs VPR:$rd), (ins VPR:$rs1, VPR:$rs2), 
                      "vadd $rd, $rs1, $rs2", 
                      [(set v16i32:$rd, (add v16i32:$rs1, v16i32:$rs2))]>;

def VSUB : AlphamInst<(outs VPR:$rd), (ins VPR:$rs1, VPR:$rs2), 
                      "vsub $rd, $rs1, $rs2", 
                      [(set v16i32:$rd, (sub v16i32:$rs1, v16i32:$rs2))]>;

def VMUL : AlphamInst<(outs VPR:$rd), (ins VPR:$rs1, VPR:$rs2), 
                      "vmul $rd, $rs1, $rs2", 
                      [(set v16i32:$rd, (mul v16i32:$rs1, v16i32:$rs2))]>;

def VDIV : AlphamInst<(outs VPR:$rd), (ins VPR:$rs1, VPR:$rs2), 
                      "vdiv $rd, $rs1, $rs2", 
                      [(set v16i32:$rd, (sdiv v16i32:$rs1, v16i32:$rs2))]>;

// AI/ML instructions
def CONV2D : AlphamInst<(outs AIR:$rd), (ins AIR:$rs1, AIR:$rs2, AIR:$rs3), 
                        "conv2d $rd, $rs1, $rs2, $rs3", []>;

def LSTM : AlphamInst<(outs AIR:$rd), (ins AIR:$rs1, AIR:$rs2, AIR:$rs3), 
                      "lstm $rd, $rs1, $rs2, $rs3", []>;

def GRU : AlphamInst<(outs AIR:$rd), (ins AIR:$rs1, AIR:$rs2, AIR:$rs3), 
                     "gru $rd, $rs1, $rs2, $rs3", []>;

def TRANSFORMER : AlphamInst<(outs AIR:$rd), (ins AIR:$rs1, AIR:$rs2, AIR:$rs3), 
                             "transformer $rd, $rs1, $rs2, $rs3", []>;

// MIMD instructions
def SPAWN : AlphamInst<(outs MIMDR:$rd), (ins GPR:$rs1, GPR:$rs2), 
                       "spawn $rd, $rs1, $rs2", []>;

def JOIN : AlphamInst<(outs), (ins MIMDR:$rs1), 
                      "join $rs1", []>;

def BARRIER : AlphamInst<(outs), (ins MIMDR:$rs1), 
                         "barrier $rs1", []>;

def REDUCE : AlphamInst<(outs GPR:$rd), (ins GPR:$rs1, MIMDR:$rs2), 
                        "reduce $rd, $rs1, $rs2", []>;

// Security instructions
def AES_ENC : AlphamInst<(outs SECR:$rd), (ins SECR:$rs1, SECR:$rs2), 
                         "aes_enc $rd, $rs1, $rs2", []>;

def AES_DEC : AlphamInst<(outs SECR:$rd), (ins SECR:$rs1, SECR:$rs2), 
                         "aes_dec $rd, $rs1, $rs2", []>;

def SHA3 : AlphamInst<(outs SECR:$rd), (ins SECR:$rs1), 
                      "sha3 $rd, $rs1", []>;

// Scientific computing instructions
def FFT : AlphamInst<(outs SCR:$rd), (ins SCR:$rs1, SCR:$rs2), 
                     "fft $rd, $rs1, $rs2", []>;

def MATRIX_MUL : AlphamInst<(outs SCR:$rd), (ins SCR:$rs1, SCR:$rs2, SCR:$rs3), 
                            "matrix_mul $rd, $rs1, $rs2, $rs3", []>;

// Real-time instructions
def RT_SET_PRIORITY : AlphamInst<(outs), (ins RTR:$rs1, GPR:$rs2), 
                                 "rt_set_priority $rs1, $rs2", []>;

def RT_SET_DEADLINE : AlphamInst<(outs), (ins RTR:$rs1, GPR:$rs2), 
                                 "rt_set_deadline $rs1, $rs2", []>;

// Debug/profiling instructions
def PROFILE_START : AlphamInst<(outs), (ins DPR:$rs1), 
                               "profile_start $rs1", []>;

def PROFILE_STOP : AlphamInst<(outs), (ins DPR:$rs1), 
                              "profile_stop $rs1", []>;

def BREAKPOINT : AlphamInst<(outs), (ins GPR:$rs1), 
                            "breakpoint $rs1", []>;

// System instructions
def SYSCALL : AlphamInst<(outs), (ins), "syscall", []>;
def HALT : AlphamInst<(outs), (ins), "halt", []>;
def NOP : AlphamInst<(outs), (ins), "nop", []>;
