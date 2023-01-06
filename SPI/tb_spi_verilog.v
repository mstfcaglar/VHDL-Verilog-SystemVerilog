`timescale 1ns / 1ps



module tb_spi_verilog
    #(
        parameter   c_clkfreq = 100_000_000,
        parameter   c_sclkfreq = 1_000_000,
        parameter   c_cpol = 0,
        parameter   c_cpha = 0
    )();


    reg   clk_i=0;		
    reg   en_i;	
    reg [7:0] mosi_data_i;
    reg   miso_i;      
    wire [7:0] miso_data_o;     
    wire  data_ready_o;
    wire  cs_o; 		 
    wire  sclk_o; 	
    wire  mosi_o;
    
    localparam clk_i_period = 10;
    localparam sckPeriod = 1000;

    reg [7:0] SPISIGNAL  = 0;
    reg spiWrite = 0;
    reg spiWriteDone = 0;

    //UUT
    spi_verilog uut(clk_i, en_i, mosi_data_i, miso_i, miso_data_o, data_ready_o, cs_o, sclk_o, mosi_o);


    always begin
        #(clk_i_period/2) clk_i = !clk_i;
    end


    always begin

        @(posedge spiWrite);
        miso_i = SPISIGNAL[7];
        @(negedge sclk_o);
        miso_i = SPISIGNAL[6];
        @(negedge sclk_o);
        miso_i = SPISIGNAL[5];
        @(negedge sclk_o);
        miso_i = SPISIGNAL[4];
        @(negedge sclk_o);
        miso_i = SPISIGNAL[3];
        @(negedge sclk_o);
        miso_i = SPISIGNAL[2];
        @(negedge sclk_o);
        miso_i = SPISIGNAL[1];
        @(negedge sclk_o);
        miso_i = SPISIGNAL[0];

        spiWriteDone    = 1;
        # 0.001 ; //1 ps
        spiWriteDone    = 0;

    end       
    
    initial begin
        
        #100 ;	
 
        #(clk_i_period*10);
    
    
        //	CPOL,CPHA = 00
        en_i 		= 1;  
    
        // write 0xD2, read 0xA2
        mosi_data_i	= 8'hD2;
        @(negedge cs_o);
        SPISIGNAL = 8'hA2;
        spiWrite    = 1;
        @(negedge spiWriteDone);
        spiWrite    = 0;
    
        // write 0x81, read 0x18
        @(posedge data_ready_o);
        mosi_data_i	<= 8'h81;	
        @(negedge sclk_o);
        SPISIGNAL <= 8'h18;
        spiWrite    <= 1;
        @(posedge spiWriteDone);
        spiWrite    <= 0;

        // write 0xC2, read 0x5A
        @(posedge data_ready_o);
        mosi_data_i	<= 8'hC2;	
        @(negedge sclk_o);
        SPISIGNAL <= 8'h5A;
        spiWrite    <= 1;
        @(posedge spiWriteDone);
        spiWrite    <= 0;

        en_i 		<= 0;  

    
        #(sckPeriod*4);
    
        $stop;
	




    end        







endmodule
