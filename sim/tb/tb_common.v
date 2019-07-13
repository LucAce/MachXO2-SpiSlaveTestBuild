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
// File:  tb_top.v
// Date:  Sun Feb 24 12:00:00 EST 2019
// Title: Device Top Level Testbench
//
// Functional Description:
//
//   Common test bench functions and tasks.  This file is `included in the
//   top level tests.
//
//*****************************************************************************


    //*************************************************************************
    // Parameter Definitions
    //*************************************************************************
    parameter SPI_HALF_PERIOD = 1000;
    parameter SPI_DELAY       = 32*SPI_HALF_PERIOD;
    parameter SPI_CSN_DELAY   = 10;

    // SPI Commands
    `define SPI_CMD_PROTOCOL    8'hF0
    `define SPI_CMD_REVISION    8'hF1


    //*************************************************************************
    // Signal Definitions
    //*************************************************************************
    reg         rst_n;
    reg         sclk;
    reg         scsn;
    reg         mosi;
    wire        miso;
    wire [5:0]  debug;

    reg  [7:0]  bytetx [0:31];
    reg  [7:0]  byterx [0:31];
    reg  [7:0]  bytecount;
    reg  [7:0]  i;


    //*************************************************************************
    // DUT Instantiation
    //*************************************************************************

    // Instantiate GSR & PUR
    GSR GSR_INST (.GSR (1'b1));
    PUR PUR_INST (.PUR (1'b1));

    top dut(
        .RST_N          (rst_n       ),
        .SCLK           (sclk        ),
        .SCSN           (scsn        ),
        .MOSI           (mosi        ),
        .MISO           (miso        ),
        .DEBUG          (debug       )
    );


    //*************************************************************************
    // TB Tasks
    //*************************************************************************

    // SPI Command
    task spi_cmd;
        integer i;
        integer j;
    begin
        for (i=0; i<32; i=i+1) begin
            byterx[i] = 8'h00;
        end

        mosi = 1'b1;
        scsn = 1'b1;
        #SPI_HALF_PERIOD;
        scsn = 1'b0;
        mosi = 1'b0;

        for (i=0; i<SPI_CSN_DELAY; i=i+1) begin
            #SPI_HALF_PERIOD;
        end

        for (i=0; i<bytecount; i=i+1) begin
            for (j=0; j<8; j=j+1) begin
                sclk = 1'b0;
                mosi = bytetx[i][7-j];
                #SPI_HALF_PERIOD;
                byterx[i][7-j] = miso;
                sclk = 1'b1;
                #SPI_HALF_PERIOD;
            end
        end

        sclk = 1'b0;
        #SPI_HALF_PERIOD;
        for (i=0; i<SPI_CSN_DELAY; i=i+1) begin
            #SPI_HALF_PERIOD;
        end
        scsn = 1'b1;

        #SPI_DELAY;
        mosi = 1'b1;
    end
    endtask

    // Protocol
    // 1 Command Byte; 1 Dummy Byte; 1 Data Byte
    task cmd_protocol;
        integer i;
    begin
        for (i=0; i<32; i=i+1) begin
            bytetx[i] = 8'h00;
        end

        bytetx[0] = `SPI_CMD_PROTOCOL;
        bytecount = 3;

        spi_cmd();
        if (byterx[2] == 8'h01)
            $display("Reported Protocol: 0x%02h", byterx[2]);
        else
            $error("Error: Reported Protocol: 0x%02h", byterx[2]);
    end
    endtask

    // Revision
    // 1 Command Byte; 1 Dummy Byte; 1 Data Byte
    task cmd_revision;
        integer i;
    begin
        for (i=0; i<32; i=i+1) begin
            bytetx[i] = 8'h00;
        end

        bytetx[0] = `SPI_CMD_REVISION;
        bytecount = 3;

        spi_cmd();
        if (byterx[2] == 8'ha5)
            $display("Reported Revision: 0x%02h", byterx[2]);
        else
            $display("Error: Reported Revision: 0x%02h", byterx[2]);
    end
    endtask

    // Zero
    // 1 Command Byte; 1 Dummy Byte; 1+ Data Byte
    task cmd_zero;
        integer i;
    begin
        for (i=0; i<32; i=i+1) begin
            bytetx[i] = 8'h00;
        end

        bytetx[0] = 8'h00;
        bytecount = 10;

        spi_cmd();

        $display("Zero Command RX:");
        for (i=0; i<bytecount; i=i+1) begin
            $display("  %02d: 0x%02h", i, byterx[i]);
        end
    end
    endtask


    //*************************************************************************
    // System Reset
    //*************************************************************************
    initial begin
        scsn  = 1'b1;
        sclk  = 1'b0;
        mosi  = 1'b1;
        rst_n = 1'b0;
        #50000;
        rst_n = 1'b1;
    end
