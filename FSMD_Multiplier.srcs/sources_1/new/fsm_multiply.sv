`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/30/2025 12:59:16 PM
// Design Name: 
// Module Name: fsm_multiply
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


module fsm_multiply(product, isDone, multiplier, multiplicand, start, clk, rst);
    parameter WORD_SIZE = 32;
    output reg [(2*WORD_SIZE)-1:0] product;
    output reg isDone;
    
    input [WORD_SIZE-1:0] multiplier, multiplicand;
    input start, clk, rst;      // rst is low asserted
    
    // State definitions
    localparam DONE = 2'b00;
    localparam INIT = 2'b01;
    localparam RS   = 2'b10;
    localparam SA   = 2'b11;
    
    reg [1:0] currentState, nextState;
    reg initLoad, srSig, saSig, counterDone;
    
    reg [WORD_SIZE-1:0] counter;    // SystemVerilog has some new tricks, let's see how this goes...
    wire [WORD_SIZE:0] internalSum;
    reg [WORD_SIZE-1:0] M;
    
    // Handle the multiplicand
    always_ff @ (posedge clk, negedge rst) begin
        if(~rst) begin
            M <= '0;
        end
        else begin
            if(initLoad) begin
                M <= multiplicand;
            end
        end
    end
    
    // Build the adder
    assign internalSum = product[(2*WORD_SIZE)-1:WORD_SIZE] + M;
    
    // Handle the product
    always_ff @ (posedge clk, negedge rst) begin
        if(~rst) begin
            product <= {WORD_SIZE{1'b0}};
        end
        else begin
            if(initLoad) begin
                product <= {{WORD_SIZE{1'b0}}, multiplier};
            end
            else if(srSig) begin
                product <= {1'b0, product[(2*WORD_SIZE)-1:1]};
            end
            else if(saSig) begin
                product <= {internalSum, product[WORD_SIZE-1:1]};
            end
            else begin
                product <= product;
            end
        end
    end
    
    // Counter Logic
    assign counterDone = (counter == 0)?1'b1:1'b0;
    
    always_ff @ (posedge clk, negedge rst) begin
        if(~rst)
            counter <= 0;
        else begin
            if(initLoad)
                counter <= WORD_SIZE;
            else if(counter > 0)
                counter <= counter - 1'b1;
        end
    end
    
    // Control logic
    always_comb begin
        case(nextState)
            DONE: begin
                initLoad    = 1'b0;
                srSig       = 1'b0;
                saSig       = 1'b0;
            end
            INIT: begin
                initLoad    = 1'b1;
                srSig       = 1'b0;
                saSig       = 1'b0;
            end
            RS: begin
                initLoad    = 1'b0;
                srSig       = 1'b1;
                saSig       = 1'b0;
            end
            SA: begin
                initLoad    = 1'b0;
                srSig       = 1'b0;
                saSig       = 1'b1;
            end
            default: begin
                initLoad    = 1'b0;
                srSig       = 1'b0;
                saSig       = 1'b0;
            end
        endcase
    end
    
    // Next state logic
    always_comb begin
        case(currentState)
            DONE: begin
                if(start)
                    nextState = INIT;
                else
                    nextState = DONE;
                isDone = 1'b1;
            end
            INIT: begin
                if(~start & (product[0] == 1'b0))
                    nextState = RS;
                else if(~start & (product[0] == 1'b1))
                    nextState = SA;
                else
                    nextState = INIT;
                isDone = 1'b0;
            end
            RS: begin
                if(counterDone == 1'b1)
                    nextState = DONE;
                else if((product[0] == 1'b0))
                    nextState = RS;
                else if((product[0] == 1'b1))
                    nextState = SA;
                else
                    nextState = DONE;
                isDone = 1'b0;
            end
            SA: begin
                if(counterDone == 1'b1)
                    nextState = DONE;
                else if((product[0] == 1'b0))
                    nextState = RS;
                else if((product[0] == 1'b1))
                    nextState = SA;
                else
                    nextState = DONE;
                isDone = 1'b0;
            end
            default: begin
                nextState = DONE;
                isDone = 1'b1;
            end
        endcase
    end
    
    // Handle FSM flippy boiz
    always_ff @ (posedge clk, negedge rst) begin
        if(~rst)
            currentState <= DONE;
        else
            currentState <= nextState;
    end
endmodule
