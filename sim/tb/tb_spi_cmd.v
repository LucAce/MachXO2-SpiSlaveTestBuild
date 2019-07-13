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
//   Simple top level test bench.
//
//*****************************************************************************

`timescale 1ns/100ps

module tb_top;

    `include "tb_common.v"

    reg  [7:0]  address;

    //*************************************************************************
    // Test
    //*************************************************************************
    initial begin
        // Wait for reset negation
        #100000;

        $display("***************************************************");
        $display("* Test Started");
        $display("***************************************************");

        //*********************************************************************
        // Read and verify initial register values
        //*********************************************************************

        // Protocol
        cmd_protocol();

        // Version
        cmd_revision();

        // Zero
        cmd_zero();

        $display("***************************************************");
        $display("* Test Complete");
        $display("***************************************************");
        $stop();
    end

endmodule