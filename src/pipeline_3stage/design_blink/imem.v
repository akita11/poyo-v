//
// imem
//


`include "define.vh"

module imem(
    input wire clk,
    input wire [31:0] addr,
    output reg [31:0] rd_data
);
   wire [15:0] 	      iaddr = addr[17:2];
   always @(posedge clk) begin
      case (iaddr)
	// blink program
// loop iteration of 10000
//	16'h0000 : rd_data <= 32'h000020b7; // lui  x1,0x2
//	16'h0001 : rd_data <= 32'h70f08093; // addi x1,x1,0x70f / x1=0x270f=10000
// loop iteration of 5
	16'h0000 : rd_data <= 32'h000000b7; // lui  x1,0x0
	16'h0001 : rd_data <= 32'h00508093; // addi x1,x1,0x005 / x1=5
        16'h0002 : rd_data <= 32'h500001b7; // lui  x3,0x50000 / GPIO base address
        16'h0003 : rd_data <= 32'h00106213; // li   x4,1 / ori x0,x4,1
	16'h0004 : rd_data <= 32'h0041a023; // sw   x4,0(x3) ; GPIO=1
	16'h0005 : rd_data <= 32'h00000113; // mv   x2,x0 = addi x2,x0,0
	16'h0006 : rd_data <= 32'h00110113; // addi x2,x2,1 = x2++
 	16'h0007 : rd_data <= 32'hfe20fee3; // bgeu x1,x2,00018 
	16'h0008 : rd_data <= 32'h0001a023; // sw   x0,0(x3) ; GPIO=0
	16'h0009 : rd_data <= 32'h00000113; // mv   x2,x0 = addi x2,x0,0
	16'h000a : rd_data <= 32'h00110113; // addi x2,x2,1      ; x2++
	16'h000b : rd_data <= 32'hfe20fee3; // bgeu x1,x2,00028
	16'h000c : rd_data <= 32'hfe1ff06f; // j  00010         
       endcase
   end
   
endmodule
