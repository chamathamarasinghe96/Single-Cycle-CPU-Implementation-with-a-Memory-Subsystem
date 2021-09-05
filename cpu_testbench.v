/*
Author	: D.L.C. Amarasinghe (E/16/022)
Date	: 02-June-2020
*/

// Define module called cpu_testbench to test the programme

`timescale 1ns/100ps

module cpu_testbench;

    // Declare variables for inputs & outputs
    wire [31:0] INSTRUCTION;        // 32 bit input port declarations as INSTRUCTION
    reg CLK, RESET;                 // 1 bit input port declarations as CLK, RESET
    wire [31:0] PC;                 // 32 bit input port declarations as PC


    wire READ, WRITE;       
    wire [7:0] ADDRESS;
    wire [7:0] WRITEDATA;
    wire [7:0] CACHE_READDATA;
    wire [31:0] READDATA;
    wire BUSYWAIT;


    // Instantiate the cpu design block
    cpu e16022cpu(PC, READ, WRITE, WRITEDATA, ADDRESS, INSTRUCTION, CLK, RESET, CACHE_READDATA, BUSYWAIT);


    wire [31:0] MEM_READDATA;
    wire MEM_READ, MEM_WRITE, MEM_BUSYWAIT;
    wire [5:0] MEM_ADDRESS;
    wire [31:0] MEM_WRITEDATA;
    wire DATA_BUSYWAIT;

    // Instantiate the dcache design block
    dcache e16022_dcache(CLK, RESET, READ, WRITE, ADDRESS, WRITEDATA, MEM_BUSYWAIT, MEM_READDATA, CACHE_READDATA, MEM_READ, MEM_WRITE, DATA_BUSYWAIT, MEM_ADDRESS, MEM_WRITEDATA);
    

    // Instantiate the data_memory design block
    data_memory e16022_data_memory(CLK, RESET, MEM_READ, MEM_WRITE, MEM_ADDRESS, MEM_WRITEDATA, MEM_READDATA, MEM_BUSYWAIT);


    wire [127:0] INST_MEM_READDATA;
    wire INST_MEM_READ, INST_MEM_BUSYWAIT;
    wire [5:0] INST_MEM_ADDRESS;
    wire INST_BUSYWAIT;
    wire [9:0] INST_ADDRESS;


    // Instantiate the instcache design block
    instcache e16022_instcache(PC, CLK, RESET, INST_MEM_READDATA, INST_MEM_BUSYWAIT, INST_MEM_READ, INSTRUCTION, INST_MEM_ADDRESS, INST_BUSYWAIT);


    // Instantiate the instruction_memory design block
    instruction_memory e16022_instruction_memory(CLK, INST_MEM_READ, INST_MEM_ADDRESS, INST_MEM_READDATA, INST_MEM_BUSYWAIT);
    
    // In order to assert BUSYWAIT to stall the CPU indicating either instruction_memory or data_memory is busy
    assign BUSYWAIT = INST_BUSYWAIT || DATA_BUSYWAIT;


    integer i;

    initial
    begin

        // generate files needed to plot the waveform using GTKWave
        $dumpfile("CPUwithInstCache_wavedata.vcd");
		$dumpvars(0, cpu_testbench);


        for(i = 0; i < 8; i = i + 1) begin
            $dumpvars(0, e16022cpu.myreg_file.regset[i]);
        end


        CLK = 1'b1;
        RESET = 1'b0;

        #3
        RESET = 1'b1;

        #5
        RESET = 1'b0;
        
        // Finish simulation after some time
        #3000
        $finish;

    end
    
    // Clock signal generation
    always
        #4 CLK = ~CLK;
    

endmodule
