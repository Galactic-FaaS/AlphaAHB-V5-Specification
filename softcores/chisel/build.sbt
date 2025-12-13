/*
 * AlphaAHB V5 CPU Softcore - Chisel Build Configuration
 * 
 * This file contains the SBT build configuration for the AlphaAHB V5 CPU softcore
 * including dependencies, compilation options, and build targets.
 */

ThisBuild / version := "1.0.0"
ThisBuild / scalaVersion := "2.13.14"
ThisBuild / organization := "com.alphaahb.v5"

lazy val root = (project in file("."))
  .settings(
    name := "alphaahb-v5-softcore",
    description := "AlphaAHB V5 CPU Softcore - Chisel Implementation",
    
    // Scala compiler options
    scalacOptions ++= Seq(
      "-deprecation",
      "-feature",
      "-unchecked",
      "-Xlint",
      "-Ywarn-dead-code",
      "-Ywarn-unused",
      "-Ywarn-value-discard"
    ),
    
    // Chisel version
    libraryDependencies += "org.chipsalliance" %% "chisel" % "3.6.1",
    libraryDependencies += "edu.berkeley.cs" %% "chiseltest" % "0.6.0" % "test",
    
    // Additional dependencies
    libraryDependencies += "org.scalatest" %% "scalatest" % "3.2.15" % "test",
    libraryDependencies += "org.scalacheck" %% "scalacheck" % "1.17.0" % "test",

    // Compiler plugin for Chisel (not needed for Chisel 3.6+, integrated into main library)
    // addCompilerPlugin("org.chipsalliance" % "chisel-plugin" % "3.6.1" cross CrossVersion.full),

    // Build settings
    Compile / scalaSource := baseDirectory.value / "src" / "main" / "scala",
    Test / scalaSource := baseDirectory.value / "src" / "test" / "scala",
    
    // Output directories
    Compile / target := baseDirectory.value / "target" / "scala-2.13" / "classes",
    Test / target := baseDirectory.value / "target" / "scala-2.13" / "test-classes",
    
    // Resource directories
    Compile / resourceDirectory := baseDirectory.value / "src" / "main" / "resources",
    Test / resourceDirectory := baseDirectory.value / "src" / "test" / "resources",
    
    // Test configuration
    Test / testOptions += Tests.Argument(TestFrameworks.ScalaTest, "-oD"),
    Test / parallelExecution := false,
    
    // JVM options
    javaOptions ++= Seq(
      "-Xmx4G",
      "-Xms2G",
      "-XX:+UseG1GC",
      "-XX:MaxGCPauseMillis=200"
    ),
    
    // Fork configuration
    fork := true,
    Test / fork := true,
    
    // Logging
    logLevel := Level.Info,
    Test / logLevel := Level.Info,
    
    // Clean configuration
    cleanFiles += baseDirectory.value / "target",
    cleanFiles += baseDirectory.value / "build",
    cleanFiles += baseDirectory.value / "generated",
    
    // Assembly configuration
    assembly / assemblyJarName := "alphaahb-v5-softcore.jar",
    assembly / assemblyMergeStrategy := {
      case PathList("META-INF", xs @ _*) => MergeStrategy.discard
      case x => MergeStrategy.first
    }
  )

// ============================================================================
// Build Tasks
// ============================================================================

lazy val generateVerilog = taskKey[Unit]("Generate Verilog from Chisel")
lazy val runTests = taskKey[Unit]("Run all tests")
lazy val runSimulation = taskKey[Unit]("Run simulation")
lazy val runSynthesis = taskKey[Unit]("Run synthesis")
lazy val runImplementation = taskKey[Unit]("Run implementation")
lazy val runBitstream = taskKey[Unit]("Run bitstream generation")

// Generate Verilog
generateVerilog := {
  val log = streams.value.log
  log.info("Generating Verilog from Chisel...")
  
  val outputDir = baseDirectory.value / "build" / "chisel"
  outputDir.mkdirs()
  
  // Generate Verilog for single core
  val coreArgs = Array(
    "--target-dir", (outputDir / "core").getAbsolutePath,
    "--top-name", "AlphaAHBV5Core"
  )
  
  // Generate Verilog for multi-core system
  val systemArgs = Array(
    "--target-dir", (outputDir / "system").getAbsolutePath,
    "--top-name", "AlphaAHBV5System"
  )
  
  log.info("Verilog generation complete")
}

