`timescale 1ns / 1ps



module tb_uart_tx#(parameter c_clkfreq = 100_000_000,  
      parameter c_baudrate= 10_000_000,  
	  parameter c_stopbit = 2,
	  parameter gonbitsys = 10 
	)();
	

	reg clk;
	reg [gonbitsys-1:0] din_i;
	reg  tx_start_i;
	wire tx_o;
	wire tx_done_tick_o;
	
	uart_tx dut (clk, din_i, tx_start_i, tx_o, tx_done_tick_o);

	localparam real c_clk_period = 10;
	
	always begin
    #(c_clk_period/2) clk = !clk;
	end

	initial begin
	clk = 1'b1;
	din_i			= 10'b1010101010;
	tx_start_i		= 1'b0;
	#(c_clk_period*10);
	din_i		= 10'b1100110011;
	tx_start_i	= 1'b1;
	#c_clk_period;
	tx_start_i	= 1'b0;
	#1300;
	din_i			= 10'b1110001110;
	tx_start_i		= 1'b1;
	#c_clk_period;
	tx_start_i		= 1'b0;
	#1300;
	$finish;
	end


endmodule
