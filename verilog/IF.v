module  IF
(
	input CLK,
	input RESET,

	output reg [31:0] Instr1_OUT,//This should contain the fetched instruction
	output reg [31:0] Instr_PC_OUT,//This should contain the address of the fetched instruction [DEBUG purposes]
	output reg [31:0] Instr_PC_Plus4,//This should contain the address of the instruction after the fetched instruction (used by ID)

	input STALL,//Will be set to true if we need to just freeze the fetch stage.

	input Request_Alt_PC, //There was probably a branch -- please load the alternate PC instead of Instr_PC_Plus4.
	input [31:0] Alt_PC,//Alternate PC to load

	output [31:0] Instr_address_2IM,//Address from which we want to fetch an instruction
	input [31:0]   Instr1_fIM//Instruction received from instruction memory
);

wire [31:0] IncrementAmount;

//Since we're a multicycle datapath, we need to account for the MIPS branch delay slot
//in an unconventional way
//reg [31:0]	BranchAddress;
//reg [7:0] 	BranchRing;
//reg [4:0]   InstructionRing;

assign IncrementAmount = 32'd4; //NB: This might get modified for superscalar.
assign Instr_address_2IM = (Request_Alt_PC)?Alt_PC:Instr_PC_Plus4;

always @(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		Instr1_OUT <= 0;
		Instr_PC_OUT <= 0;
		Instr_PC_Plus4 <= 32'hBFC00000;
		$display("FETCH [RESET] Fetching @%x", Instr_PC_Plus4);
	end else if(CLK) begin
		if(!STALL) begin
			Instr1_OUT <= Instr1_fIM;
			Instr_PC_OUT <= Instr_address_2IM;
			Instr_PC_Plus4 <= Instr_address_2IM + IncrementAmount;
			$display("FETCH:Instr@%x=%x;Next@%x",Instr_address_2IM,Instr1_fIM,Instr_address_2IM + IncrementAmount);
			$display("FETCH:ReqAlt[%d]=%x",Request_Alt_PC,Alt_PC);
	
		end else begin
			$display("FETCH: Stalling; next request will be %x",Instr_address_2IM);
		end
	end
end

endmodule

