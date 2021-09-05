/*
Author	: D.L.C. Amarasinghe (E/16/022)
Date	: 02-June-2020
*/

`timescale 1ns/100ps

// Define module called reg_file
module reg_file(IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET, BUSYWAIT);
    
    // Declare input and output ports
    input [2:0] OUT1ADDRESS, OUT2ADDRESS;
    input [2:0] INADDRESS;
    input [7:0] IN;
    input BUSYWAIT;
    input WRITE, CLK, RESET;
    output [7:0] OUT1, OUT2;

    assign #2 OUT1 = regset[OUT1ADDRESS];   /* Retrieving values stored in register referred by OUT1ADDRESS and load value to OUT1. Register read delay is #2 */
    assign #2 OUT2 = regset[OUT2ADDRESS];   /* Retrieving values stored in register referred by OUT2ADDRESS and load value to OUT2. Register read delay is #2 */
    
    // Register set of 8 registers with 8 bits each
    reg [7:0] regset [7:0];

    always @ (RESET)
    begin
        if (RESET == 1'b1) begin           
            #2;     // reg reset delay
            
            // Reset all register values to zero
            regset[0] <= 8'b0;
            regset[1] <= 8'b0;
            regset[2] <= 8'b0;
            regset[3] <= 8'b0;
            regset[4] <= 8'b0;
            regset[5] <= 8'b0;
            regset[6] <= 8'b0;
            regset[7] <= 8'b0;
            
        end
    end

    // Checking for availability of rising edge of CLOCK
    always @ (posedge CLK)
    begin
        #1;         // Register write delay 
        if (WRITE == 1'b1 && !BUSYWAIT) begin
   
            regset[INADDRESS] <= IN;    /* Write data, present in IN port to the input register specified by the INADDRESS */
 
        end
    end

endmodule