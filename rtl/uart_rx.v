`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.07.2026 01:25:52
// Design Name: 
// Module Name: uart_rx
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


module uart_rx #(
    parameter CLK_FREQ      = 50_000_000,
    parameter BAUD_RATE     = 9600,
    parameter PARITY_ENABLE = 0,
    parameter PARITY_TYPE   = 0
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,

    output reg [7:0] data_out,
    output reg       rx_done,
    output reg       rx_busy,
    output reg       parity_error,
    output reg       frame_error
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    localparam IDLE   = 3'd0,
               START  = 3'd1,
               DATA   = 3'd2,
               PARITY = 3'd3,
               STOP   = 3'd4,
               DONE   = 3'd5;

    reg [2:0]  state;
    reg [2:0]  bit_counter;
    reg [7:0]  shift_reg;
    reg [12:0] baud_counter;

    always @(posedge clk)
    begin
        if (!rst_n)
        begin
            state         <= IDLE;
            bit_counter   <= 3'd0;
            baud_counter  <= 13'd0;
            shift_reg     <= 8'd0;
            data_out      <= 8'd0;
            rx_done       <= 1'b0;
            rx_busy       <= 1'b0;
            parity_error  <= 1'b0;
            frame_error   <= 1'b0;
        end
        else
        begin
            case (state)

                IDLE:
                begin
                    rx_busy      <= 1'b0;
                    rx_done      <= 1'b0;
                    baud_counter <= 13'd0;
                    bit_counter  <= 3'd0;

                    if (rx == 1'b0)
                    begin
                        rx_busy      <= 1'b1;
                        parity_error <= 1'b0;
                        frame_error  <= 1'b0;
                        state        <= START;
                    end
                end

                START:
                begin
                    if (baud_counter == (CLKS_PER_BIT/2) - 1)
                    begin
                        baud_counter <= 13'd0;

                        if (rx == 1'b0)
                        begin
                            bit_counter <= 3'd0;
                            state       <= DATA;
                        end
                        else
                        begin
                            state <= IDLE;
                        end
                    end
                    else
                    begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end

                DATA:
                begin
                    if (baud_counter == CLKS_PER_BIT - 1)
                    begin
                        baud_counter <= 13'd0;
                        shift_reg[bit_counter] <= rx;

                        if (bit_counter == 3'd7)
                        begin
                            if (PARITY_ENABLE)
                                state <= PARITY;
                            else
                                state <= STOP;
                        end
                        else
                        begin
                            bit_counter <= bit_counter + 1'b1;
                        end
                    end
                    else
                    begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end

                PARITY:
                begin
                    if (baud_counter == CLKS_PER_BIT - 1)
                    begin
                        baud_counter <= 13'd0;

                        if (rx != ((PARITY_TYPE == 0) ?
                                   (^shift_reg) :
                                   ~(^shift_reg)))
                        begin
                            parity_error <= 1'b1;
                        end

                        state <= STOP;
                    end
                    else
                    begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end

                STOP:
                begin
                    if (baud_counter == CLKS_PER_BIT - 1)
                    begin
                        baud_counter <= 13'd0;

                        if (rx != 1'b1)
                        begin
                            frame_error <= 1'b1;
                        end

                        state <= DONE;
                    end
                    else
                    begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end

                DONE:
                begin
                    data_out <= shift_reg;
                    rx_done  <= 1'b1;
                    rx_busy  <= 1'b0;
                    state    <= IDLE;
                end

                default:
                begin
                    state         <= IDLE;
                    bit_counter   <= 3'd0;
                    baud_counter  <= 13'd0;
                    rx_busy       <= 1'b0;
                    rx_done       <= 1'b0;
                end

            endcase
        end
    end

endmodule