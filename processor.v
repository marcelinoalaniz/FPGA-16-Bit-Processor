`timescale 1ns/1ns

/*
 * Module: processor
 * Description: The top module of this lab 
 */
module processor (
	input 	     CLK,
	input [7:0]  SW,
	input [3:0]  BTN,
	output [7:0] LED, 
	output [6:0] SEG,
	output 	     DP,
	output [3:0] AN
); 

   assign DP = 1'b1;  // Permanently switched off
   
   wire  cpu_clk_en; // Output signal from clock division module 
   wire  display_clk_en; // Output signal from clock division module
   wire [15:0] display_num;  // Input to 7-segment display


   // Add the input-output ports of each module instantiated below
   
// Declare wires to interconnect the ports of the modules to implement the processor
	wire [15:0] pc, instr, reg1_data, reg2_data, regD_data, alu_result, read_data;
	wire [5:0] alu_immediate;
	wire [7:0] reg_immediate;
	wire [11:0] dec_immediate;
	wire [2:0] alu_func, dest_reg, source_reg1, source_reg2;
	wire arith_2op, arith_1op, movi_lower, movi_higher, addi, subi, load_wire, store_wire, branch_eq;
	wire branch_ge, branch_le, branch_carry, jump, stc_cmd, stb_cmd, halt_cmd, rst_cmd;
	wire current_carry, current_borrow, new_carry, new_borrow, is_branch_taken;
    wire       reset, clock_enable;
   
   // Write an "assign" statement for the "reset" signal
   // Write an "assign" statement for the  "clock_enable" signal
    assign reset = BTN[0] | rst_cmd;
	assign clock_enable = cpu_clk_en & ~halt_cmd;
	assign reg_immediate = dec_immediate[7:0];
	assign alu_immediate = dec_immediate[5:0];
   // Add the input-output ports of each module instantiated below

decoder myDecoder(
	.instruction_pi(instr),
	.alu_func_po(alu_func),
	.destination_reg_po(dest_reg),
	.source_reg1_po(source_reg1),
	.source_reg2_po(source_reg2),
	.immediate_po(dec_immediate),
	.arith_2op_po(arith_2op),
	.arith_1op_po(arith_1op),
	.movi_lower_po(movi_lower),
	.movi_higher_po(movi_higher),
	.addi_po(addi),
	.subi_po(subi),
	.load_po(load_wire),
	.store_po(store_wire),
	.branch_eq_po(branch_eq),
	.branch_ge_po(branch_ge),
	.branch_le_po(branch_le),
	.branch_carry_po(branch_carry),
	.jump_po(jump),
	.stc_cmd_po(stc_cmd),
	.stb_cmd_po(stb_cmd),
	.halt_cmd_po(halt_cmd),
	.rst_cmd_po(rst_cmd)

); 

alu  myALU(
	.arith_1op_pi(arith_1op),
    .arith_2op_pi(arith_2op),
    .alu_func_pi(alu_func),
    .addi_pi(addi),
    .subi_pi(subi),
    .load_or_store_pi(load_wire|store_wire),
    .reg1_data_pi(reg1_data),
    .reg2_data_pi(reg2_data),
    .immediate_pi(alu_immediate),
    .stc_cmd_pi(stc_cmd),
    .stb_cmd_pi(stb_cmd),
    .carry_in_pi(current_carry),
    .borrow_in_pi(current_borrow),
        
    .alu_result_po(alu_result),
    .carry_out_po(new_carry),
    .borrow_out_po(new_borrow)
);

branch  myBranch( 
	.branch_eq_pi(branch_eq),
	.branch_ge_pi(branch_ge),
	.branch_le_pi(branch_le),
	.branch_carry_pi(branch_carry),
	.reg1_data_pi(reg1_data),
	.reg2_data_pi(reg2_data),
	.alu_carry_bit_pi(new_carry),
	
	.is_branch_taken_po(is_branch_taken)
);

regfile   myRegfile(
	.clk_pi(CLK),
    .clk_en_pi(clock_enable),
    .reset_pi(reset),

    .source_reg1_pi(source_reg1),
    .source_reg2_pi(source_reg2),

    .destination_reg_pi(dest_reg),
    .dest_result_data_pi(load_wire ? read_data: alu_result),
    .wr_destination_reg_pi(arith_1op | arith_2op | movi_lower | movi_higher | addi | subi | load_wire|st),

    .movi_lower_pi(movi_lower),
    .movi_higher_pi(movi_higher),
    .immediate_pi(reg_immediate),

    .new_carry_pi(new_carry),
    .new_borrow_pi(new_borrow),

    .reg1_data_po(reg1_data),
    .reg2_data_po(reg2_data),

    .current_carry_po(current_carry),
    .current_borrow_po(current_borrow),

    .regD_data_po(regD_data)
);

program_counter myProgram_counter(
	
	.clk_pi(CLK),
	.clk_en_pi(clock_enable),
	.reset_pi(reset),
	.branch_taken_pi(is_branch_taken),
	.branch_immediate_pi(alu_immediate),
	.jump_taken_pi(jump),
	.jump_immediate_pi(dec_immediate),
	.pc_po(pc)
);

			  
instruction_mem myInstruction_mem(
	.pc_pi(pc),
	.instruction_po(instr)
);

data_mem  myData_mem(
	.clk_pi(CLK),
	.clk_en_pi(clock_enable),
	.reset_pi(reset),
	.write_pi(store_wire),
	.wdata_pi(regD_data),
	.addr_pi(alu_result),
	.rdata_po(read_data),
	.display_num_po(display_num)
);
  





   
   
// Clock modules
display_clkdiv  Idisplay_clkdiv (
.clk_pi(CLK),
.clk_en_po(display_clk_en)
);


display_clkdiv  #(.SIZE(12)) Icpu_clkdiv (
.clk_pi(CLK),
.clk_en_po(cpu_clk_en)
);


// Display module
sevenSegDisplay IsevenSegDisplay(
.clk_pi(CLK),
.clk_en_pi(display_clk_en),
.num_pi(display_num),
.seg_po(SEG),
.an_po(AN)
);

endmodule 



