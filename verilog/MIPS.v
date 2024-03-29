//-----------------------------------------
//            Pipelined MIPS
//-----------------------------------------
module MIPS (

	input RESET,
	input CLK,

	output [31:0] data_address_2DM,//The physical memory address we want to interact with
	output MemRead_2DM,//We want to perform a read?
	output MemWrite_2DM,//We want to perform a write?

	input [31:0] data_read_fDM,//Data being read
	output [31:0] data_write_2DM,//Data being written
	//How many bytes to write:
	// 1 byte: 1
	// 2 bytes: 2
	// 3 bytes: 3
	// 4 bytes: 0
	output [1:0] data_write_size_2DM,
	input [255:0] block_read_fDM,//Data being read
	output [255:0] block_write_2DM,//Data being written
	output dBlkRead,//Request a block read
	output dBlkWrite,//Request a block write
	input block_read_fDM_valid,//Block read is successful (meets timing requirements)
	input block_write_fDM_valid,//Block write is successful
	output [31:0] Instr_address_2IM,//Instruction to fetch

	input [31:0] Instr1_fIM,//Instruction fetched at Instr_address_2IM    
	input [31:0] Instr2_fIM,//Instruction fetched at Instr_address_2IM+4 (if you want superscalar)

	input [255:0] block_read_fIM,//Cache block of instructions fetched
	input block_read_fIM_valid,//Block read is successfull
	output iBlkRead,//Request a block read

	//Tell the simulator that everything's ready to go to process a syscall.
	//Make sure that all register data is flushed to the register file, and that 
	//all data cache lines are flushed and invalidated.
	output SYS
);


//Connecting wires between IF and ID
wire [31:0] Instr1_IFID;
wire [31:0] Instr_PC_IFID;
wire [31:0] Instr_PC_Plus4_IFID;
wire        STALL_IDIF;
wire        Request_Alt_PC_IDIF;
wire [31:0] Alt_PC_IDIF;

// Input for Hazard stall mux
wire [4:0] RS_IFID;
wire [4:0] RT_IFID;
wire reg stall;  
// vaues of inputs
assign RS_IFID = {Instr1_IFID[25:21]};
assign RT_IFID = {Instr1_IFID[20:16]};

//Connecting wires between IC and IF
wire [31:0] Instr_address_2IC/*verilator public*/;
//Instr_address_2IC is verilator public so that sim_main can give accurate 
//displays.
//We could use Instr_address_2IM, but this way sim_main doesn't have to 
//worry about whether or not a cache is present.
wire [31:0] Instr1_fIC;
wire [31:0] Instr2_fIC;
assign Instr_address_2IM = Instr_address_2IC;
assign Instr1_fIC = Instr1_fIM;
assign Instr2_fIC = Instr2_fIM;
assign iBlkRead = 1'b0;
/*verilator lint_off UNUSED*/
wire [255:0] unused_i1;
wire unused_i2;
/*verilator lint_on UNUSED*/
assign unused_i1 = block_read_fIM;
assign unused_i2 = block_read_fIM_valid;
`ifdef SUPERSCALAR
`else
	/*verilator lint_off UNUSED*/
	wire [31:0] unused_i3;
	/*verilator lint_on UNUSED*/
	assign unused_i3 = Instr2_fIC;
