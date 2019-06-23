//
// cpu_top
//


`include "define.vh"

module poyov_blink (
    input wire clk,
    input wire rst,
    output     LED
);
    // reset
    wire rst_n;
    assign rst_n = ~rst;


   
    // PC
    wire [7:0] next_PC;
    wire [7:0] ex_br_addr;
    wire ex_br_taken;
    reg [7:0] PC;

    // ex stageの結果をフォワーディング
      assign next_PC = (rst_n == 1'b0) ? PC + 4 : ex_br_taken ? ex_br_addr + 4 : PC + 4;
   
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            PC <= 0;
        end else begin
            PC <= next_PC;
        end
    end

    //====================================================================
    // fetch stage
    //====================================================================
   wire [7:0] imem_addr;
   wire [31:0] imem_rd_data;
    reg [7:0] ex_PC;

    // ex stageの結果をフォワーディング
    assign imem_addr = (rst_n == 1'b0) ? 0 : ex_br_taken ? ex_br_addr : PC;

    imem imem (
        .clk(clk),
        .addr(imem_addr),
        .rd_data(imem_rd_data)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ex_PC <= 0;
        end else begin
            ex_PC <= imem_addr;
        end
    end

    //====================================================================
    // execution stage
    //====================================================================
    
    // decoder
    wire [31:0] decoder_insn;
    wire [4:0] decoder_srcreg1_num, decoder_srcreg2_num, ex_dstreg_num;
    wire [31:0] decoder_imm;
    wire [5:0] ex_alucode;
    wire [1:0] ex_aluop1_type, ex_aluop2_type;
    wire ex_reg_we, ex_is_load, ex_is_store;

    assign decoder_insn = imem_rd_data;

    decoder decoder_0 (
        .insn(decoder_insn),
        .srcreg1_num(decoder_srcreg1_num),
        .srcreg2_num(decoder_srcreg2_num),
        .dstreg_num(ex_dstreg_num),
        .imm(decoder_imm),
        .alucode(ex_alucode),
        .aluop1_type(ex_aluop1_type),
        .aluop2_type(ex_aluop2_type),
        .reg_we(ex_reg_we),
        .is_load(ex_is_load),
        .is_store(ex_is_store)
    );

    // register file
    wire regfile_we;
    wire [4:0] regfile_srcreg1_num, regfile_srcreg2_num, regfile_dstreg_num;
    wire [31:0] regfile_srcreg1_value, regfile_srcreg2_value, regfile_dstreg_value;

    assign regfile_srcreg1_num = decoder_srcreg1_num;
    assign regfile_srcreg2_num = decoder_srcreg2_num;
    
    // wb stageの結果に応じて書き込み
    assign regfile_we = wb_reg_we;
    assign regfile_dstreg_num = wb_dstreg_num;
    assign regfile_dstreg_value = wb_dstreg_value;

    regfile regfile_0 (
        .clk(clk),
        .we(regfile_we),
        .srcreg1_num(regfile_srcreg1_num),
        .srcreg2_num(regfile_srcreg2_num),
        .dstreg_num(regfile_dstreg_num),
        .dstreg_value(regfile_dstreg_value),
        .srcreg1_value(regfile_srcreg1_value),
        .srcreg2_value(regfile_srcreg2_value)
    );

    // ALU
    wire [5:0] alu_alucode;
    wire [31:0] alu_op1, alu_op2, ex_alu_result;
    wire [31:0] ex_srcreg1_value, ex_srcreg2_value, ex_store_value;

    assign alu_alucode = ex_alucode;
    assign ex_srcreg1_value = (regfile_srcreg1_num==5'd0) ? 32'd0 : 
                              (wb_reg_we && (decoder_srcreg1_num == wb_dstreg_num)) ? wb_dstreg_value : regfile_srcreg1_value;
    assign ex_srcreg2_value = (regfile_srcreg2_num==5'd0) ? 32'd0 : 
                              (wb_reg_we && (decoder_srcreg2_num == wb_dstreg_num)) ? wb_dstreg_value : regfile_srcreg2_value;

    assign alu_op1 = (ex_aluop1_type == `OP_TYPE_REG) ? ex_srcreg1_value :
                        (ex_aluop1_type == `OP_TYPE_IMM) ? decoder_imm :
                        (ex_aluop1_type == `OP_TYPE_PC)  ? ex_PC: 32'd0;
    assign alu_op2 = (ex_aluop2_type == `OP_TYPE_REG) ? ex_srcreg2_value :
                        (ex_aluop2_type == `OP_TYPE_IMM) ? decoder_imm :
                        (ex_aluop2_type == `OP_TYPE_PC)  ? ex_PC : 32'd0;
    
    alu alu_0 (
        .alucode(alu_alucode),
        .op1(alu_op1),
        .op2(alu_op2),
        .alu_result(ex_alu_result),
        .br_taken(ex_br_taken)
    );

    assign ex_store_value = (ex_alucode == `ALU_SW) ? ex_srcreg2_value :
                            (ex_alucode == `ALU_SH) ? {{16{ex_srcreg2_value[15]}}, ex_srcreg2_value[15:0]} :
                            (ex_alucode == `ALU_SB) ? {{24{ex_srcreg2_value[7]}}, ex_srcreg2_value[7:0]} : 32'd0;

    assign ex_br_addr = (ex_alucode==`ALU_JAL) ? ex_PC + decoder_imm :
                        (ex_alucode==`ALU_JALR) ? alu_op1 + decoder_imm :
                        ((ex_alucode==`ALU_BEQ) || (ex_alucode==`ALU_BNE) || (ex_alucode==`ALU_BLT) ||
                         (ex_alucode==`ALU_BGE) || (ex_alucode==`ALU_BLTU) || (ex_alucode==`ALU_BGEU)) ? ex_PC + decoder_imm: 32'd0;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            wb_reg_we <= 1'b0;
            wb_dstreg_num <= 32'd0;
            wb_is_load <= 1'b0;
            wb_alucode <= 6'd0;
            wb_alu_result <= 32'd0;
        end else begin
            wb_reg_we <= ex_reg_we;
            wb_dstreg_num <= ex_dstreg_num;
            wb_is_load <= ex_is_load;
            wb_alucode <= ex_alucode;
            wb_alu_result <= ex_alu_result;
        end
    end
    //====================================================================
    // writeback stage
    //====================================================================
    reg wb_reg_we;
    reg [31:0] wb_dstreg_num;
    reg wb_is_load;
    reg [5:0] wb_alucode;
    reg [31:0] wb_alu_result;
    wire [31:0] wb_load_value, wb_dstreg_value;

    assign wb_dstreg_value = wb_is_load ? wb_load_value : wb_alu_result;
   // GPIO
   wire gpio_we;
   wire [7:0] gpio_data_i;
   wire [7:0] gpio_data_o;
   assign gpio_data_i = ex_store_value[7:0];
   assign gpio_we = ((ex_alu_result == `GPIO_ADDR) && (ex_is_store == `ENABLE)) ? 1'b1 : 1'b0;
   assign LED = gpio_data_o[0];

   gpio gpio_0 (
		.gpio_we(gpio_we),
		.wr_data(gpio_data_i),
		.clk(clk),
		.rst_n(rst_n),
		.gpio(gpio_data_o)
    );

   
endmodule
