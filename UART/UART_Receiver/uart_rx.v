`timescale 1ns / 1ps



module uart_rx
    #(  parameter c_clkfreq = 100_000_000,  
        parameter c_baudrate= 115_200  
    ) (
        input clk,
        input rx_i,
        output [7:0] dout_o,
        output reg rx_done_tick_o

    );
   
    localparam c_bittimerlim = c_clkfreq/c_baudrate;
    localparam S_IDLE = 2'b00, S_START = 2'b01, S_DATA = 2'b10, S_STOP = 2'b11;


    reg [clogb2(c_bittimerlim)-1:0] bittimer = 0;
	reg [clogb2(7)-1:0] bitcntr ;
	reg [7:0] shreg = 8'b0 ;
	reg [1:0] state;

    always @(posedge clk) begin

        case (state)
        
            S_IDLE : begin
                rx_done_tick_o	<= 0;
			    bittimer		<= 0;
                bitcntr         <= 0;
                if (rx_i == 0) begin
                    state	<= S_START;
                end
            end	
            
            S_START : begin	
                shreg  <= 0;
                if (bittimer == c_bittimerlim/2-1) begin
                    state		<= S_DATA;
                    bittimer	<= 0;
                end    
                else begin
                    bittimer	<= bittimer + 1;
                end 
            end
            
            S_DATA : begin	
                if (bittimer == c_bittimerlim-1) begin
                    if (bitcntr == 7) begin
                        state	<= S_STOP;
                        bitcntr	<= 0;
                    end    
                    else begin
                        bitcntr	<= bitcntr + 1;
                    end 
                    shreg[bitcntr]	<= rx_i | shreg [bitcntr];
                    bittimer	<= 0;
                end    
                else begin
                    bittimer	<= bittimer + 1;
                end   
            end    
           
    
            S_STOP : begin		
                if (bittimer == c_bittimerlim-1) begin
                    state			<= S_IDLE;
                    bittimer		<= 0;
                    rx_done_tick_o	<= 1;
                end    
                else begin
                    bittimer	<= bittimer + 1;
                end 
            end    
            default: begin
                state			<= S_IDLE;
            end	
        endcase
        
    end	


assign dout_o = shreg; 
    
function integer clogb2;
input integer depth;
  for (clogb2=0; depth>0; clogb2=clogb2+1)
    depth = depth >> 1;
endfunction


endmodule
