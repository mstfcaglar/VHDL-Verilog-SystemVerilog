`timescale 1ns / 1ps



module tb_uart_rx  #(   parameter c_clkfreq = 100_000_000,  
                        parameter c_baudrate= 115_200  //frekans       
                    ) ();

reg clk;
reg rx_i;
wire [7:0] dout_o;
wire  rx_done_tick_o;

reg [3:0] i;

uart_rx dut(clk,rx_i, dout_o, rx_done_tick_o);


localparam real c_clk_period = 10;     
localparam c_baud115200 = 8680;     // (1/115200)*1_000_000_000  periyot (ns)

localparam c_hex52 = 10'b 1_01010010_0;
localparam c_hexB5 = 10'b 1_10110101_0;
localparam c_hex55 = 10'b 1_01010101_0;


always begin
   #(c_clk_period/2) clk = !clk;
end

initial begin
    clk = 0;
    rx_i = 1;

    #(c_clk_period*10);

    for(i=0;i<10;i=i+1) begin
        rx_i <= c_hex52[i];
        # c_baud115200;         
    end

    #20_000;

    for(i=0;i<10;i=i+1) begin
        rx_i <= c_hexB5[i];
        # c_baud115200;         
    end

    #20_000;

    for(i=0;i<10;i=i+1) begin
        rx_i <= c_hex55[i];
        # c_baud115200;         
    end

    #20_000;
    
    $stop;


end    







endmodule
