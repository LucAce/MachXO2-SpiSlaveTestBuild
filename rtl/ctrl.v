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
// File:  ctrl.v
// Date:  Sun Feb 24 12:00:00 EST 2019
// Title: Main Controller
//
// Functional Description:
//
//   Device Wishbone Controller
//
// Notes:
//
//   - Writing to registers SPICR1 or SPICR2 will cause the SPI core to reset.
//     See note in table Table 18. SPI Control 1, or Table 19. SPI Control 2
//   - The Internal Wishbone Clock frequency of the EFB-SPI slave must be
//     atleast twice than the External SPI Master's clock frequency.
//
//*****************************************************************************

`timescale 1ns/100ps

module ctrl #(
    parameter           PROTOCOL = 8'hFF,   // Protocol Version
    parameter           REVISION = 8'hFF    // Device Revision
) (
    input  wire         CLK,                // Clock
    input  wire         RST_N,              // Reset (Active Low)

    output wire         WB_CYC_O,           // Wishbone Bus Cycle
    output wire         WB_STB_O,           // Wishbone Strobe
    output reg          WB_WE_O,            // Wishbone Write Enable
    output reg  [7:0]   WB_ADR_O,           // Wishbone Address
    output reg  [7:0]   WB_DAT_O,           // Wishbone Data Out
    input  wire [7:0]   WB_DAT_I,           // Wishbone Data In
    input  wire         WB_ACK_I,           // Wishbone Acknowledge

    output reg  [5:0]   DEBUG               // Debug Output Signals

);

    //*************************************************************************
    // Signal Definition
    //*************************************************************************

    // Wishbone Request Types
    `define REQ_READ                 1'b0
    `define REQ_WRITE                1'b1

    // SPI EFB Register Addresses
    `define SPICR0                   8'h54
    `define SPICR1                   8'h55
    `define SPICR2                   8'h56
    `define SPIBR                    8'h57
    `define SPICSR                   8'h58
    `define SPITXDR                  8'h59
    `define SPISR                    8'h5A
    `define SPIRXDR                  8'h5B
    `define SPIIRQ                   8'h5C
    `define SPIIRQEN                 8'h5D

    // SPI EFB Register Configuration Values
    `define SPICR1_CFG               8'h80
    `define SPICR2_CFG               8'h00
    `define SPITXDR_CFG              8'h00
    `define SPIIRQEN_CFG             8'h00

    // SPI Commands
    `define SPI_CMD_PROTOCOL         8'hF0
    `define SPI_CMD_REVISION         8'hF1

    // State Machine States
    `define S_INIT                   5'h00
    `define S_SPICR1                 5'h01
    `define S_SPICR2                 5'h02
    `define S_WAIT_FOR_TIPN          5'h03
    `define S_RXDR_DISCARD1          5'h04
    `define S_RXDR_DISCARD2          5'h05
    `define S_T1_TXDR                5'h06
    `define S_WAIT_FOR_TIP           5'h07
    `define S_T2_TRDY                5'h08
    `define S_T2_TXDR                5'h09
    `define S_R1_RRDY                5'h0A
    `define S_R1_RXDR                5'h0B
    `define S_T3_TRDY                5'h0C
    `define S_T3_TXDR                5'h0D
    `define S_RN_RRDY                5'h0E
    `define S_RN_RXDR                5'h0F
    `define S_RN_PROCESS             5'h10
    `define S_TN_TRDY                5'h11
    `define S_TN_TXDR                5'h12

    // Wishbone Cycle
    reg       wb_cyc;

    // State machine states
    reg [4:0] sm_state;

    // State machine SPI attributes
    reg [7:0] sm_spi_cmd;
    reg [7:0] sm_spi_count;

    // Immediate wishbone assignments
    // Article ID 2416 and some documentation states
    // a delay is required to avoid a race condition
    // in the simulation model
    assign #1.000 WB_STB_O = wb_cyc;
    assign #1.000 WB_CYC_O = wb_cyc;

    // Controller state machine
    always @(posedge CLK) begin
        if (RST_N == 1'b0) begin
            sm_state        <= `S_INIT;

            // Wishbone output reset values
            wb_cyc          <= 1'b0;
            WB_WE_O         <= 1'b0;
            WB_ADR_O        <= 8'h00;
            WB_DAT_O        <= 8'h00;

            // SPI Attributes reset values
            sm_spi_cmd      <= 8'h00;
            sm_spi_count    <= 8'h00;

            // Debug output reset values
            DEBUG           <= 6'h00;
        end
        else begin
            // Default signals values
            wb_cyc          <= 1'b0;
            WB_WE_O         <= `REQ_READ;

            // Set when the SPISR TIP is set
            if      ( (wb_cyc      == 1'b1) && (WB_ADR_O == `SPISR) &&
                      (WB_DAT_I[7] == 1'b1) && (WB_ACK_I == 1'b1) )
                DEBUG[5] <= 1'b1;
            // Negate when SPISR TIPN is set
            else if ( (wb_cyc      == 1'b1) && (WB_ADR_O == `SPISR) &&
                      (WB_DAT_I[7] == 1'b0) && (WB_ACK_I == 1'b1) )
                DEBUG[5] <= 1'b0;

            // Output state of FSM
            DEBUG[4:0] <= sm_state;


            //*************************************************************
            // State Machine
            //*************************************************************
            case (sm_state)

                //*************************************************************
                // State: S_INIT
                // Initialization state
                //*************************************************************
                `S_INIT: begin
                    sm_state <= `S_SPICR1;
                end

                //*************************************************************
                // State: S_SPICR1
                // Enable EFB SPI Interface
                //*************************************************************
                `S_SPICR1: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPICR1;
                    WB_DAT_O <= `SPICR1_CFG;
                    WB_WE_O  <= `REQ_WRITE;
                    sm_state <= `S_SPICR1;

                    if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_SPICR2;
                    end
                end

                //*************************************************************
                // State: S_SPICR2
                // Enable EFB SPI as a Slave
                //*************************************************************
                `S_SPICR2: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPICR2;
                    WB_DAT_O <= `SPICR2_CFG;
                    WB_WE_O  <= `REQ_WRITE;

                    if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_WAIT_FOR_TIPN;
                    end
                end

                //*************************************************************
                // State: S_WAIT_FOR_TIPN
                // Wait for Not TIP
                //*************************************************************
                `S_WAIT_FOR_TIPN: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPISR;
                    WB_WE_O  <= `REQ_READ;

                    if ( (WB_ACK_I    == 1'b1) &&
                         (WB_DAT_I[7] == 1'b0) ) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_RXDR_DISCARD1;
                    end
                    else if (WB_ACK_I == 1'b1)  begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_WAIT_FOR_TIPN;
                    end
                end

                //*************************************************************
                // State: S_RXDR_DISCARD1
                // Discard data from RXDR
                //
                // discard <= RXDR
                //*************************************************************
                `S_RXDR_DISCARD1: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPIRXDR;
                    WB_WE_O  <= `REQ_READ;

                    if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_RXDR_DISCARD2;
                    end
                end

                //*************************************************************
                // State: S_RXDR_DISCARD2
                // Discard data from RXDR
                //
                // discard <= RXDR
                //*************************************************************
                `S_RXDR_DISCARD2: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPIRXDR;
                    WB_WE_O  <= `REQ_READ;

                    if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_T1_TXDR;
                    end
                end

                //*************************************************************
                // State: S_T1_TXDR
                // Load T1 Data into TXDR
                //
                // TXDR <= T1 data
                //*************************************************************
                `S_T1_TXDR: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPITXDR;
                    WB_DAT_O <= 8'h00;
                    WB_WE_O  <= `REQ_WRITE;

                    if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_WAIT_FOR_TIP;
                    end
                end

                //*************************************************************
                // State: S_WAIT_FOR_TIP
                // Wait for TIP
                //*************************************************************
                `S_WAIT_FOR_TIP: begin
                    sm_spi_count <= 8'h00;

                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPISR;
                    WB_WE_O  <= `REQ_READ;

                    // Ready for TX byte
                    if ( (WB_ACK_I    == 1'b1) &&
                         (WB_DAT_I[7] == 1'b1) &&
                         (WB_DAT_I[4] == 1'b1) ) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_T2_TXDR;
                    end
                    // Wait for TRDY
                    else if ( (WB_ACK_I    == 1'b1) &&
                              (WB_DAT_I[7] == 1'b1) ) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_T2_TRDY;
                    end
                    // Make new Wishbone request
                    else if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_WAIT_FOR_TIP;
                    end
                end

                //*************************************************************
                // State: S_T2_TRDY
                // Wait for TRDY
                //*************************************************************
                `S_T2_TRDY: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPISR;
                    WB_WE_O  <= `REQ_READ;

                    if ( (WB_ACK_I    == 1'b1) &&
                         (WB_DAT_I[4] == 1'b1) ) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_T2_TXDR;
                    end
                    else if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_T2_TRDY;
                    end
                end

                //*************************************************************
                // State: S_T2_TXDR
                // Load T2 Data into TXDR
                //
                // TXDR <= T2 data
                //*************************************************************
                `S_T2_TXDR: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPITXDR;
                    WB_DAT_O <= 8'h00;
                    WB_WE_O  <= `REQ_WRITE;

                    if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_R1_RRDY;
                    end
                end

                //*************************************************************
                // State: S_R1_RRDY
                // Wait for RRDY following T2
                //*************************************************************
                `S_R1_RRDY: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPISR;
                    WB_WE_O  <= `REQ_READ;

                    // SPI operation complete and no pending RX data
                    if ( (WB_ACK_I    == 1'b1) &&
                         (WB_DAT_I[7] == 1'b0) &&
                         (WB_DAT_I[3] == 1'b0) ) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_SPICR2;
                    end
                    // Read ready
                    else if ( (WB_ACK_I    == 1'b1) &&
                              (WB_DAT_I[3] == 1'b1) ) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_R1_RXDR;
                    end
                    // Make new Wishbone request
                    else if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_R1_RRDY;
                    end
                end

                //*************************************************************
                // State: S_R1_RXDR
                // Read R1 Data from RXDR, R1 data is the SPI Command
                //
                // R1 data <= RXDR
                //*************************************************************
                `S_R1_RXDR: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPIRXDR;
                    WB_WE_O  <= `REQ_READ;

                    if (WB_ACK_I == 1'b1) begin
                        sm_spi_cmd <= WB_DAT_I;

                        wb_cyc     <= 1'b0;
                        WB_WE_O    <= `REQ_READ;
                        sm_state   <= `S_T3_TRDY;
                    end
                end

                //*************************************************************
                // State: S_T3_TRDY
                // Wait for TRDY
                //*************************************************************
                `S_T3_TRDY: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPISR;
                    WB_WE_O  <= `REQ_READ;

                    // SPI operation complete
                    if ( (WB_ACK_I    == 1'b1) &&
                         (WB_DAT_I[7] == 1'b0) ) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_SPICR2;
                    end
                    // SPI TX ready
                    else if ( (WB_ACK_I    == 1'b1) &&
                              (WB_DAT_I[4] == 1'b1) ) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_T3_TXDR;
                    end
                    // Make new Wishbone request
                    else if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_T3_TRDY;
                    end
                end

                //*************************************************************
                // State: S_T3_TXDR
                // Load T3 Data into TXDR
                //
                // TXDR <= T3 data
                //*************************************************************
                `S_T3_TXDR: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPITXDR;
                    WB_WE_O  <= `REQ_WRITE;

                    case (sm_spi_cmd)
                        `SPI_CMD_PROTOCOL: WB_DAT_O <= PROTOCOL;
                        `SPI_CMD_REVISION: WB_DAT_O <= REVISION;
                        default:           WB_DAT_O <= 8'h00;
                    endcase

                    if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_RN_RRDY;
                    end
                end

                //*************************************************************
                // State: S_RN_RRDY
                // Wait for R2/RN RRDY
                //*************************************************************
                `S_RN_RRDY: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPISR;
                    WB_WE_O  <= `REQ_READ;

                    // SPI complete and no pending RX data
                    if ( (WB_ACK_I    == 1'b1) &&
                         (WB_DAT_I[7] == 1'b0) &&
                         (WB_DAT_I[3] == 1'b0) ) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_SPICR2;
                    end
                    // RX Ready
                    else if ( (WB_ACK_I    == 1'b1) &&
                              (WB_DAT_I[3] == 1'b1) ) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_RN_RXDR;
                    end
                    // Make new Wishbone request
                    else if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_RN_RRDY;
                    end
                end

                //*************************************************************
                // State: S_RN_RXDR
                // Read R2/R2+ Data from RXDR
                //
                // R2 data <= RXDR
                //*************************************************************
                `S_RN_RXDR: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPIRXDR;
                    WB_WE_O  <= `REQ_READ;

                    if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_RN_PROCESS;
                    end
                end

                //*************************************************************
                // State: S_RN_PROCESS
                // Process the R2/R2+ RX Data word depending on SPI Command
                //*************************************************************
                `S_RN_PROCESS: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPISR;
                    WB_WE_O  <= `REQ_READ;
                    sm_state <= `S_TN_TRDY;

                    sm_spi_count <= sm_spi_count + 8'h01;
                end

                //*************************************************************
                // State: S_TN_TRDY
                // Wait for T2/TN TRDY
                //*************************************************************
                `S_TN_TRDY: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPISR;
                    WB_WE_O  <= `REQ_READ;

                    if ( (WB_ACK_I    == 1'b1) &&
                         (WB_DAT_I[7] == 1'b0) ) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_SPICR2;
                    end
                    else if ( (WB_ACK_I    == 1'b1) &&
                              (WB_DAT_I[4] == 1'b1) ) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_TN_TXDR;
                    end
                    // Make new Wishbone request
                    else if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_TN_TRDY;
                    end
                end

                //*************************************************************
                // State: S_TN_TXDR
                // Load TXDR register with next byte to transmit
                //*************************************************************
                `S_TN_TXDR: begin
                    wb_cyc   <= 1'b1;
                    WB_ADR_O <= `SPITXDR;
                    WB_DAT_O <= sm_spi_count;
                    WB_WE_O  <= `REQ_WRITE;

                    if (WB_ACK_I == 1'b1) begin
                        wb_cyc   <= 1'b0;
                        WB_WE_O  <= `REQ_READ;
                        sm_state <= `S_RN_RRDY;
                    end
                end

                //*************************************************************
                // State: Default
                // All other values of sm_state.
                //*************************************************************
                default: begin
                    sm_state <= `S_INIT;
                end
            endcase
        end
    end

endmodule
