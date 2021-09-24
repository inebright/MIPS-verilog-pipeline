module EXE(
	input CLK,
	input RESET,
	input [31:0] Instr1_IN, //Current instruction [debug]
	input [31:0] Instr1_PC_IN,//Current instruction's PC [debug]
	input [31:0] OperandA1_IN,//Operand A (if already known)
	input [31:0] OperandB1_IN,//Operand B (if already known)
	input [4:0] WriteRegister1_IN,//Destination register
	input [31:0] MemWriteData1_IN,//Data in MemWrite1 register
	input RegWrite1_IN,//We do a register write
	input [5:0] ALU_Control1_IN,//ALU Control signal
	input MemRead1_IN,//We read from memory (passed to MEM)
	input MemWrite1_IN,//We write to memory (passed to MEM)
	input [4:0] ShiftAmount1_IN,//Shift amount (needed for shift operations)
	input [31:0] dataMem,
	input [1:0] forward_A,//forwarding signal
	input [1:0] forward_B, //forwarding signal
	output reg [31:0] Instr1_OUT,//Instruction [debug] to MEM
	output reg [31:0] Instr1_PC_OUT,//PC [debug] to MEM
	output reg [31:0] ALU_result1_OUT,//Our ALU results to MEM
	output reg [4:0] WriteRegister1_OUT,//What register gets the data (or store from) to MEM
	output reg [31:0] MemWriteData1_OUT,//Data in WriteRegister1 (if known) to MEM
	output reg RegWrite1_OUT,//Whether we will write to a register
	output reg [5:0] ALU_Control1_OUT,//ALU Control (actually used by MEM)
	output reg MemRead1_OUT,//We need to read from MEM (passed to MEM)
	output reg MemWrite1_OUT//We need to write to MEM (passed to MEM)
);


wire [31:0] A1;
wire [31:0] B1;
wire[31:0]ALU_result1;

wire comment1;
assign comment1 = 1;
assign A1 = OperandA1_IN;
assign B1 = OperandB1_IN;

reg [31:0] HI/*verilator public*/;
reg [31:0] LO/*verilator public*/;
wire [31:0] HI_new1;
wire [31:0] LO_new1;
wire [31:0] new_HI;
wire [31:0] new_LO;

assign new_HI=HI_new1;
assign new_LO=LO_new1;

FTOMUX GETA1VALUE(
	.select(forward_A),
	.in1(OperandA1_IN),
	.in2(dataMem),
	.in3(ALU_result1_OUT),
	.in4(ALU_result1_OUT),
	.out(A1)
);

FTOMUX GETB1VALUE(
	.select(forward_B),
	.in1(OperandB1_IN), //normal register
	.in2(dataMem), //data from mem
	.in3(ALU_result1_OUT), //data from ALU
	.in4(ALU_result1_OUT), //data from ALU
	.out(B1)
);

ALU ALU1(
	.aluResult(ALU_result1),
	.HI_OUT(HI_new1),
	.LO_OUT(LO_new1),
	.HI_IN(HI),
	.LO_IN(LO),
	.A(A1), 
	.B(B1), 
	.ALU_control(ALU_Control1_IN), 
	.shiftAmount(ShiftAmount1_IN), 
	.CLK(!CLK)
);


wire [31:0] MemWriteData1;

assign MemWriteData1 = MemWriteData1_IN;

always @(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		Instr1_OUT <= 0;
		Instr1_PC_OUT <= 0;
		ALU_result1_OUT <= 0;
		WriteRegister1_OUT <= 0;
		MemWriteData1_OUT <= 0;
		RegWrite1_OUT <= 0;
		ALU_Control1_OUT <= 0;
		MemRead1_OUT <= 0;
		MemWrite1_OUT <= 0;
		$display("EXE:RESET");
	end else if(CLK) begin
		HI <= new_HI;
		LO <= new_LO;
		Instr1_OUT <= Instr1_IN;
		Instr1_PC_OUT <= Instr1_PC_IN;
		ALU_result1_OUT <= ALU_result1;
		WriteRegister1_OUT <= WriteRegister1_IN;
		MemWriteData1_OUT <= MemWriteData1;
		RegWrite1_OUT <= RegWrite1_IN;
		ALU_Control1_OUT <= ALU_Control1_IN;
		MemRead1_OUT <= MemRead1_IN;
		MemWrite1_OUT <= MemWrite1_IN;
		if(comment1) begin
			$display("EXE:Instr1=%x,Instr1_PC=%x,ALU_result1=%x; Write?%d to %d",Instr1_IN,Instr1_PC_IN,ALU_result1, RegWrite1_IN, WriteRegister1_IN);
			//$display("EXE:ALU_Control1=%x; MemRead1=%d; MemWrite1=%d (Data:%x)",ALU_Control1_IN, MemRead1_IN, MemWrite1_IN, MemWriteData1);
			//$display("EXE:OpA1=%x; OpB1=%x; HI=%x; LO=%x", A1, B1, new_HI,new_LO);
		end
	end
end

endmodule
