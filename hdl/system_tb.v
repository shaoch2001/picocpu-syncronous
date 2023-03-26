`timescale 1 ps / 1 ps

module system_tb;
    reg key = 1'b0;
	reg clk = 1;
	always #1 clk = ~clk;

	reg resetn = 0;
	initial begin
		repeat (5) @(posedge clk);
		resetn <= 1;
		repeat (5) @(posedge clk);
		
		repeat (5) @(posedge clk);
		$stop;
	end

//	wire trap;
//	wire [7:0] out_byte;
//	wire out_byte_en;

    wire led1;



	system uut (
		.clk        (clk        ),
		.resetn     (resetn     ),
		.key        (key        ),
		.led1       (led1       )

	);

//	always @(posedge clk) begin
//		if (resetn && out_byte_en) begin
//			$write("%c", out_byte);
//			$fflush;
//		end
//		if (resetn && trap) begin
//			$finish;
//		end
//	end
endmodule
