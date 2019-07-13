# MachXO2-SpiSlaveTestBuild
Lattice MachXO2 Hardened SPI Slave Test Build

# File Description and Instructions

## Diamond Project:

```
./prj/top/top.ldf       : Top level Lattice Diamond project file
./syn/top.lpf           : Design IO constraints/locations
```

## Design:
```
./rtl/
  -> ctrl.v             : Wishbone and SPI Command controller
  -> slave_efb.v        : EBF SPI Slave instance
  -> top.v              : Top level
```

## Test Bench:
```
./sim/
  -> tb/
    -> tb_common.v      : Common testbench tasks and functions, this file is `included
    -> tb_spi_cmd.v     : Test specific operations
    -> tb_spi_cmd.do    : Active HDL do file to compile and launch simulation
  -> waves/
    -> aliases.xml      : Active HDL signal group aliases
    -> waves.do         : Active HDL do file to configure a waveform
```

### Launch Simulation Using Active-HDL:

1.  Change the BASE_PATH attribute in the tb_spi_cmd.do file to the location of the files
2.  Launch Active HDL
3.  Execute .do macro to compile and run the test

```
    Tools -> Execute macro...

        Navigate to the [BASE_PATH]/sim/tb/tb_spi_cmd.do
        Select file and Click -> "Open"
```
