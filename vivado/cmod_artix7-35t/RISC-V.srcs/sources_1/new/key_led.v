


module key_led(
	               input clk,
	               input resetn,
	               input wire key,
	               output reg led1 );
	              
	            
	  
	              
	               //led
	               always @(posedge clk )
	               begin
	                   if(!key)begin
	                    led1 <=0;
	                   end             
	                   else if(key) begin
	                    led1 <=1;
	                   end    
	               end
endmodule