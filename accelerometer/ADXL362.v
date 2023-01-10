`timescale 1ns / 1ps

module ADXL362#(   
parameter p_clkfreq = 100_000_000,
parameter p_sclkfreq = 1_000_000,
parameter p_readfreq = 1_000,
parameter p_cpol = 0,
parameter p_cpha = 0)(
input clk_i, 
input miso_i,
output mosi_o, 	
output sclk_o, 	
output cs_o, 	
output reg [15:0]  ax_o, 	
output reg [15:0] ay_o, 	
output reg [15:0] az_o, 	
output reg ready_o	
);




localparam timer_rd_lim = p_clkfreq/p_readfreq;
localparam S_CONFIGURE = 0, S_MEASURE = 1;


reg [7:0] mosi_data=0;
reg en=0;
wire [7:0] miso_data;
wire data_ready;


reg beginread=0;
reg [2:0] cntr=0; // general purpose counter

reg [clogb2(timer_rd_lim)-1:0] timer_rd=0;
reg timer_rd_tick=0;

reg state;

//instantiation
spi_verilog dut (
    .clk_i(clk_i),
    .en_i(en),
    .mosi_data_i(mosi_data),
    .miso_i(miso_i),
    .miso_data_o(miso_data),
    .data_ready_o(data_ready),
    .cs_o(cs_o),
    .sclk_o(sclk_o),
    .mosi_o(mosi_o)
    );


always @(posedge clk_i) begin

    case (state)

            S_CONFIGURE : begin
                if (timer_rd_tick == 1) begin
                    beginread	<= 1;
                end 
            
                if (beginread == 1) begin
                    if (cntr == 0) begin
                        en 			<= 1;
                        mosi_data	<= 'h0A;	// write command to ADXL362
                        if (data_ready == 1) begin
                            mosi_data	<= 'h2D;	// POWER_CTL register address
                            cntr		<= cntr + 1;
                        end 
                    end    
                    else if (cntr == 1) begin
                        if (data_ready == 1) begin
                            mosi_data	<= 'h02;	// enable measurmenet mode
                            cntr		<= cntr + 1;
                        end 
                    end        
                    else if (cntr == 2) begin
                        if (data_ready == 1) begin
                            cntr		<= 0;
                            en			<= 0;
                            state		<= S_MEASURE;
                            beginread	<= 0;
                        end 
                    end 
                end 
            end	

            S_MEASURE : begin
                if (timer_rd_tick == 1) begin
                    beginread	<= 1;
                end 
                
                if (beginread == 1) begin
                    if (cntr == 0) begin
                        en 			<= 1;
                        mosi_data	<= 'h0B;	// read command to ADXL362
                        if (data_ready == 1) begin
                            mosi_data	<= 'h0E;	// XDATA_L register address
                            cntr		<= cntr + 1;
                        end 
                    end    		
                    else if (cntr == 1) begin
                        if (data_ready == 1) begin
                            mosi_data			<= 'h00;	// in continious read mode, only first address is enough
                            cntr				<= cntr + 1;
                        end 
                    end    
                    else if (cntr == 2) begin
                        if (data_ready == 1) begin
                            cntr				<= cntr + 1;
                            ax_o [7:0] 	<= miso_data;
                        end 
                    end    
                    else if (cntr == 3) begin
                        if (data_ready == 1) begin
                            cntr		<= cntr + 1;
                            ax_o [15:8]	<= miso_data;
                        end 	
                    end    	
                    else if (cntr == 4) begin
                        if (data_ready == 1) begin
                            cntr				<= cntr + 1;
                            ay_o [7:0]	<= miso_data;
                        end 
                    end    		
                    else if (cntr == 5) begin
                        if (data_ready == 1) begin
                            cntr				<= cntr + 1;
                            ay_o [15:8]	<= miso_data;
                        end 
                    end    	
                    else if (cntr == 6) begin
                        if (data_ready == 1) begin
                            cntr				<= cntr + 1;
                            az_o [7:0]	<= miso_data;
                        end 
                    end    							
                    else if (cntr == 7) begin
                        if (data_ready == 1) begin
                            cntr				<= 0;
                            az_o [15:8]	<= miso_data;
                            ready_o				<= 1;
                            en 					<= 0;
                            beginread			<= 0;
                        end 						
                    end 
                end 
            end
            default : begin
                state <= S_CONFIGURE;
            end 

    endcase        



end    

always @(posedge clk_i) begin

    if (timer_rd == timer_rd_lim-1) begin
		timer_rd 		<= 0;
		timer_rd_tick	<= 1'b1;
    end    
	else begin
		timer_rd 		<= timer_rd + 1;
		timer_rd_tick	<= 0;
	end 

end	







function integer clogb2;
input integer depth;
for (clogb2=0; depth>0; clogb2=clogb2+1)
depth = depth >> 1;
endfunction


endmodule