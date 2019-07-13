//*****************************************************************************
//
// Copyright (c) 2019 LucAce
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//
//*****************************************************************************
//
// File:  top.v
// Date:  Sun Feb 24 12:00:00 EST 2019
// Title: Device Top Level
//
// Functional Description:
//
//   Top level verilog module of the design.  It defines the IO and
//   instantiates the subcomponents.
//
// Notes:
//
//   - This design requires an active Slave Select signal.  Without it, the
//     design cannot distinquish between SPI operations.
//
//*****************************************************************************

`timescale 1ns/100ps

module top (
    input  wire         RST_N,              // Reset (Active Low)

    // SPI (On-chip hardened function)
    input  wire         SCLK,               // SPI Slave Clock
    input  wire         SCSN,               // SPI Slave Select (Active Low)
    input  wire         MOSI,               // SPI Slave Master Out Slave In
    output wire         MISO,               // SPI Slave Master In Slave Out

    // Debug Output
    output wire[5:0]    DEBUG       		// DEBUG Output Signals
);

    //*************************************************************************
    // Parameter Definitions
    //*************************************************************************
    parameter       PROTOCOL = 8'h01;       // Protocol Version
    parameter       REVISION = 8'hA5;       // Device Revision


    //*************************************************************************
    // Signal Definitions
    //*************************************************************************

    // On-chip clock
    wire            clk;

    // Active High Reset
    wire            rst;

    // Wishbone Master (Controller)
    wire            wbm_cyc_o;
    wire            wbm_stb_o;
    wire            wbm_we_o;
    wire [7:0]      wbm_adr_o;
    wire [7:0]      wbm_dat_o;
    wire [7:0]      wbm_dat_i;
    wire            wbm_ack_i;


    //*************************************************************************
    // Subcomponent Instatiations
    //*************************************************************************

    // Onboard clock resource, 38.00 MHZ
    OSCH #(
        .NOM_FREQ("2.08")
    )
    internal_oscillator_inst (
        .STDBY              (1'b0                   ),
        .OSC                (clk                    ),
		.SEDSTDBY			(					    )
    );

    // Slave EFB module
    slave_efb slave_efb_inst (
        .wb_clk_i           (clk                    ),
        .wb_rst_i           (rst                    ),
        .wb_cyc_i           (wbm_cyc_o              ),
        .wb_stb_i           (wbm_stb_o              ),
        .wb_we_i            (wbm_we_o               ),
        .wb_adr_i           (wbm_adr_o              ),
        .wb_dat_i           (wbm_dat_o              ),
        .wb_dat_o           (wbm_dat_i              ),
        .wb_ack_o           (wbm_ack_i              ),

        .spi_clk            (SCLK                   ),
        .spi_miso           (MISO                   ),
        .spi_mosi           (MOSI                   ),
        .spi_scsn           (SCSN                   )
    );

    // Controller
    ctrl #(
        .PROTOCOL           (PROTOCOL               ),
        .REVISION           (REVISION               )
    ) ctrl_inst (
        .CLK                (clk                    ),
        .RST_N              (RST_N                  ),

        .WB_CYC_O           (wbm_cyc_o              ),
        .WB_STB_O           (wbm_stb_o              ),
        .WB_WE_O            (wbm_we_o               ),
        .WB_ADR_O           (wbm_adr_o              ),
        .WB_DAT_O           (wbm_dat_o              ),
        .WB_DAT_I           (wbm_dat_i              ),
        .WB_ACK_I           (wbm_ack_i              ),

        .DEBUG              (DEBUG                  )
    );


    //*************************************************************************
    // Concurrent Logic
    //*************************************************************************

    // Invert Reset for Active High Reset blocks
    assign rst = ~RST_N;

endmodule
