`timescale 1 ps / 1 ps

module system (
	input            clk,
	input            resetn,
	input            key,
	output reg led1
);
	// set this to 0 for better timing but less performance/MHz
	parameter FAST_MEMORY = 0;

	// 4096 32bit words = 16kB memory
	parameter MEM_SIZE = 4096;

	localparam LED_BASE_ADDR = 32'h4000;

	wire mem_valid;
	wire mem_instr;
	reg mem_ready;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	reg [31:0] mem_rdata;
	wire [31:0] irq;
	wire [31:0] eoi;

    reg led1_temp;    

	wire mem_la_read;
	wire mem_la_write;
	wire [31:0] mem_la_addr;
	wire [31:0] mem_la_wdata;
	wire [3:0] mem_la_wstrb;
    assign irq[0] = 1'b0;
	assign irq[1] = 1'b0;
	assign irq[2] = 1'b0;
	assign irq[3] = key;
    assign irq[31:4]= 28'b0000000000000000000000000000;
	picorv32  #(
		.ENABLE_IRQ        (1'b1        ),
		.ENABLE_IRQ_QREGS  (1'b1        ),
		.PROGADDR_IRQ      (32'h0004    )
	) picorv32_core
	(
		.clk         (clk         ),
		.resetn      (resetn      ),
		.trap        (trap        ),
		.mem_valid   (mem_valid   ),
		.mem_instr   (mem_instr   ),
		.mem_ready   (mem_ready   ),
		.mem_addr    (mem_addr    ),
		.mem_wdata   (mem_wdata   ),
		.mem_wstrb   (mem_wstrb   ),
		.mem_rdata   (mem_rdata   ),
		.mem_la_read (mem_la_read ),
		.mem_la_write(mem_la_write),
		.mem_la_addr (mem_la_addr ),
		.mem_la_wdata(mem_la_wdata),
		.mem_la_wstrb(mem_la_wstrb),
		.irq         (irq         ),
		.eoi         (eoi         )
	);





	wire           trap;
	reg [7:0] out_byte;
	reg [0:0]      out_byte_en;
    wire [0:0]  trap_ila;
    
    assign trap_ila[0] = trap;

    ila_0 inst_ila_0 (.clk(clk), .probe0(out_byte), .probe1(trap_ila), .probe2(out_byte_en));


	reg [31:0] memory [0:MEM_SIZE-1];
	initial $readmemh("firmware.hex", memory);

	reg [31:0] m_read_data;
	reg m_read_en;

	generate if (FAST_MEMORY) begin
		always @(posedge clk) begin
			mem_ready <= 1;
			out_byte_en[0] <= 0;
			mem_rdata <= memory[mem_la_addr >> 2];
			if (mem_la_write && (mem_la_addr >> 2) < MEM_SIZE) begin
				if (mem_la_wstrb[0]) memory[mem_la_addr >> 2][ 7: 0] <= mem_la_wdata[ 7: 0];
				if (mem_la_wstrb[1]) memory[mem_la_addr >> 2][15: 8] <= mem_la_wdata[15: 8];
				if (mem_la_wstrb[2]) memory[mem_la_addr >> 2][23:16] <= mem_la_wdata[23:16];
				if (mem_la_wstrb[3]) memory[mem_la_addr >> 2][31:24] <= mem_la_wdata[31:24];
			end
			else
			if (mem_la_write && mem_la_addr == LED_BASE_ADDR) begin
				out_byte_en[0] <= 1;
				out_byte <= mem_la_wdata;
				led1_temp <=1;
			end
		end
	end else begin
		always @(posedge clk) begin
			m_read_en <= 0;
			mem_ready <= mem_valid && !mem_ready && m_read_en;

			m_read_data <= memory[mem_addr >> 2];
			mem_rdata <= m_read_data;

			out_byte_en[0] <= 0;

			(* parallel_case *)
			case (1)
				mem_valid && !mem_ready && !mem_wstrb && (mem_addr >> 2) < MEM_SIZE: begin
					m_read_en <= 1;
				end
				mem_valid && !mem_ready && |mem_wstrb && (mem_addr >> 2) < MEM_SIZE: begin
					if (mem_wstrb[0]) memory[mem_addr >> 2][ 7: 0] <= mem_wdata[ 7: 0];
					if (mem_wstrb[1]) memory[mem_addr >> 2][15: 8] <= mem_wdata[15: 8];
					if (mem_wstrb[2]) memory[mem_addr >> 2][23:16] <= mem_wdata[23:16];
					if (mem_wstrb[3]) memory[mem_addr >> 2][31:24] <= mem_wdata[31:24];
					mem_ready <= 1;
				end
				mem_valid && !mem_ready && |mem_wstrb && mem_addr == LED_BASE_ADDR: begin
					out_byte_en[0] <= 1;
					out_byte <= mem_wdata;
					mem_ready <= 1; 
					led1_temp <=1;
				end
			endcase
		end
	end endgenerate
	
	reg set_led;
	
	generate if(FAST_MEMORY) 
	   begin
	       always @(posedge clk or negedge resetn)
              begin
                  if(~resetn)
                      begin
                        set_led <= 1'b0;
                      end
                   else if(mem_la_write && mem_la_addr == LED_BASE_ADDR)
                      begin
                        set_led <= 1'b1;
                       end
            end
	   end
	else
	   begin
	   
	        always @(posedge clk or negedge resetn)
              begin
                  if(~resetn)
                      begin
                        set_led <= 1'b0;
                      end
                   else if(mem_valid && !mem_ready && |mem_wstrb && mem_addr == LED_BASE_ADDR)
                      begin
                        set_led <= 1'b1;
                       end
            end
	   end
	endgenerate

    always @(posedge clk or negedge resetn)
        begin
            if(~resetn)
                begin
                    led1 <= 1'b0;
                end
            else if(set_led)
                begin
                    led1 <= led1_temp;
                end
        end
endmodule
