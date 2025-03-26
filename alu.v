`timescale 1ns/1ns

`define NOP 4'b0000
`define ARITH_2OP 4'b0001
`define ARITH_1OP 4'b0010
`define MOVI 4'b0011
`define ADDI 4'b0100
`define SUBI 4'b0101
`define LOAD 4'b0110
`define STOR 4'b0111
`define BEQ 4'b1000
`define BGE 4'b1001
`define BLE 4'b1010
`define BC 4'b1011
`define J 4'b1100
`define CONTROL 4'b1111

`define ADD 3'b000
`define ADDC 3'b001
`define SUB 3'b010
`define SUBB 3'b011
`define AND 3'b100
`define OR 3'b101
`define XOR 3'b110
`define XNOR 3'b111

`define NOT 3'b000
`define SHIFTL 3'b001
`define SHIFTR 3'b010
`define CP 3'b011

`define STC    12'b000000000001
`define STB    12'b000000000010
`define RESET  12'b101010101010
`define HALT   12'b111111111111




/*
 * Module: alu
 * Description: Arithmetic Logic Unit
 *              This unit contains the math/logical units for the processor, and is used for the following functions:
 *              - 2 Operand Arithmetic
 *                  Add, Add with Carry, Subtract, Subtract with Borrow, bitwise AND/OR/XOR/XNOR
 *              - 1 Operand Arithmetic
 *                  Bitwise NOT, Shift Left, Shift Right, Register Copy
 *              - Add immediate (no carry bit)
 *              - Subtract immediate (no borrow bit)
 *              - Load and Store (Address addition - effectively the same to the ALU as Add immediate)
 *              This module does not contain the adder for the Program Counter, nor does it have the comparator logic for branches
 */
module alu (
	input 	      arith_1op_pi,
	input 	      arith_2op_pi,
	input [2:0]   alu_func_pi,
	input 	      addi_pi,
	input 	      subi_pi,
	input 	      load_or_store_pi,
	input [15:0]  reg1_data_pi, // Register operand 1
	input [15:0]  reg2_data_pi, // Register operand 2
	input [5:0]   immediate_pi, // Immediate operand
	input 	      stc_cmd_pi, // STC instruction must set carry_out
	input 	      stb_cmd_pi, // STB instruction must set borrow_out
	input 	      carry_in_pi, // Use for ADDC
	input 	      borrow_in_pi, // Use for SUBB
	
	output [15:0] alu_result_po,// The 16-bit result disregarding carry out or borrow
	output 	      carry_out_po, // Propagate carry_in unless an arithmetic/STC instruction generates a new carry 
	output 	      borrow_out_po // Propagate borrow_in unless an arithmetic/STB instruction generates a new borrow
);
wire [16:0] addVal, addcVal, subVal, subbVal, andVal, orVal, xorVal, xnorVal, notVal, shiftLVal, shiftRVal, cpVal, addiVal, subiVal, ldstVal, fin;
wire [16:0] isAdd, isAddc, isSub, isSubb, isAnd, isOr, isXor, isXnor, isNot, isShiftL, isShiftR, isCP, arithmetic_result1, arithmetic_result2;
wire [16:0] isAddi, isSubi, isArith1, isArith2, isLDST;
wire carry;
wire borrowSub;
wire borrowSubc;
wire borrowSubi;
wire chooseBorrow;
wire ifBorrow;
// ALU Results
assign addVal = reg1_data_pi+reg2_data_pi;
assign addcVal = reg1_data_pi+reg2_data_pi+carry_in_pi;
assign subVal = reg1_data_pi-reg2_data_pi;
assign subbVal = reg1_data_pi-reg2_data_pi-borrow_in_pi;
assign andVal = reg1_data_pi&reg2_data_pi;
assign orVal = reg1_data_pi|reg2_data_pi;
assign xorVal = reg1_data_pi^reg2_data_pi;
assign xnorVal = reg1_data_pi~^reg2_data_pi;
assign notVal = ~reg1_data_pi;
assign shiftLVal = reg1_data_pi<<1;
assign shiftRVal = reg1_data_pi>>1;
assign cpVal = reg1_data_pi;
assign addiVal = reg1_data_pi+immediate_pi;
assign subiVal = reg1_data_pi-immediate_pi;
assign ldstVal = addiVal;

// Deciding which function to Use
assign isAdd = (alu_func_pi==`ADD) ? addVal: 17'b0;
assign isAddc = (alu_func_pi==`ADDC) ? addcVal: 17'b0;
assign isSub = (alu_func_pi==`SUB) ? subVal: 17'b0;
assign isSubb = (alu_func_pi==`SUBB) ? subbVal: 17'b0;
assign isAnd = (alu_func_pi==`AND) ? andVal: 17'b0;
assign isOr = (alu_func_pi==`OR) ? orVal: 17'b0;
assign isXor = (alu_func_pi==`XOR) ? xorVal: 17'b0;
assign isXnor = (alu_func_pi==`XNOR) ? xnorVal: 17'b0;
assign isNot = (alu_func_pi==`NOT) ? notVal: 17'b0;
assign isShiftL = (alu_func_pi==`SHIFTL) ? shiftLVal: 17'b0;
assign isShiftR = (alu_func_pi==`SHIFTR) ? shiftRVal: 17'b0;
assign isCP = (alu_func_pi==`CP) ? cpVal: 17'b0;

assign arithmetic_result2 = isAdd+isAddc+isSubb+isSub+isAnd+isOr+isXor+isXnor;
assign arithmetic_result1 = isNot+isShiftL+isShiftR+isCP;

// Deciding alu_result_po

assign isAddi = (addi_pi) ? addiVal: 17'b0;
assign isSubi = (subi_pi) ? subiVal: 16'b0;
assign isLDST = (load_or_store_pi) ? ldstVal: 16'b0;
assign isArith1 = (arith_1op_pi) ? arithmetic_result1: 16'b0;
assign isArith2 = (arith_2op_pi) ? arithmetic_result2: 16'b0;

assign fin = isAddi+isSubi+isArith1+isArith2+isLDST;
assign alu_result_po = fin[15:0];

assign carry = fin[16];
assign ifCarry = (addi_pi) ? 1'b1:((fin==addVal&alu_func_pi==`ADD)?1'b1: ((fin==addcVal&alu_func_pi==`ADDC)?1'b1:0));
assign carry_out_po = ((addi_pi|(|isAdd)|(|isAddc))&ifCarry) ? carry|stc_cmd_pi: carry_in_pi|stc_cmd_pi;

assign borrowSub = (reg1_data_pi < reg2_data_pi) ? 1'b1: 1'b0;
assign borrowSubb = (reg1_data_pi < reg2_data_pi+borrow_in_pi) ? 1'b1: 1'b0;
assign borrowSubi = (reg1_data_pi < immediate_pi) ? 1'b1: 1'b0;
assign chooseBorrow = (subi_pi) ? borrowSubi:((fin==subVal&alu_func_pi==`SUB)?borrowSub: ((fin==subbVal&alu_func_pi==`SUBB)?borrowSubb:0));
assign ifBorrow = (subi_pi) ? 1'b1:((fin==subVal&alu_func_pi==`SUB)?1'b1: ((fin==subbVal&alu_func_pi==`SUBB)?1'b1:0));
assign borrow_out_po = (ifBorrow) ? chooseBorrow|stb_cmd_pi: borrow_in_pi|stb_cmd_pi;



   


endmodule // alu
