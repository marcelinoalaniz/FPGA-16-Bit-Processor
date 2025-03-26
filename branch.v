`timescale 1ns/1ns

module branch (
input        branch_eq_pi,
input        branch_ge_pi,
input        branch_le_pi,
input        branch_carry_pi,
input [15:0] reg1_data_pi,
input [15:0] reg2_data_pi,
input        alu_carry_bit_pi,

output  is_branch_taken_po)
;
wire isEQ, isLE, isGE;
wire takeEQ, takeGE, takeLE, takeC;
assign isEQ = (reg1_data_pi==reg2_data_pi)?1'b1:1'b0;
assign isGE = (reg1_data_pi>=reg2_data_pi)?1'b1:1'b0;
assign isLE = (reg1_data_pi<=reg2_data_pi)?1'b1:1'b0;

assign takeEQ = branch_eq_pi&isEQ;
assign takeGE = branch_ge_pi&isGE;
assign takeLE = branch_le_pi&isLE;
assign takeC = alu_carry_bit_pi&branch_carry_pi;

assign is_branch_taken_po = takeEQ|takeGE|takeLE|takeC;


endmodule // branch_comparator
