`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.07.2026 01:26:29
// Design Name: 
// Module Name: uart_rx_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module uart_rx_tb;

    parameter CLK_FREQ      = 100;
    parameter BAUD_RATE     = 10;
    parameter PARITY_ENABLE = 1;
    parameter PARITY_TYPE   = 0;

    reg        clk;
    reg        rst_n;
    reg        rx;

    wire [7:0] data_out;
    wire       rx_done;
    wire       rx_busy;
    wire       parity_error;
    wire       frame_error;

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .PARITY_ENABLE(PARITY_ENABLE),
        .PARITY_TYPE(PARITY_TYPE)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .data_out(data_out),
        .rx_done(rx_done),
        .rx_busy(rx_busy),
        .parity_error(parity_error),
        .frame_error(frame_error)
    );

    //---------------------------------------------------
    // Clock Generation
    //---------------------------------------------------
    initial
        clk = 1'b0;

    always #5 clk = ~clk;

    //---------------------------------------------------
    // Test Stimulus
    //---------------------------------------------------
    initial
    begin
        rst_n = 1'b0;
        rx    = 1'b1;

        #20;
        rst_n = 1'b1;

        #100;

        //=================================================
        // Test 1 : Correct Reception of 8'hA5
        //=================================================

        // Start bit
        rx = 1'b0;
        #100;

        // D0-D7 (A5 = 10100101, LSB first)
        rx = 1'b1; #100; // D0
        rx = 1'b0; #100; // D1
        rx = 1'b1; #100; // D2
        rx = 1'b0; #100; // D3
        rx = 1'b0; #100; // D4
        rx = 1'b1; #100; // D5
        rx = 1'b0; #100; // D6
        rx = 1'b1; #100; // D7

        // Correct even parity
        rx = 1'b0;
        #100;

        // Stop bit
        rx = 1'b1;
        #100;

        #200;

        //=================================================
        // Test 2 : Parity Error
        //=================================================

        // Start bit
        rx = 1'b0;
        #100;

        // D0-D7
        rx = 1'b1; #100;
        rx = 1'b0; #100;
        rx = 1'b1; #100;
        rx = 1'b0; #100;
        rx = 1'b0; #100;
        rx = 1'b1; #100;
        rx = 1'b0; #100;
        rx = 1'b1; #100;

        // WRONG parity bit
        rx = 1'b1;
        #100;

        // Stop bit
        rx = 1'b1;
        #100;

        #200;

        //=================================================
        // Test 3 : Frame Error
        //=================================================

        // Start bit
        rx = 1'b0;
        #100;

        // D0-D7
        rx = 1'b1; #100;
        rx = 1'b0; #100;
        rx = 1'b1; #100;
        rx = 1'b0; #100;
        rx = 1'b0; #100;
        rx = 1'b1; #100;
        rx = 1'b0; #100;
        rx = 1'b1; #100;

        // Correct parity
        rx = 1'b0;
        #100;

        // WRONG stop bit
        rx = 1'b0;
        #100;

        #200;

        $stop;
    end

endmodule