//
// cpu_tb
//


module pipeline_cpu_tb;

    reg clk;
    reg rst;
    wire LED;

    parameter CYCLE = 10;

    always #(CYCLE/2) clk = ~clk;

    poyov_blink cpu_top(
       .clk(clk),
       .rst(rst),
       .LED(LED)
    );

    initial begin
        #10 clk = 1'd0;
        rst = 1'd1;
        #(CYCLE) rst = 1'd0;
    end

    initial begin
      $dumpfile("dump.vcd");
      $dumpvars(0, cpu_top);
      $monitor("%t: rst=%b clk=%b LED=%b", $time, rst, clk, LED);
    end  
   
endmodule
