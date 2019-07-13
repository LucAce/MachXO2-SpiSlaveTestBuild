onerror { resume }
transcript off
add wave

add wave -named_row "Top Level IO" -bold -height 32 -color 255,0,0
add wave -noreg -logic {/tb_top/dut/RST_N}
add wave -noreg -logic {/tb_top/dut/SCLK}
add wave -noreg -logic {/tb_top/dut/SCSN}
add wave -noreg -logic {/tb_top/dut/MOSI}
add wave -noreg -logic {/tb_top/dut/MISO}
add wave -noreg -hexadecimal -literal {/tb_top/dut/DEBUG}

add wave -named_row "Wishbone" -bold -height 32 -color 255,0,0
add wave -noreg -logic {/tb_top/dut/ctrl_inst/CLK}
add wave -noreg -logic {/tb_top/dut/ctrl_inst/WB_CYC_O}
add wave -noreg -logic {/tb_top/dut/ctrl_inst/WB_STB_O}
add wave -noreg -logic {/tb_top/dut/ctrl_inst/WB_WE_O}
add wave -noreg -hexadecimal -literal {/tb_top/dut/ctrl_inst/WB_ADR_O}
add wave -noreg -hexadecimal -literal {/tb_top/dut/ctrl_inst/WB_DAT_O}
add wave -noreg -hexadecimal -literal {/tb_top/dut/ctrl_inst/WB_DAT_I}
add wave -noreg -logic {/tb_top/dut/ctrl_inst/WB_ACK_I}

add wave -named_row "Ctrl" -bold -height 32 -color 255,0,0
add wave -noreg -hexadecimal -literal {/tb_top/dut/ctrl_inst/sm_state}
add wave -noreg -hexadecimal -literal {/tb_top/dut/ctrl_inst/sm_spi_cmd}
add wave -noreg -hexadecimal -literal {/tb_top/dut/ctrl_inst/sm_spi_count}
add wave -noreg -hexadecimal -literal {/tb_top/dut/ctrl_inst/PROTOCOL}
add wave -noreg -hexadecimal -literal {/tb_top/dut/ctrl_inst/REVISION}

add wave -named_row "EFB" -bold -height 32 -color 255,0,0
add wave -noreg -logic {/tb_top/dut/slave_efb_inst/EFBInst_0/SPI_TIP}
add wave -noreg -logic {/tb_top/dut/slave_efb_inst/EFBInst_0/SPI_RRDY}
add wave -noreg -logic {/tb_top/dut/slave_efb_inst/EFBInst_0/SPI_TRDY}
add wave -noreg -logic {/tb_top/dut/slave_efb_inst/EFBInst_0/SPI_MDF}
add wave -noreg -logic {/tb_top/dut/slave_efb_inst/EFBInst_0/SPI_ROE}
add wave -noreg -logic {/tb_top/dut/slave_efb_inst/EFBInst_0/SPI_WRITE}
add wave -noreg -hexadecimal -literal {/tb_top/dut/slave_efb_inst/EFBInst_0/SPIBR}
add wave -noreg -hexadecimal -literal {/tb_top/dut/slave_efb_inst/EFBInst_0/SPICR0}
add wave -noreg -hexadecimal -literal {/tb_top/dut/slave_efb_inst/EFBInst_0/SPICR1}
add wave -noreg -hexadecimal -literal {/tb_top/dut/slave_efb_inst/EFBInst_0/SPICR2}
add wave -noreg -hexadecimal -literal {/tb_top/dut/slave_efb_inst/EFBInst_0/SPICSR}
add wave -noreg -hexadecimal -literal {/tb_top/dut/slave_efb_inst/EFBInst_0/SPIRXDR}
add wave -noreg -hexadecimal -literal {/tb_top/dut/slave_efb_inst/EFBInst_0/SPISR}
add wave -noreg -hexadecimal -literal {/tb_top/dut/slave_efb_inst/EFBInst_0/SPITXDR}

cursor "Cursor 1" 0ps  
transcript on
