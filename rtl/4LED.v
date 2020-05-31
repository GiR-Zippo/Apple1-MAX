module LED_Ctrl(
	clk,
	rst_n,
	Abus,
	Data_In,
	we,
	LEDs
);  
  
input clk;  
input rst_n;  
input [15:0] Abus;//Data Input  
input [7:0] Data_In;
input we;
output [3:0] LEDs;
reg [3:0] LEDs;
reg [3:0] OldLED;

always@(negedge we)  
   begin 
		if(Abus[15:1] == 14'b11010000001100)
			OldLED[3:0] = Data_In[3:0];
   end

always@(posedge OldLED)
begin
	LEDs[0] = 1'b1;
	LEDs[3:1] = OldLED[3:1];
end



endmodule
