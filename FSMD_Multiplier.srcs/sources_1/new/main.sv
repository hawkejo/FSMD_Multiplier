`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/30/2025 12:59:16 PM
// Design Name: 
// Module Name: main
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


module main(LED, DP, AN, SEG, SW, start, setDivisor, setDividend, upper2bytes, clk, rst,
            LED16_B, LED16_G, LED16_R, LED17_B, LED17_G, LED17_R);
    output DP;
    output [6:0] SEG;
    output [7:0] AN;
    output LED16_B, LED16_G, LED16_R, LED17_B, LED17_G, LED17_R;
    output [15:0] LED;
    input [15:0] SW;
    input start, setDivisor, setDividend, upper2bytes, clk, rst;
    
    reg [31:0] divisor, dividend;
    
    wire invRst;
    wire debStart, debDivisor, debDividend, debUpperBytes;
    wire [31:0] qOut;//, remOut;
    
    assign invRst = !rst;
    
    // Debounce the start button
    debouncer deb0 (.debBtn(debStart), .clk100MHz(clk), .btn(start), .rst(rst));
    
    // Debounce the divisor and dividend control buttons.
    debouncer deb1 (.debBtn(debDivisor), .clk100MHz(clk), .btn(setDivisor), .rst(rst));
    debouncer deb2 (.debBtn(debDividend), .clk100MHz(clk), .btn(setDividend), .rst(rst));
    debouncer deb3 (.debBtn(debUpperBytes), .clk100MHz(clk), .btn(upper2bytes), .rst(rst));
    
    // I/O logic for handling setting the divisor and dividend registers
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            divisor <= 0;
            dividend <= 0;
        end
        else if (debDivisor) begin
            if (debUpperBytes)
                divisor[31:16] <= SW;
            else
                divisor[15:0] <= SW;
        end
        else if (debDividend) begin
            if (debUpperBytes)
                dividend[31:16] <= SW;
            else
                dividend[15:0] <= SW;
        end
        else begin
            divisor <= divisor;
            dividend <= dividend;
        end
    end
    
    // Status indicator LED logic
    assign LED17_B = (dividend == 0)?1'b1:1'b0;
    assign LED17_R = ((dividend[15:0] == 0) && (dividend[31:16] != 0))?1'b1:1'b0;
    assign LED17_G = ((dividend[15:0] != 0) && (dividend[31:16] == 0))?1'b1:1'b0;
    
    assign LED16_B = (divisor == 0)?1'b1:1'b0;
    assign LED16_R = ((divisor[15:0] == 0) && (divisor[31:16] != 0))?1'b1:1'b0;
    assign LED16_G = ((divisor[15:0] != 0) && (divisor[31:16] == 0))?1'b1:1'b0;
    
    // The divider module
    fsm_multiply div0(.product({LED,qOut}),  .multiplier(divisor), .isDone(),
                 .multiplicand(dividend), .start(debStart), .clk(clk), .rst(invRst));
    
    // Display the remainder on the LEDs.  The upper 16 bits are truncated.
    //assign LED = remOut[15:0];
    
    // 7-segment display modules for displaying the quotient
    wire dispClk;
    wire [7:0] a, b, c, d, e, f, g, h;
    clockDivider redClk0(dispClk, clk, rst);
    
    sevenSegmentControl disp0(.dp(DP), .seg(SEG), .an(AN),
                .clk(dispClk), .dispUsed(8'h00), .data0(a), .data1(b), .data2(c),
                .data3(d), .data4(e), .data5(f), .data6(g), .data7(h));
    
    sevenSegmentHex disp1(.segData(a), .number(qOut[3:0]));
    sevenSegmentHex disp2(.segData(b), .number(qOut[7:4]));
    sevenSegmentHex disp3(.segData(c), .number(qOut[11:8]));
    sevenSegmentHex disp4(.segData(d), .number(qOut[15:12]));
    sevenSegmentHex disp5(.segData(e), .number(qOut[19:16]));
    sevenSegmentHex disp6(.segData(f), .number(qOut[23:20]));
    sevenSegmentHex disp7(.segData(g), .number(qOut[27:24]));
    sevenSegmentHex disp8(.segData(h), .number(qOut[31:28]));
    
endmodule