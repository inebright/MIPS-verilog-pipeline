//Forwarding Unit for Hazards
// Control Values
// Forward = 00 The first ALU operand comes from the register file.
// Forward = 10 The first ALU operand comes from the prior ALU result.
// Forward = 01 The first ALU operand comes from data memory or an early ALU result. 

module ForwardingMux(
	input [4:0] EXEReg, //destination register 1
	input [4:0] MEMReg, //destination register 2
	input [4:0] ReadReg, //current register
	input [31:0] regFileValue, // current register Value
	input [31:0] MemVal, //value to be forwarded from MEM
	input [31:0] ExeVal, //value to be forwarded from EXE
	output [1:0] forward //output signal that represents action to be taken
);

always @ (*)
	 begin
        $display("--Entered MIPS HAZARD--");
			//EX Hazard
			if (EXEReg==ReadReg && regFileValue!=ExeVal && ExeVal!=0 && EXEReg!=0) //forward from EXE to ALU
				begin
					hazardType =  2'b10;
				end
			//MEM Hazard
			else if (MEMReg==ReadReg && regFileValue!=MemVal && MemVal!=0 && MEMReg !=0) //forward from MEM to ALU
				begin
					hazardType = 2'b01;
				end
			//No hazard therefore, no need to forward
			else
				begin
					hazardType = 2'b00;
				end
	end
endmodule
