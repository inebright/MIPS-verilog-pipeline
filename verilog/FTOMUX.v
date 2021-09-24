//simple 4-to-1 MUX
module FTOMUX (select, in1, in2, in3, in4, out);

input[1:0] select;
input [31:0] in1;
input [31:0] in2;
input [31:0] in3;
input [31:0] in4;
output [31:0] out;

always @ (*)
	begin
		if (select==2'b00)
			begin
				out = in1;
			end

		else if (select==2'b01)
			begin
				out = in2;
			end

		else if (select==2'b10)
			begin
				out = in3;
			end
		else  //(select==2'b11)
			begin
				out = in4;
			end
	end //begin
endmodule
