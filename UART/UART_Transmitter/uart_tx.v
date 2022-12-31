`timescale 1ns / 1ps


module uart_tx 
	#(parameter c_clkfreq = 100_000_000,  
      parameter c_baudrate= 10_000_000,  
	  parameter c_stopbit = 2,
	  parameter gonbitsys = 10       // Gönderilecek bit sayısı
	)  											
    (input clk,												
	 input [gonbitsys-1:0] din_i,
	 input  tx_start_i,             // Veriyi gönder komutu
	 output reg tx_o,
	 output reg tx_done_tick_o      // Veri gönderim durumu (tamamlandı/tamamlanmadı)
    );
	
	localparam c_bittimerlim = c_clkfreq/c_baudrate;
	localparam c_stopbitlim = (c_clkfreq/c_baudrate)*c_stopbit;
	localparam S_IDLE = 2'b00, S_START = 2'b01, S_DATA = 2'b10, S_STOP = 2'b11;
	
	reg [5:0] bittimer = 0;
	reg [5:0] bitcntr = 0;
	reg [gonbitsys-1:0] shreg = 8'b0;
	reg [1:0] state;


always @(posedge clk) begin

	case (state)
	
        S_IDLE : begin
			tx_o			<= 1'b1;
			tx_done_tick_o	<= 1'b0;
			bitcntr			<=  0 ;			
			if (tx_start_i == 1'b1) begin
				state	<= S_START;
				tx_o	<= 1'b0;
				shreg	<= din_i;
			end
		end	
		
		S_START : begin	
			if (bittimer == c_bittimerlim-1) begin
				state				<= S_DATA;
				tx_o				<= shreg[0];
				shreg[gonbitsys-1]			<= shreg[0];
				shreg[gonbitsys-2:0]	<= shreg[gonbitsys-1:1];
				bittimer			<= 0;
			end	
			else begin
				bittimer			<= bittimer + 1;
			end 
		end
		
		S_DATA : begin	
			if (bitcntr == gonbitsys-1) begin
				if (bittimer == c_bittimerlim-1) begin
					bitcntr				<= 0;
					state				<= S_STOP;
					tx_o				<= 1'b1;
					bittimer			<= 0;
				end	
				else begin
					bittimer			<= bittimer + 1;					
				end 
			end			
			else begin
				if (bittimer == c_bittimerlim-1) begin
					shreg[gonbitsys-1]			<= shreg[0];
					shreg[gonbitsys-2:0]	<= shreg[gonbitsys-1:1];					
					tx_o				<= shreg[0];
					bitcntr				<= bitcntr + 1;
					bittimer			<= 0;
				end	
				else begin
					bittimer			<= bittimer + 1;					
				end 
			end 
		end	

		S_STOP : begin		
			if (bittimer == c_stopbitlim-1) begin
				state				<= S_IDLE;
				tx_done_tick_o		<= 1'b1;
				bittimer			<= 0;
			end	
			else begin
				bittimer			<= bittimer + 1;				
			end 	
	    end
		default: begin
			state				<= S_IDLE;
		end	
	endcase
	
end	
endmodule
