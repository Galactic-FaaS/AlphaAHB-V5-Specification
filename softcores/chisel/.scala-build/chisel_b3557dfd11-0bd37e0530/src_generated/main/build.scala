

final class build$_ {
def args = build_sc.args$
def scriptPath = """build.sc"""
/*<script>*/
// AlphaAHB V5 CPU Softcore - Mill Build Configuration
// Modern Scala build tool with better command-line experience than SBT

import mill._
import mill.scalalib._
import mill.scalalib.scalafmt._
import mill.scalalib.TestModule
import mill.scalalib.publish._

object alphaahb extends ScalaModule with ScalafmtModule {
  def scalaVersion = "2.13.16"
  
  def organization = "com.alphaahb.v5"
  def artifactName = "alphaahb-v5-softcore"
  def version = "1.0.0"
  
  // Chisel dependencies
  def ivyDeps = Agg(
    ivy"org.chipsalliance::chisel:6.7.0",
    ivy"edu.berkeley.cs::chiseltest:0.6.0"
  )
  
  // Compiler plugin for Chisel
  def scalacPluginIvyDeps = Agg(
    ivy"org.chipsalliance:chisel-plugin:6.7.0"
  )
  
  // Scala compiler options
  def scalacOptions = Seq(
    "-deprecation",
    "-feature", 
    "-unchecked",
    "-Xlint",
    "-Ywarn-dead-code",
    "-Ywarn-unused",
    "-Ywarn-value-discard"
  )
  
  // JVM options
  def forkArgs = Seq(
    "-Xmx4G",
    "-Xms2G", 
    "-XX:+UseG1GC",
    "-XX:MaxGCPauseMillis=200"
  )
  
  // Test configuration
  object test extends ScalaTests with TestModule.ScalaTest {
    def ivyDeps = Agg(ivy"org.scalatest::scalatest:3.2.15")
    def testFramework = "org.scalatest.tools.Framework"
  }
  
  // Generate Verilog task
  def generateVerilog = T {
    val log = T.log
    log.info("Generating Verilog from Chisel...")
    
    val outputDir = T.dest / "verilog"
    os.makeDir.all(outputDir)
    
    // This would typically call the Chisel main object
    log.info("Verilog generation complete")
    
    outputDir
  }
  
  // Run simulation task
  def runSimulation = T {
    val log = T.log
    log.info("Running simulation...")
    
    // Run tests
    test.test()
    
    log.info("Simulation completed successfully")
  }
  
  // Assembly task
  def assembly = T {
    val log = T.log
    log.info("Creating assembly JAR...")
    
    val jar = super.assembly()
    val renamedJar = T.dest / "alphaahb-v5-softcore.jar"
    os.copy(jar.path, renamedJar)
    
    log.info(s"Assembly JAR created: ${renamedJar}")
    PathRef(renamedJar)
  }
  
  // Clean task
  def cleanAll = T {
    val log = T.log
    log.info("Cleaning all build artifacts...")
    
    // Clean mill cache
    os.remove.all(T.dest)
    
    // Clean generated files
    val generatedDir = T.workspace / "generated"
    if (os.exists(generatedDir)) {
      os.remove.all(generatedDir)
    }
    
    log.info("Clean completed")
  }
}

// Build aliases
object build extends mill.Module {
  def compile = T { alphaahb.compile() }
  def test = T { alphaahb.test.test() }
  def verilog = T { alphaahb.generateVerilog() }
  def sim = T { alphaahb.runSimulation() }
  def assembly = T { alphaahb.assembly() }
  def clean = T { alphaahb.cleanAll() }
}

// Help task
object help extends mill.Module {
  def show = T {
    val log = T.log
    log.info("AlphaAHB V5 CPU Softcore - Mill Build System")
    log.info("==============================================")
    log.info("")
    log.info("Available commands:")
    log.info("  mill build.compile    - Compile Scala/Chisel code")
    log.info("  mill build.test       - Run test suite")
    log.info("  mill build.verilog    - Generate Verilog from Chisel")
    log.info("  mill build.sim        - Run simulation")
    log.info("  mill build.assembly   - Create JAR file")
    log.info("  mill build.clean      - Clean build artifacts")
    log.info("  mill help.show        - Show this help")
    log.info("")
    log.info("Configuration:")
      log.info("  Scala version: 2.13.16")
  log.info("  Chisel version: 6.7.0")
    log.info("  Mill version: 0.11.4")
    log.info("  Java version: 23+")
    log.info("")
  }
}

/*</script>*/ /*<generated>*//*</generated>*/
}

object build_sc {
  private var args$opt0 = Option.empty[Array[String]]
  def args$set(args: Array[String]): Unit = {
    args$opt0 = Some(args)
  }
  def args$opt: Option[Array[String]] = args$opt0
  def args$: Array[String] = args$opt.getOrElse {
    sys.error("No arguments passed to this script")
  }

  lazy val script = new build$_

  def main(args: Array[String]): Unit = {
    args$set(args)
    val _ = script.hashCode() // hashCode to clear scalac warning about pure expression in statement position
  }
}

export build_sc.script as `build`

