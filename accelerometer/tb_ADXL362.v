`timescale 1ns / 1ps

module tb_ADXL362#(
parameter p_clkfreq = 100_000_000,
parameter p_sclkfreq = 1_000_000,
parameter p_readfreq = 1_000,
parameter p_cpol = 0,
parameter p_cpha = 0)();

reg  clk_i=0; 
reg  miso_i;
wire mosi_o; 	
wire sclk_o; 	
wire cs_o; 	
wire [15:0]  ax_o; 	
wire [15:0] ay_o; 	
wire [15:0] az_o; 	
wire ready_o;	



//instantiation
ADXL362 uut(clk_i, miso_i, mosi_o, sclk_o, cs_o, ax_o, ay_o, az_o, ready_o);


localparam clk_i_period = 10;
localparam sckPeriod = 1000;//1us

reg [7:0] SPISIGNAL=0;
reg spiWrite=0;
reg spiWriteDone=0;  
integer i;

always begin
    // #10 clk = !clk;
    #(clk_i_period/2) clk_i = !clk_i;
end

always begin
    @(posedge spiWrite);

    if ((p_cpol == 0 && p_cpha == 0) || (p_cpol == 1 && p_cpha == 1)) begin
        for (i=0;i<8;i=i+1) begin
            miso_i    <= SPISIGNAL[7-i];  
            @(negedge sclk_o);
        end 
    end 

	if ((p_cpol == 0 && p_cpha == 1) || (p_cpol == 1 && p_cpha == 0)) begin
        for (i=0;i<8;i=i+1) begin
            miso_i    <= SPISIGNAL[7-i];
            @(posedge sclk_o); 
        end
    end 
	spiWriteDone    <= 1; 
    #0.001;//1ps
    spiWriteDone    <= 0;

end    

initial begin

    #(clk_i_period*10);
	#1_000_000;//1ms
    
	//CPOL,CPHA = 00  -- write 0xAA, 0xBB, 0xCC,  read 0xA1, 0xA2,
    @(negedge cs_o);      
	# 15510 ;  @(negedge sclk_o);
	#clk_i_period; #0.001;
	SPISIGNAL <= 'hA1; spiWrite    <= 1; #0.001;  spiWrite    <= 0;           // AX_L
	@(posedge spiWriteDone); #0.001; 
	// wait until falling_edge(sclk_o);  wait for 1 ps; wait until falling_edge(sclk_o); wait for 1 ps;
	SPISIGNAL <= 'hA2; spiWrite    <= 1;  #0.001;  spiWrite    <= 0;           // AX_H
	@(posedge spiWriteDone); #0.001;
	// wait until falling_edge(sclk_o);  wait for 1 ps; wait until falling_edge(sclk_o); wait for 1 ps;
	SPISIGNAL <= 'hA3; spiWrite    <= 1;  #0.001;  spiWrite    <= 0;           // AY_L
	@(posedge spiWriteDone); #0.001;
	// wait until falling_edge(sclk_o);  wait for 1 ps; wait until falling_edge(sclk_o); wait for 1 ps;
	SPISIGNAL <= 'hA4; spiWrite    <= 1;  #0.001;  spiWrite    <= 0;           // AY_H
	@(posedge spiWriteDone); #0.001;
	// wait until falling_edge(sclk_o);  wait for 1 ps; wait until falling_edge(sclk_o); wait for 1 ps;
	SPISIGNAL <= 'hA5; spiWrite    <= 1;  #0.001;  spiWrite    <= 0;           // AZ_L
	@(posedge spiWriteDone); #0.001;
	// wait until falling_edge(sclk_o);  wait for 1 ps; wait until falling_edge(sclk_o); wait for 1 ps;
	SPISIGNAL <= 'hA6; spiWrite    <= 1;  #0.001;  spiWrite    <= 0;           // AZ_H	
	@(posedge spiWriteDone); #0.001;
	@(posedge cs_o);
	
	
	#20_000;
	// wait until rising_edge(data_ready_o); wait for clk_i_period ;
	
    // wait until rising_edge(data_ready_o); wait for clk_i_period ; wait for 1 ps;
	// SPISIGNAL <= x"A1"; spiWrite    <= '1';  wait for 1 ps;  spiWrite    <= '0';           -- AX_L
	// wait until rising_edge(data_ready_o); wait for clk_i_period ; wait for 1 ps;           
    // SPISIGNAL <= x"A2"; spiWrite    <= '1';  wait for 1 ps;  spiWrite    <= '0';           -- AX_H
    // wait until rising_edge(data_ready_o); wait for clk_i_period ; wait for 1 ps;
	// SPISIGNAL <= x"A3"; spiWrite    <= '1';  wait for 1 ps;  spiWrite    <= '0';           -- AY_L
	// wait until rising_edge(data_ready_o); wait for clk_i_period ; wait for 1 ps;           
    // SPISIGNAL <= x"A4"; spiWrite    <= '1';  wait for 1 ps;  spiWrite    <= '0';           -- AY_H
    // wait until rising_edge(data_ready_o); wait for clk_i_period ; wait for 1 ps;	
	// SPISIGNAL <= x"A5"; spiWrite    <= '1';  wait for 1 ps;  spiWrite    <= '0';           -- AZ_L
	// wait until rising_edge(data_ready_o); wait for clk_i_period ; wait for 1 ps;           
    // SPISIGNAL <= x"A6"; spiWrite    <= '1';  wait for 1 ps;  spiWrite    <= '0';           -- AZ_H
    // wait until rising_edge(data_ready_o); wait for clk_i_period ; wait for 1 ps;
    
    #(clk_i_period*40);
    $stop;

end    





endmodule