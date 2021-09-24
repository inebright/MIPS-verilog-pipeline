module HazardStallMux( 
	input clk, 
	input MemRead,
	input [4:0] RT_IFID,
	input [4:0] RS_IFID,
	input [4:0] RT_IDEXE,
	output stall	
);

always @ (posedge clk) begin 
if (!stall && MemRead && ((RS_IFID==RT_IDEXE)|| (RT_IFID==RT_IDEXE))) 
begin 
		stall = 1'b1;
		$display("Stalling!!");
end 
	else
	 begin 
		stall = 1'b0;
	end 
end 

endmodule 
