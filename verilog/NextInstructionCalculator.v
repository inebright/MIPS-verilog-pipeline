module NextInstructionCalculator(
	input [31:0] Instr_PC_Plus4,/* PC of the current instruction + 4*/
	input [31:0] Instruction,/* The bits of the instruction (needed to extract the jump destination)*/
	input Jump,/* Whether this instruction is a jump */
	input JumpRegister,/* Whether this is a jump register instruction */
	input [31:0] RegisterValue,/* If this is a jump register instruction, the value of the register (jump destination)*/
	output [31:0] NextInstructionAddress,/* Where we need to jump to */
	input [4:0] Register/* The register for the jr/jalr (used for debugging Jump Register) */
);

/* A version of the immediate suitable for feeding to 32bit addition*/
wire [31:0] signExtended_shifted_immediate;
/* Where the jump would go (if this were a jump) */
wire [31:0] jumpDestination_immediate;
/* Where the branch would go (if this were a branch) */
wire [31:0] branchDestination_immediate;


wire [15:0] immediate;
assign immediate = Instruction[15:0];

assign signExtended_shifted_immediate = {{14{immediate[15]}},immediate,2'b00};

assign jumpDestination_immediate = {Instr_PC_Plus4[31:28],Instruction[25:0],2'b00};
assign branchDestination_immediate = Instr_PC_Plus4 + signExtended_shifted_immediate;

assign NextInstructionAddress = Jump?(JumpRegister?RegisterValue:jumpDestination_immediate):branchDestination_immediate;
always @(Jump or JumpRegister or RegisterValue or Instr_PC_Plus4 or Instruction) begin
	if(Jump) begin
		/* Uncomment the line below */
		$display("Jump Analysis:jr=%d[%d]=%x; jd_imm=%x; branchd=%x => %x",JumpRegister, Register, RegisterValue, jumpDestination_immediate, branchDestination_immediate, NextInstructionAddress);
	end
end


endmodule
