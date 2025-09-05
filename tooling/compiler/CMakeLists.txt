# Alpham Compiler Backend CMake Configuration
# Supports both Alpha (legacy) and Alpham (MIMD-enhanced) targets

cmake_minimum_required(VERSION 3.20)
project(AlphamCompilerBackend)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find LLVM
find_package(LLVM REQUIRED CONFIG)
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

# Include directories
include_directories(${LLVM_INCLUDE_DIRS})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Add definitions
add_definitions(${LLVM_DEFINITIONS})

# Set target architectures
set(LLVM_TARGETS_TO_BUILD "Alpha;Alpham")

# Alpha target (legacy compatibility)
add_llvm_target(Alpha
    AlphaAsmPrinter.cpp
    AlphaAsmPrinter.h
    AlphaFrameLowering.cpp
    AlphaFrameLowering.h
    AlphaISelDAGToDAG.cpp
    AlphaISelDAGToDAG.h
    AlphaISelLowering.cpp
    AlphaISelLowering.h
    AlphaInstrInfo.cpp
    AlphaInstrInfo.h
    AlphaInstrInfo.td
    AlphaMCInstLower.cpp
    AlphaMCInstLower.h
    AlphaRegisterInfo.cpp
    AlphaRegisterInfo.h
    AlphaRegisterInfo.td
    AlphaSubtarget.cpp
    AlphaSubtarget.h
    AlphaSubtarget.td
    AlphaTargetMachine.cpp
    AlphaTargetMachine.h
    AlphaTargetMachine.td
)

# Alpham target (MIMD-enhanced)
add_llvm_target(Alpham
    AlphamAsmPrinter.cpp
    AlphamAsmPrinter.h
    AlphamFrameLowering.cpp
    AlphamFrameLowering.h
    AlphamISelDAGToDAG.cpp
    AlphamISelDAGToDAG.h
    AlphamISelLowering.cpp
    AlphamISelLowering.h
    AlphamInstrInfo.cpp
    AlphamInstrInfo.h
    AlphamInstrInfo.td
    AlphamMCInstLower.cpp
    AlphamMCInstLower.h
    AlphamRegisterInfo.cpp
    AlphamRegisterInfo.h
    AlphamRegisterInfo.td
    AlphamSubtarget.cpp
    AlphamSubtarget.h
    AlphamSubtarget.td
    AlphamTargetMachine.cpp
    AlphamTargetMachine.h
    AlphamTargetMachine.td
)

# Custom optimization passes
add_llvm_library(AlphamPasses
    AlphamVectorize.cpp
    AlphamAIOptimize.cpp
    AlphamMIMDOptimize.cpp
)

# Link with LLVM libraries
target_link_libraries(AlphamPasses
    LLVMCore
    LLVMSupport
    LLVMAnalysis
    LLVMTransformUtils
    LLVMTarget
    LLVMCodeGen
)

# Installation
install(TARGETS AlphamPasses
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

# Test configuration
if(BUILD_TESTING)
    enable_testing()
    add_subdirectory(test)
endif()

# Documentation
if(BUILD_DOCS)
    add_subdirectory(docs)
endif()