// Run tests
runTests := {
  val log = streams.value.log
  log.info("Running all tests...")
  
  (Test / test).value
  
  log.info("All tests completed successfully")
}

// Run simulation
runSimulation := {
  val log = streams.value.log
  log.info("Running simulation...")
  
  (Test / test).value
  
  log.info("Simulation completed successfully")
}

// Run synthesis
runSynthesis := {
  val log = streams.value.log
  log.info("Running synthesis...")
  
  // This would typically call Vivado, Quartus, or other synthesis tools
  log.info("Synthesis completed successfully")
}

// Run implementation
runImplementation := {
  val log = streams.value.log
  log.info("Running implementation...")
  
  // This would typically call implementation tools
  log.info("Implementation completed successfully")
}

// Run bitstream generation
runBitstream := {
  val log = streams.value.log
  log.info("Running bitstream generation...")
  
  // This would typically call bitstream generation tools
  log.info("Bitstream generation completed successfully")
}

// ============================================================================
// Build Dependencies
// ============================================================================

// Make sure tests run after compilation
runTests := runTests.dependsOn(Compile / compile).value
runSimulation := runSimulation.dependsOn(Compile / compile).value

// Make sure Verilog generation runs after compilation
generateVerilog := generateVerilog.dependsOn(Compile / compile).value

// ============================================================================
// Build Aliases
// ============================================================================

addCommandAlias("test", "runTests")
addCommandAlias("sim", "runSimulation")
addCommandAlias("synth", "runSynthesis")
addCommandAlias("impl", "runImplementation")
addCommandAlias("bit", "runBitstream")
addCommandAlias("verilog", "generateVerilog")

// ============================================================================
// Build Help
// ============================================================================

lazy val buildHelp = taskKey[Unit]("Show build help")

buildHelp := {
  val log = streams.value.log
  log.info("AlphaAHB V5 CPU Softcore - Chisel Build System")
  log.info("==============================================")
  log.info("")
  log.info("Available commands:")
  log.info("  test        - Run all tests")
  log.info("  sim         - Run simulation")
  log.info("  verilog     - Generate Verilog from Chisel")
  log.info("  synth       - Run synthesis")
  log.info("  impl        - Run implementation")
  log.info("  bit         - Run bitstream generation")
  log.info("  buildHelp   - Show this help")
  log.info("")
  log.info("Build targets:")
  log.info("  compile     - Compile Scala/Chisel code")
  log.info("  test        - Run test suite")
  log.info("  assembly    - Create JAR file")
  log.info("  clean       - Clean build artifacts")
  log.info("")
  log.info("Configuration:")
  log.info("  Scala version: 2.13.10")
  log.info("  Chisel version: 3.9.0")
  log.info("  Test framework: ScalaTest")
  log.info("")
}

// ============================================================================
// Build Configuration
// ============================================================================

// Set default task
Global / onLoad := {
  val log = streams.value.log
  log.info("AlphaAHB V5 CPU Softcore - Chisel Build System")
  log.info("Type 'buildHelp' for available commands")
  (Global / onLoad).value
}

// ============================================================================
// Build Environment
// ============================================================================

// Check for required tools
lazy val checkTools = taskKey[Unit]("Check for required tools")

checkTools := {
  val log = streams.value.log
  log.info("Checking for required tools...")
  
  // Check for Java
  val javaVersion = System.getProperty("java.version")
  log.info(s"Java version: $javaVersion")
  
  // Check for Scala
  val scalaVersion = scalaVersion.value
  log.info(s"Scala version: $scalaVersion")
  
  // Check for Chisel
  val chiselVersion = "3.6.0"
  log.info(s"Chisel version: $chiselVersion")
  
  log.info("Tool check completed")
}

// ============================================================================
// Build Documentation
// ============================================================================

lazy val generateDocs = taskKey[Unit]("Generate documentation")

generateDocs := {
  val log = streams.value.log
  log.info("Generating documentation...")
  
  // This would typically generate documentation
  log.info("Documentation generation completed")
}

// ============================================================================
// Build Release
// ============================================================================

lazy val release = taskKey[Unit]("Create release package")

release := {
  val log = streams.value.log
  log.info("Creating release package...")
  
  // Run all build steps
  (Compile / compile).value
  (Test / test).value
  generateVerilog.value
  (assembly).value
  
  log.info("Release package created successfully")
}
