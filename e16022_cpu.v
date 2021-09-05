/*
Author	: D.L.C. Amarasinghe (E/16/022)
Date	: 02-June-2020
*/

`timescale 1ns/100ps

// Define module called cpu
module cpu(PC, MEMORYREAD, MEMORYWRITE, WRITEDATA, ADDRESS, INSTRUCTION, CLK, RESET, MEMREADDATA, BUSYWAIT);

    // Declare input and output ports
    output reg [31:0] PC;       // 32 bit output port declaration as PC
    output MEMORYREAD, MEMORYWRITE;
    output [7:0] WRITEDATA;
    output [7:0] ADDRESS;
    input BUSYWAIT;
    input [7:0] MEMREADDATA;
    input [31:0] INSTRUCTION;   // 32 bit input port declaration as INSTRUCTION
    input CLK, RESET;           // 1 bit input port declarations as CLK, RESET
    wire [7:0] ALURESULT;

    // Write -4 to PC, if RESET is enabled
    always @ (RESET)
    begin
        if(RESET) begin
            PC = -4;
        end
    end
 
    wire [31:0] PC_UPDATED1;

    // Instance of the module adderPC is created
    adderPC_step1 myadderPC1(PC, PC_UPDATED1);

    reg [7:0] OPCODE, DESTINATION, SOURCE1, SOURCE2;

    // Decoding an 32 bit word instruction
    always @ (INSTRUCTION)
    begin
        
        OPCODE = INSTRUCTION[31:24];
        DESTINATION = INSTRUCTION[23:16];
        SOURCE1 = INSTRUCTION[15:8];
        SOURCE2 = INSTRUCTION[7:0];

    end

    wire [7:0] OUT1, OUT2;
    wire [31:0] SIGNEXTIMMEDIATE;

    wire [7:0] TwosCompOUT2, mux1_2sCompOUTPUT, mux2_ImmediateOUTPUT;


    // Generating TwosComplement form from REGISTER 2 OUTPUT in case of 'sub' instruction
    assign #1 TwosCompOUT2 = (~OUT2 + 8'b00000001);


    // Sign extend 8 bits immediate to 32 bits
    // Reroute wires to get shift left by 2 (To get the power of 2)
    assign SIGNEXTIMMEDIATE = { {22{DESTINATION[7]}}, DESTINATION[7:0], 2'b00 };
    

    wire [31:0] PC_UPDATED2;
    // Instance of the module adderPC_step2 is created
    adderPC_step2 myadderPC2(PC_UPDATED1, SIGNEXTIMMEDIATE, PC_UPDATED2);

    reg PCSELECT;
    wire BRANCHALUSIGNAL;

    initial
    begin
        PCSELECT = 1'b0;
    end

    // PCSELECT is the signal to mux3_PC in order to decide PC value to which instruction which should be fetched
    always @ (JUMPSEL, BRANCHSEL, BRANCHALUSIGNAL, ALURESULT)
    begin 
        if (BRANCHSEL == 1'b1) begin
            PCSELECT = BRANCHALUSIGNAL && BRANCHSEL;        // For 'beq' instruction
        end else if (JUMPSEL == 1'b1) begin
            PCSELECT = 1'b1;        // For 'j' instruction
        end else begin
            PCSELECT = 1'b0;        // For 'loadi', 'mov', 'add', 'sub', 'and', 'or' instructions
        end
    end

    wire [31:0] PCOUT;

    // Instance of the module mux3_PC is created
    mux3_PC mymux3_PC(PC_UPDATED1, PC_UPDATED2, PCSELECT, PCOUT);


    // Update PC after #1 time unit only if no memory read or write operations is happening
    always @ (posedge CLK)
    if (RESET == 1'b0) begin
        #1
        if (BUSYWAIT == 1'b0) begin
            PC = PCOUT;
        end
    end


    wire [2:0] aluOP;
    wire WRITEENABLE, TWOsCOMPLSEL, IMMEDIATESEL, BRANCHSEL, JUMPSEL;


    
    assign WRITEDATA = OUT1;
    assign ADDRESS = ALURESULT;
    wire [7:0] DATAOUT;

    // Instance of the module mux4_memory is created
    mux4_memory mymux4(ALURESULT, MEMREADDATA, MEMORYREAD, DATAOUT);




    // Instance of the module control_unit is created
    control_unit mycontrol_unit(INSTRUCTION, aluOP, WRITEENABLE, TWOsCOMPLSEL, IMMEDIATESEL, BRANCHSEL, JUMPSEL, MEMORYREAD, MEMORYWRITE);

    // Instance of the module mux1_2sComp is created
    mux1_2sComp mymux1(TwosCompOUT2, OUT2, TWOsCOMPLSEL, mux1_2sCompOUTPUT);

    // Instance of the module mux2_Immediate is created
    mux2_Immediate mymux2(mux1_2sCompOUTPUT, SOURCE2[7:0], IMMEDIATESEL, mux2_ImmediateOUTPUT);

    // Instance of the module reg_file is created
    reg_file myreg_file(DATAOUT, OUT1, OUT2, DESTINATION[2:0], SOURCE1[2:0], SOURCE2[2:0], WRITEENABLE, CLK, RESET, BUSYWAIT);

    // Instance of the module alu is created
    alu myalu(OUT1, mux2_ImmediateOUTPUT, ALURESULT, BRANCHALUSIGNAL, aluOP);


endmodule

// Define module called control_unit
/*
    Generating control signals 'WRITEENABLE', 'TWOsCOMPLSEL', 'IMMEDIATESEL', 'aluOP', 'BRANCHSEL', 'JUMPSEL', 'MEMORYREAD', 'MEMORYWRITE' according to OPCODE
*/
module control_unit(INSTRUCTION, aluOP, WRITEENABLE, TWOsCOMPLSEL, IMMEDIATESEL, BRANCHSEL, JUMPSEL, MEMORYREAD, MEMORYWRITE);

    // Declare input and output ports
    input [31:0] INSTRUCTION;
    output reg [2:0] aluOP;
    output reg WRITEENABLE, TWOsCOMPLSEL, IMMEDIATESEL, BRANCHSEL, JUMPSEL, MEMORYREAD, MEMORYWRITE;

    wire [7:0] OPCODE;
    assign OPCODE = INSTRUCTION[31:24];


    // Generating control signals according to OPCODE
    always @ (INSTRUCTION)
    begin

        MEMORYREAD = 1'b0; 
        MEMORYWRITE = 1'b0;

        #1

        if (OPCODE[3:0] == 4'b0000) begin    // 'loadi' instruction operation
            WRITEENABLE = 1'b1;
            TWOsCOMPLSEL = 1'b0;
            IMMEDIATESEL = 1'b1;
            aluOP = 3'b000;
            BRANCHSEL = 1'b0;
            JUMPSEL = 1'b0;
            MEMORYREAD = 1'b0; 
            MEMORYWRITE = 1'b0;
        end else if (OPCODE[3:0] == 4'b0001) begin    // 'mov' instruction operation
            WRITEENABLE = 1'b1;
            TWOsCOMPLSEL = 1'b0;
            IMMEDIATESEL = 1'b0;
            aluOP = 3'b000;
            BRANCHSEL = 1'b0;
            JUMPSEL = 1'b0;
            MEMORYREAD = 1'b0; 
            MEMORYWRITE = 1'b0;
        end else if (OPCODE[3:0] == 4'b0010) begin    // 'add' instruction operation
            WRITEENABLE = 1'b1;
            TWOsCOMPLSEL = 1'b0;
            IMMEDIATESEL = 1'b0;
            aluOP = 3'b001;
            BRANCHSEL = 1'b0;
            JUMPSEL = 1'b0;
            MEMORYREAD = 1'b0; 
            MEMORYWRITE = 1'b0;
        end else if (OPCODE[3:0] == 4'b0011) begin    // 'sub' instruction operation
            WRITEENABLE = 1'b1;
            TWOsCOMPLSEL = 1'b1;
            IMMEDIATESEL = 1'b0;
            aluOP = 3'b001;
            BRANCHSEL = 1'b0;
            JUMPSEL = 1'b0;
            MEMORYREAD = 1'b0; 
            MEMORYWRITE = 1'b0;
        end else if (OPCODE[3:0] == 4'b0100) begin    // 'and' instruction operation
            WRITEENABLE = 1'b1;
            TWOsCOMPLSEL = 1'b0;
            IMMEDIATESEL = 1'b0;
            aluOP = 3'b010;
            BRANCHSEL = 1'b0;
            JUMPSEL = 1'b0;
            MEMORYREAD = 1'b0; 
            MEMORYWRITE = 1'b0;
        end else if (OPCODE[3:0] == 4'b0101) begin    // 'or' instruction operation
            WRITEENABLE = 1'b1;
            TWOsCOMPLSEL = 1'b0;
            IMMEDIATESEL = 1'b0;
            aluOP = 3'b011;
            BRANCHSEL = 1'b0;
            JUMPSEL = 1'b0;
            MEMORYREAD = 1'b0; 
            MEMORYWRITE = 1'b0;
        end else if (OPCODE[3:0] == 4'b0110) begin    // 'j' instruction operation
            WRITEENABLE = 1'b0;
            TWOsCOMPLSEL = 1'bx;
            IMMEDIATESEL = 1'bx;
            aluOP = 3'bx;
            BRANCHSEL = 1'b0;
            JUMPSEL = 1'b1;
            MEMORYREAD = 1'b0; 
            MEMORYWRITE = 1'b0;
        end else if (OPCODE[3:0] == 4'b0111) begin    // 'beq' instruction operation
            WRITEENABLE = 1'b0;
            TWOsCOMPLSEL = 1'b1;
            IMMEDIATESEL = 1'b0;
            aluOP = 3'b001;
            BRANCHSEL = 1'b1;
            JUMPSEL = 1'b0;
            MEMORYREAD = 1'b0; 
            MEMORYWRITE = 1'b0;
        end else if (OPCODE[3:0] == 4'b1000) begin    // Newly added 'lwd' instruction operation
            WRITEENABLE = 1'b1;
            TWOsCOMPLSEL = 1'b0;
            IMMEDIATESEL = 1'b0;
            aluOP = 3'b000;
            BRANCHSEL = 1'b0;
            JUMPSEL = 1'b0;
            MEMORYREAD = 1'b1; 
            MEMORYWRITE = 1'b0;
        end else if (OPCODE[3:0] == 4'b1001) begin    // Newly added 'lwi' instruction operation
            WRITEENABLE = 1'b1;
            TWOsCOMPLSEL = 1'b0;
            IMMEDIATESEL = 1'b1;
            aluOP = 3'b000;
            BRANCHSEL = 1'b0;
            JUMPSEL = 1'b0;
            MEMORYREAD = 1'b1; 
            MEMORYWRITE = 1'b0;
        end else if (OPCODE[3:0] == 4'b1010) begin    // Newly added 'swd' instruction operation
            WRITEENABLE = 1'b0;
            TWOsCOMPLSEL = 1'b0;
            IMMEDIATESEL = 1'b0;
            aluOP = 3'b000;
            BRANCHSEL = 1'b0;
            JUMPSEL = 1'b0;
            MEMORYREAD = 1'b0; 
            MEMORYWRITE = 1'b1;
        end else if (OPCODE[3:0] == 4'b1011) begin    // Newly added 'swi' instruction operation
            WRITEENABLE = 1'b0;
            TWOsCOMPLSEL = 1'b0;
            IMMEDIATESEL = 1'b1;
            aluOP = 3'b000;
            BRANCHSEL = 1'b0;
            JUMPSEL = 1'b0;
            MEMORYREAD = 1'b0; 
            MEMORYWRITE = 1'b1;
        end

    end

endmodule

// Define module called adderPC_step1
/*
    Update PC by 4 to fetch next instruction
*/
module adderPC_step1(PC, PC_UPDATED1);
    
    // Declare input and output ports
    input [31:0] PC;
    output reg [31:0] PC_UPDATED1;

    always @ (PC)
    begin

        #1;
        PC_UPDATED1 = PC + 32'd4;

    end
    
endmodule



// Define module called adderPC_step2
/*
    Update PC to jump to fetch desired instruction with a given Offset from current instruction (for 'j' or 'beq' instructions)
*/
module adderPC_step2(PC_UPDATED1, SIGNEXTIMMEDIATE, PC_UPDATED2);
    
    // Declare input and output ports
    input [31:0] PC_UPDATED1, SIGNEXTIMMEDIATE;
    output reg [31:0] PC_UPDATED2;
    
    always @ (SIGNEXTIMMEDIATE)
    begin
    
        PC_UPDATED2 = PC_UPDATED1 + SIGNEXTIMMEDIATE;
    
    end

endmodule



// Define module called mux4_memory
/*
    Decide what should be written in register, depending on control signal
*/
module mux4_memory(ALUDATA, MEMORYDATA, MEMORYSELECT, DATAOUT);

    // Declare input and output ports
    input [7:0] ALUDATA, MEMORYDATA;
    input MEMORYSELECT;
    output reg [7:0] DATAOUT;

    always @ (ALUDATA, MEMORYDATA, MEMORYSELECT)
    begin
        if (MEMORYSELECT == 1'b1) begin
            DATAOUT = MEMORYDATA;   // To read memory and store result in a register (For 'lwd' & 'lwi' instructions)
        end else begin
            DATAOUT = ALUDATA;      // For 'loadi', 'mov', 'add', 'sub', 'and', 'or' instructions 
        end
    end

endmodule



// Define module called mux3_PC
/*
    Decide what should be the PC, depending on type of the instruction
*/
module mux3_PC(PC1, PC2, PCSELECT, PCOUT);

    // Declare input and output ports
    input [31:0] PC1, PC2;
    input PCSELECT;
    output reg [31:0] PCOUT;

    always @ (PC1, PC2, PCSELECT)
    begin
        if (PCSELECT == 1'b1) begin
            PCOUT = PC2;        // For 'j' & 'beq' instructions
        end else begin
            PCOUT = PC1;        // For 'loadi', 'mov', 'add', 'sub', 'and', 'or' instructions
        end
    end

endmodule



// Define module called mux2_Immediate
/*
    Decide what immediate to be selected, whether it is an immediate directly from instruction (for 'loadi' instruction)
    or immediate derived from a register (for 'and', 'sub', 'and', 'or', 'mov' instructions)
*/
module mux2_Immediate(in2, in3, sel2, out2);

    // Declare input and output ports
    input [7:0] in2, in3;
    input sel2;
    output reg [7:0] out2;

    always @ (in2, in3, sel2)
    begin
        if (sel2 == 1'b1) begin
            out2 = in3;     // Set 'out2' with an immediate directly from instruction for 'loadi' instruction
        end else begin
            out2 = in2;     // Set 'out2' with an immediate derived from a register for 'and', 'sub', 'and', 'or', 'mov' instructions
        end
    end

endmodule


// Define module called mux1_2sComp
/*
    Decide whether the immediate derived from a read register2 should be converted to TwosComplement or not
*/
module mux1_2sComp(in0, in1, sel1, out1);

    // Declare input and output ports
    input [7:0] in0, in1;
    input sel1;
    output reg [7:0] out1;

    always @ (in0, in1, sel1)
    begin
        if (sel1 == 1'b1) begin
            out1 = in0;     // Set 'out1' with TwosComplement converted immediate derived from a read register2
        end else begin
            out1 = in1;     // Set 'out1' directly with the immediate derived from a read register2
        end
    end

endmodule