`endif

//stall on load to detect RAW dependencies
HazardStallMux LOAD(
	.clk(CLK),
	.MemRead(MemRead1_IDEXE),
	.RS_IFID(RS_IFID),
	.RT_IFID(RS_IFID),
	.RT_IDEXE(ReadRegisterB1_OUT_IDEXE),
	.stall(stall)	
); 
assign STALL_IDIF = stall;

IF IF(
	.CLK(CLK),
	.RESET(RESET),
	.Instr1_OUT(Instr1_IFID),
	.Instr_PC_OUT(Instr_PC_IFID),
	.Instr_PC_Plus4(Instr_PC_Plus4_IFID),
	.STALL(STALL_IDIF),
	.Request_Alt_PC(Request_Alt_PC_IDIF),
	.Alt_PC(Alt_PC_IDIF),
	.Instr_address_2IM(Instr_address_2IC),
	.Instr1_fIM(Instr1_fIC)
);


wire [4:0]  WriteRegister1_MEMWB;
wire [31:0] WriteData1_MEMWB;
wire        RegWrite1_MEMWB;
wire [31:0] Instr1_IDEXE;
wire [31:0] Instr1_PC_IDEXE;
wire [31:0] OperandA1_IDEXE;
wire [31:0] OperandB1_IDEXE;
wire [4:0]  WriteRegister1_IDEXE;
wire [31:0] MemWriteData1_IDEXE;
wire        RegWrite1_IDEXE;
wire [5:0]  ALU_Control1_IDEXE;
wire        MemRead1_IDEXE;
wire        MemWrite1_IDEXE;
wire [4:0]  ShiftAmount1_IDEXE;

wire [1:0] forward_A; //this wire is the control unit for the MUX to do forwarding
wire [1:0] forward_B; //this wire is the control unit for the MUX to do forwarding

ForwardingMux A(
	//pass proper values early from the pipeline registers to ALU
	.EXEReg(WriteRegister1_EXEMEM),
	.MEMReg(WriteRegister1_MEMWB),
	.ReadReg(ReadRegisterA1_OUT_IDEXE),
	.regFileValue(OperandA1_IDEXE), 
	.MemVal(WriteData1_MEMWB), 
	.ExeVal(ALU_result1_EXEMEM), 
	.Forward(forward_A)
);

ForwardingMux B(
	.EXEReg(WriteRegister1_EXEMEM), 
    .MEMReg(WriteRegister1_MEMWB),
    .ReadReg(ReadRegisterB1_OUT_IDEXE), 
	.regFileValue(OperandB1_IDEXE), 
	.MemVal(WriteData1_MEMWB), 
	.ExeVal(ALU_result1_EXEMEM), 
	.Forward(forward_B)
);

ID ID(
	.CLK(CLK),
	.RESET(RESET),
	.ALUReg(WriteRegister1_EXEMEM),
   	.MEMReg(WriteRegister1_MEMWB),
    .ALUVal(ALU_result1_EXEMEM),
    .MEMVal(WriteData1_MEMWB),
	.Instr1_IN(Instr1_IFID),
	.Instr_PC_IN(Instr_PC_IFID),
	.Instr_PC_Plus4_IN(Instr_PC_Plus4_IFID),
	.WriteRegister1_IN(WriteRegister1_MEMWB),
	.WriteData1_IN(WriteData1_MEMWB),
	.RegWrite1_IN(RegWrite1_MEMWB),
	.Alt_PC(Alt_PC_IDIF),
	.Request_Alt_PC(Request_Alt_PC_IDIF),
	.Instr1_OUT(Instr1_IDEXE),
	.Instr1_PC_OUT(Instr1_PC_IDEXE),
	.OperandA1_OUT(OperandA1_IDEXE),
	.OperandB1_OUT(OperandB1_IDEXE),
	/* verilator lint_off PINCONNECTEMPTY */
	.ReadRegisterA1_OUT(),
	.ReadRegisterB1_OUT(),
	/* verilator lint_on PINCONNECTEMPTY */
	.WriteRegister1_OUT(WriteRegister1_IDEXE),
	.MemWriteData1_OUT(MemWriteData1_IDEXE),
	.RegWrite1_OUT(RegWrite1_IDEXE),
	.ALU_Control1_OUT(ALU_Control1_IDEXE),
	.MemRead1_OUT(MemRead1_IDEXE),
	.MemWrite1_OUT(MemWrite1_IDEXE),
	.ShiftAmount1_OUT(ShiftAmount1_IDEXE),
	.SYS(SYS),
	.WANT_FREEZE(STALL_IDIF)
);

wire [31:0] Instr1_EXEMEM;
wire [31:0] Instr1_PC_EXEMEM;
wire [31:0] ALU_result1_EXEMEM;
wire [4:0]  WriteRegister1_EXEMEM;
wire [31:0] MemWriteData1_EXEMEM;
wire        RegWrite1_EXEMEM;
wire [5:0]  ALU_Control1_EXEMEM;
wire        MemRead1_EXEMEM;
wire        MemWrite1_EXEMEM;

EXE EXE(
	.CLK(CLK),
	.RESET(RESET),
	.Instr1_IN(Instr1_IDEXE),
	.Instr1_PC_IN(Instr1_PC_IDEXE),
	.OperandA1_IN(OperandA1_IDEXE),
	.OperandB1_IN(OperandB1_IDEXE),
	.WriteRegister1_IN(WriteRegister1_IDEXE),
	.MemWriteData1_IN(MemWriteData1_IDEXE),
	.RegWrite1_IN(RegWrite1_IDEXE),
	.ALU_Control1_IN(ALU_Control1_IDEXE),
	.MemRead1_IN(MemRead1_IDEXE),
	.MemWrite1_IN(MemWrite1_IDEXE),
	.ShiftAmount1_IN(ShiftAmount1_IDEXE),
	.Instr1_OUT(Instr1_EXEMEM),
	.Instr1_PC_OUT(Instr1_PC_EXEMEM),
	.ALU_result1_OUT(ALU_result1_EXEMEM),
	.WriteRegister1_OUT(WriteRegister1_EXEMEM),
	.MemWriteData1_OUT(MemWriteData1_EXEMEM),
	.RegWrite1_OUT(RegWrite1_EXEMEM),
	.ALU_Control1_OUT(ALU_Control1_EXEMEM),
	.MemRead1_OUT(MemRead1_EXEMEM),
	.MemWrite1_OUT(MemWrite1_EXEMEM)
	//data for FTOMux in EXE module
	.dataMem(WriteData1_MEMWB),
	.forward_A(forward_A),
	.forward_B(forward_B),
);


wire [31:0] data_write_2DC/*verilator public*/;
wire [31:0] data_address_2DC/*verilator public*/;
wire [1:0]  data_write_size_2DC/*verilator public*/;
wire [31:0] data_read_fDC/*verilator public*/;
wire        read_2DC/*verilator public*/;
wire        write_2DC/*verilator public*/;
//No caches, so:
/* verilator lint_off UNUSED */
wire        flush_2DC/*verilator public*/;
/* verilator lint_on UNUSED */
wire        data_valid_fDC /*verilator public*/;
assign data_write_2DM = data_write_2DC;
assign data_address_2DM = data_address_2DC;
assign data_write_size_2DM = data_write_size_2DC;
assign data_read_fDC = data_read_fDM;
assign MemRead_2DM = read_2DC;
assign MemWrite_2DM = write_2DC;
assign data_valid_fDC = 1'b1;

assign dBlkRead = 1'b0;
assign dBlkWrite = 1'b0;
assign block_write_2DM = block_read_fDM;
/*verilator lint_off UNUSED*/
wire unused_d1;
wire unused_d2;
/*verilator lint_on UNUSED*/
assign unused_d1 = block_read_fDM_valid;
assign unused_d2 = block_write_fDM_valid;

MEM MEM(
	.CLK(CLK),
	.RESET(RESET),
	.Instr1_IN(Instr1_EXEMEM),
	.Instr1_PC_IN(Instr1_PC_EXEMEM),
	.ALU_result1_IN(ALU_result1_EXEMEM),
	.WriteRegister1_IN(WriteRegister1_EXEMEM),
	.MemWriteData1_IN(MemWriteData1_EXEMEM),
	.RegWrite1_IN(RegWrite1_EXEMEM),
	.ALU_Control1_IN(ALU_Control1_EXEMEM),
	.MemRead1_IN(MemRead1_EXEMEM),
	.MemWrite1_IN(MemWrite1_EXEMEM),
	.WriteRegister1_OUT(WriteRegister1_MEMWB),
	.RegWrite1_OUT(RegWrite1_MEMWB),
	.WriteData1_OUT(WriteData1_MEMWB),
	.data_write_2DM(data_write_2DC),
	.data_address_2DM(data_address_2DC),
	.data_write_size_2DM(data_write_size_2DC),
	.data_read_fDM(data_read_fDC),
	.MemRead_2DM(read_2DC),
	.MemWrite_2DM(write_2DC)
);
endmodule
