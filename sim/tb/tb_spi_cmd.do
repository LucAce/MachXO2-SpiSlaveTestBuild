set BASE_PATH "C:\Temp\MachXO2-SpiTestBuild"

cd $BASE_PATH/lib

if {![file exists rtl_verilog]} {
    vlib rtl_verilog
}
endif

design create rtl_verilog .
design open rtl_verilog
adel -all

cd $BASE_PATH/sim

vlog -dbg ../rtl/slave_efb.v
vlog -dbg ../rtl/ctrl.v
vlog -dbg ../rtl/top.v

vlog -dbg tb/tb_spi_cmd.v

vsim +access +r -L ovi_machxo2 -PL pmi_work tb_top

do waves/waves.do

run -all
