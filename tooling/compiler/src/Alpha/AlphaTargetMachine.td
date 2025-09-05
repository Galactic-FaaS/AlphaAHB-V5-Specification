// Alpha Target Machine TableGen Definition
// Original Alpha target for legacy compatibility

include "llvm/Target/Target.td"

// Alpha target definition
def Alpha : Target {
  let InstructionSet = AlphaInstrInfo;
  let AssemblyParser = AlphaAsmParser;
  let AssemblyPrinter = AlphaAsmPrinter;
  let Disassembler = AlphaDisassembler;
  let InstrInfo = AlphaInstrInfo;
  let RegisterInfo = AlphaRegisterInfo;
  let Subtarget = AlphaSubtarget;
  let FrameLowering = AlphaFrameLowering;
  let SelectionDAGInfo = AlphaSelectionDAGInfo;
  let CallingConv = [CC_Alpha];
  let CodeGenRegisters = AlphaRegs;
  let CodeGenInstrs = AlphaInstrs;
  let CodeGenPseudoLowering = AlphaPseudoLowering;
}

// Alpha target machine
def AlphaTargetMachine : TargetMachine {
  let InstructionSet = AlphaInstrInfo;
  let AssemblyPrinter = AlphaAsmPrinter;
  let Disassembler = AlphaDisassembler;
  let InstrInfo = AlphaInstrInfo;
  let RegisterInfo = AlphaRegisterInfo;
  let Subtarget = AlphaSubtarget;
  let FrameLowering = AlphaFrameLowering;
  let SelectionDAGInfo = AlphaSelectionDAGInfo;
  let CallingConv = [CC_Alpha];
  let CodeGenRegisters = AlphaRegs;
  let CodeGenInstrs = AlphaInstrs;
  let CodeGenPseudoLowering = AlphaPseudoLowering;
}

// Alpha calling conventions
def CC_Alpha : CallingConv<[
  CCIfType<[i32], CCAssignToReg<[R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11, R12, R13, R14, R15, R16, R17, R18, R19, R20, R21, R22, R23, R24, R25, R26, R27, R28, R29, R30, R31]>>
]>;

// Alpha register classes
def GPR : RegisterClass<"Alpha", [i32, i64], 32, (add
  (sequence "R%u", 0, 31)
)>;

def FPR : RegisterClass<"Alpha", [f32, f64], 32, (add
  (sequence "F%u", 0, 31)
)>;

// Alpha instruction formats
class AlphaInst<dag outs, dag ins, string asmstr, list<dag> pattern>
    : Instruction {
  let OutOperandList = outs;
  let InOperandList = ins;
  let AsmString = asmstr;
  let Pattern = pattern;
}

// Alpha basic instructions
def ADD : AlphaInst<(outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2), 
                    "add $rd, $rs1, $rs2", 
                    [(set i32:$rd, (add i32:$rs1, i32:$rs2))]>;

def SUB : AlphaInst<(outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2), 
                    "sub $rd, $rs1, $rs2", 
                    [(set i32:$rd, (sub i32:$rs1, i32:$rs2))]>;

def MUL : AlphaInst<(outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2), 
                    "mul $rd, $rs1, $rs2", 
                    [(set i32:$rd, (mul i32:$rs1, i32:$rs2))]>;

def DIV : AlphaInst<(outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2), 
                    "div $rd, $rs1, $rs2", 
                    [(set i32:$rd, (sdiv i32:$rs1, i32:$rs2))]>;

// Memory instructions
def LD : AlphaInst<(outs GPR:$rd), (ins GPR:$rs1, i32:$imm), 
                   "ld $rd, $imm($rs1)", 
                   [(set i32:$rd, (load i32:$rs1))]>;

def ST : AlphaInst<(outs), (ins GPR:$rs1, GPR:$rs2, i32:$imm), 
                  "st $rs1, $imm($rs2)", 
                  [(store i32:$rs1, i32:$rs2)]>;

// Branch instructions
def BEQ : AlphaInst<(outs), (ins GPR:$rs1, GPR:$rs2, i32:$imm), 
                    "beq $rs1, $rs2, $imm", 
                    [(brcond (seteq i32:$rs1, i32:$rs2), bb:$imm))]>;

def BNE : AlphaInst<(outs), (ins GPR:$rs1, GPR:$rs2, i32:$imm), 
                    "bne $rs1, $rs2, $imm", 
                    [(brcond (setne i32:$rs1, i32:$rs2), bb:$imm))]>;

def JMP : AlphaInst<(outs), (ins GPR:$rs1), 
                    "jmp $rs1", 
                    [(br i32:$rs1)]>;

// Floating-point instructions
def FADD : AlphaInst<(outs FPR:$rd), (ins FPR:$rs1, FPR:$rs2), 
                     "fadd $rd, $rs1, $rs2", 
                     [(set f32:$rd, (fadd f32:$rs1, f32:$rs2))]>;

def FSUB : AlphaInst<(outs FPR:$rd), (ins FPR:$rs1, FPR:$rs2), 
                     "fsub $rd, $rs1, $rs2", 
                     [(set f32:$rd, (fsub f32:$rs1, f32:$rs2))]>;

def FMUL : AlphaInst<(outs FPR:$rd), (ins FPR:$rs1, FPR:$rs2), 
                     "fmul $rd, $rs1, $rs2", 
                     [(set f32:$rd, (fmul f32:$rs1, f32:$rs2))]>;

def FDIV : AlphaInst<(outs FPR:$rd), (ins FPR:$rs1, FPR:$rs2), 
                     "fdiv $rd, $rs1, $rs2", 
                     [(set f32:$rd, (fdiv f32:$rs1, f32:$rs2))]>;

// System instructions
def SYSCALL : AlphaInst<(outs), (ins), "syscall", []>;
def HALT : AlphaInst<(outs), (ins), "halt", []>;
def NOP : AlphaInst<(outs), (ins), "nop", []>;
