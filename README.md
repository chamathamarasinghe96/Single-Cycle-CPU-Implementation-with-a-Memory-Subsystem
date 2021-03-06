# Single Cycle CPU Implementation with a Memory Subsystem

## Instructions for execution

1. Compile

* ~$ iverilog -o e16022CPUwithInstCache.vvp e16022_cpu.v e16022_regfile.v e16022_alu.v cpu_testbench.v e16022_data_memory.v e16022_dcache.v e16022_instruction_memory.v e16022_instruction_cache.v

2. Run

* ~$ vvp e16022CPUwithInstCache.vvp

3. Open with gtkwave tool

* ~$ gtkwave CPUwithInstCache_wavedata.vcd

## Advisor
> Dr. Isuru Nawinne,
> Senior Lecturer,
> Department of Computer Engineering,
> Faculty of Engineering,
> University of Peradeniya.

## Links
> [Department of Computer Engineering Website](http://www.ce.pdn.ac.lk/ "http://www.ce.pdn.ac.lk/")

> [Faculty of Engineering Website](https://eng.pdn.ac.lk/ "https://eng.pdn.ac.lk/")
