`timescale 1ns / 1ps

module top#(
parameter p_clkfreq = 100_000_000,
// spi
parameter p_sclkfreq = 1_000_000,
parameter p_cpol = 0,
parameter p_cpha = 0,
// ADXL362
parameter p_readfreq = 2,
// uart
parameter p_baudrate = 115_200,
parameter p_stopbit	= 2    
)(
input   clk,		
input miso_i, 	
output mosi_o, 	
output sclk_o, 	
output cs_o, 	
output  tx		  
);

wire [15:0] ax;
wire [15:0] ay;
wire [15:0] az;
reg [7:0] din;
reg [6*8-1:0] tx_buffer;

wire ready;
reg tx_start;
wire tx_done_tick;
reg sent_trig;

reg [2:0] cntr;

//instantiation
ADXL362 dut (
.clk_i 	(clk   ),
.miso_i (miso_i),
.mosi_o (mosi_o),
.sclk_o (sclk_o),
.cs_o 	(cs_o  ), 
.ax_o 	(ax    ), 
.ay_o 	(ay    ), 
.az_o 	(az    ), 
.ready_o(ready )
);

uart_tx dut1 (
.clk			(clk         ),             
.din_i			(din         ),
.tx_start_i		(tx_start    ),
.tx_o			(tx          ),
.tx_done_tick_o	(tx_done_tick)
);


always @(posedge clk)  begin

    if(ready == 1) begin
        tx_buffer	<= {ax,ay,az};
		cntr		<= 6;
		sent_trig	<= 1;
    end 
    
    din <= tx_buffer[6*8-1 : 5*8];

    if (sent_trig == 1) begin
        if (cntr == 6) begin
            tx_start					<= 1;
			tx_buffer[6*8-1 : 8]	<= tx_buffer[5*8-1 : 0];
			cntr						<= cntr - 1;
        end
        else if(cntr == 0) begin
            tx_start <= 0;
            if (tx_done_tick == 1) begin
				sent_trig	<= 0;
			end 
        end 
        else begin
            if (tx_done_tick == 1) begin
				cntr						<= cntr - 1;
				tx_buffer[6*8-1 : 8]	<= tx_buffer[5*8-1 : 0];
			end 
        end      
    end            

end    




endmodule