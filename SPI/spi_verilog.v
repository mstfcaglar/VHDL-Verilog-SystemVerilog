`timescale 1ns / 1ps



module spi_verilog
    #(
        parameter   c_clkfreq = 100_000_000,
        parameter   c_sclkfreq = 1_000_000,
        parameter   c_cpol = 1'b0,
        parameter   c_cpha = 1'b0
    )
    (   
        input   clk_i, 		
        input   en_i,		
        input [7:0] mosi_data_i, 
        input   miso_i,      
        output reg [7:0] miso_data_o,     
        output reg  data_ready_o,
        output reg  cs_o, 		 
        output reg  sclk_o, 		 
        output reg  mosi_o 		 
    );

    localparam c_edgecntrlimdiv2 = c_clkfreq/(c_sclkfreq*2);
    localparam S_IDLE = 0, S_TRANSFER = 1;

    reg state;    
    reg [7:0] write_reg	= 0;	
    reg [7:0] read_reg	= 0;	

    reg sclk_en	= 0;
    reg sclk = 0;
    reg sclk_next = 0;
    reg sclk_rise = 0;
    reg sclk_fall = 0;

    reg mosi_en	= 0;
    reg miso_en	= 0;
    reg once = 0;

    reg [clogb2(c_edgecntrlimdiv2)-1:0] edgecntr = 0;

    reg [clogb2(15)-1:0] cntr = 0;

    wire [1:0] pol_phase;
    assign pol_phase = {c_cpol,c_cpha};

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//SAMPLE_EN
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @(pol_phase, sclk_fall, sclk_rise) begin


        case (pol_phase)

            00 : begin
                mosi_en <= sclk_fall;
                miso_en	<= sclk_rise;
            end	
            
            01 : begin	
                mosi_en <= sclk_rise;
                miso_en	<= sclk_fall;
            end
            
            10 : begin	
                mosi_en <= sclk_rise;
			    miso_en	<= sclk_fall;
            end    
        

            11 : begin		
                mosi_en <= sclk_fall;
			    miso_en	<= sclk_rise;
            end    
            	
        endcase

    end        

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//RISEFALL_DETECT
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

    always @(sclk, sclk_next) begin

        if (sclk == 1 && sclk_next == 0) begin
            sclk_rise <= 1;
        end    
        else begin
            sclk_rise <= 0;
        end 
     
        if (sclk == 0 && sclk_next == 1) begin
            sclk_fall <= 1;
        end    
        else begin
            sclk_fall <= 0;
        end 	

    end  
 
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//MAIN
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    always @(posedge clk_i) begin


        data_ready_o = 1'b0;
	    sclk_next	= sclk;

        case (state)
        
            S_IDLE : begin
                cs_o			<= 1;
                mosi_o			<= 0;
                data_ready_o	<= 0;			
                sclk_en			<= 0;
                cntr			<= 0; 
    
                if (c_cpol == 0) begin
                    sclk_o	<= 0;
                end    
                else begin
                    sclk_o	<= 1;
                end 	
    
                if (en_i == 1) begin
                    state		<= S_TRANSFER;
                    sclk_en		<= 1;
                    write_reg	<= mosi_data_i;
                    mosi_o		<= mosi_data_i [7];
                    read_reg	<= 8'h00;
                end 
            end	
          
            
            S_TRANSFER : begin	
                cs_o	<= 0;
                mosi_o	<= write_reg[7];
     
     
                if (c_cpha == 1) begin	
     
                    if (cntr == 0) begin
                        sclk_o	<= sclk;
                        if (miso_en == 1) begin
                            read_reg [0]		<=  miso_i;
                            read_reg [7:1]      <=  read_reg [6:0];
                            cntr				<=  cntr + 1;
                            once                <=  1;
                        end 
                    end    			
                    else if (cntr == 8) begin
                        if (once == 1) begin
                            data_ready_o	<= 1;
                            once            <= 0;				       
                        end 					
                        miso_data_o		<= read_reg;
                        if (mosi_en == 1) begin
                            if (en_i == 1) begin
                                write_reg	<= mosi_data_i;
                                mosi_o		<= mosi_data_i[7];	
                                sclk_o		<= sclk;							
                                cntr		<= 0;
                            end    
                            else begin
                                state	<= S_IDLE;
                                cs_o	<= 1;								
                            end 
                        end 
                    end    
                    else if (cntr == 9) begin
                        if (miso_en == 1) begin
                            state	<= S_IDLE;
                            cs_o	<= 1;
                        end 
                    end    						
                    else begin
                        sclk_o	<= sclk;
                        if (miso_en == 1) begin
                            read_reg [0]				<= miso_i;
                            read_reg [7:1] 	<= read_reg [6:0];
                            cntr					<= cntr + 1;
                        end 
                        if (mosi_en == 1) begin
                            mosi_o	<= write_reg [7];
                            write_reg [7:1]	<= write_reg [6:0];
                        end 
                    end 
                end 

                else begin
     
                    if (cntr == 0) begin
                        sclk_o	<= sclk;					
                        if (miso_en == 1) begin
                            read_reg [0]				<= miso_i;
                            read_reg [7:1] 	<= read_reg [6:0];
                            cntr					<= cntr + 1;
                            once                    <= 1;
                        end
                    end     
                    else if (cntr == 8) begin			
                        if (once == 1) begin
                            data_ready_o    <= 1;
                            once            <= 0;                       
                        end 
                        miso_data_o		<= read_reg;
                        sclk_o			<= sclk;
                        if (mosi_en == 1) begin
                            if (en_i == 1) begin
                                write_reg	<= mosi_data_i;
                                mosi_o		<= mosi_data_i [7];		
                                cntr		<= 0;
                            end    
                            else begin
                                cntr	<= cntr + 1;
                            end 
                            if (miso_en == 1) begin
                                state	<= S_IDLE;
                                cs_o	<= 1;							
                            end 
                        end 
                    end    		
                    else if (cntr == 9) begin
                        if (miso_en == 1) begin
                            state	<= S_IDLE;
                            cs_o	<= 1;
                        end 
                    end    
                    else begin
                        sclk_o	<= sclk;
                        if (miso_en == 1) begin
                            read_reg [0]				<= miso_i;
                            read_reg [7:1] 	<= read_reg [6:0];
                            cntr					<= cntr + 1;
                        end 
                        if (mosi_en == 1) begin
                            write_reg [7:1] 	<= write_reg [6:0];
                        end 
                    end 			
     
                end           
            end
            default : begin
                state <= S_IDLE;
            end        
        endcase
        
    end
    
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//SCLK_GEN
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

    always @(posedge clk_i) begin

        if (sclk_en == 1) begin
            if (edgecntr == c_edgecntrlimdiv2-1) begin
                sclk 		<= (! sclk);
                edgecntr	<= 0;
            end    
            else 
                edgecntr	<= edgecntr + 1;
        end          
        else begin
            edgecntr	<= 0;
            if (c_cpol == 0) begin
                sclk	<= 0;
            end    
            else
                sclk	<= 1;
        end 

    end





    function integer clogb2;
    input integer depth;
    for (clogb2=0; depth>0; clogb2=clogb2+1)
    depth = depth >> 1;
    endfunction

endmodule
