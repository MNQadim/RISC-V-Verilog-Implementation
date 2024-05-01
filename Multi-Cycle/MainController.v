`define R_T     7'b0110011
`define I_T     7'b0010011
`define S_T     7'b0100011
`define B_T     7'b1100011
`define U_T     7'b0110111
`define J_T     7'b1101111
`define L_T     7'b0000011

`define Fetch        5'b00000
`define Decode       5'b00001
`define EX_I         5'b00010
`define EX_J         5'b00101
`define EX_R         5'b00011
`define RegWrite     5'b01110
`define EX_B         5'b00100
`define EX_S         5'b00111
`define MemWrite     5'b01101
`define EX_L         5'b01010
`define MemRead      5'b01011
`define MemWB        5'b10001
`define MEM_U        5'b01111
`define RejWrite     5'b11010

module MainController(clk, rst, op, zero, neg,
                      PCUpdate, adrSrc, memWrite, branch,
                      IRWrite, resultSrc, ALUOp, 
                      ALUSrcA, ALUSrcB, immSrc, regWrite);

    input [6:0] op;
    input clk, rst, zero , neg;

    output reg [1:0]  resultSrc, ALUSrcA, ALUSrcB, ALUOp;
    output reg [2:0] immSrc;
    output reg adrSrc, regWrite, memWrite, PCUpdate, branch, IRWrite;

    reg [4:0] pstate;
    reg [4:0] nstate = `Fetch;

    always @(*) begin
        case (pstate)
            `Fetch   : nstate <= `Decode;

            `Decode  : nstate <= (op == `I_T)    ? `EX_I     :
                                 (op == `R_T)    ? `EX_R     :
                                 (op == `B_T)    ? `EX_B     :
                                 (op == `U_T)    ? `MEM_U    :                                    
                                 (op == `J_T)    ? `EX_J     :
                                 (op == `S_T)    ? `EX_S     :
                                 (op == `L_T)    ? `EX_L     : `Fetch; // undefined instruction

            `EX_I : nstate <= `RegWrite;
            `RegWrite: nstate <= `Fetch;

            `EX_R : nstate <= `RegWrite;
            `RegWrite: nstate <= `Fetch;

            `EX_B : nstate <= `Fetch;

            `EX_J : nstate <= `RejWrite;
            `RejWrite : nstate <= `Fetch;

            `EX_S : nstate <= `MemWrite;
            `MemWrite: nstate <= `Fetch;
            
            `EX_L : nstate <= `MemRead;
            `MemRead: nstate <= `MemWB;
            `MemWB : nstate <= `Fetch;

            `MEM_U: nstate <= `Fetch;


        endcase
    end

    always @(pstate) begin

        {resultSrc, memWrite, ALUOp, ALUSrcA, ALUSrcB, immSrc, 
                regWrite, PCUpdate, branch, IRWrite} <= 14'b0;

        case (pstate)
            // instruction fetch
            `Fetch : begin
                IRWrite   <= 1'b1;
                adrSrc    <= 1'b0;
                ALUSrcA   <= 2'b00;
                ALUSrcB   <= 2'b10;
                ALUOp     <= 2'b00;
                resultSrc <= 2'b10;
                PCUpdate  <= 1'b1;
            end
            // instruction decode
            `Decode: begin
                ALUSrcA   <= 2'b01;
                ALUSrcB   <= 2'b01;
                ALUOp     <= 2'b00;
                immSrc    <= 3'b010;
            end
            // I-type
            `EX_I: begin 
                ALUSrcA   <= 2'b10;
                ALUSrcB   <= 2'b01;
                immSrc    <= 3'b000;
                ALUOp     <= 2'b11;
            end
            // LW (like JALR)
            `EX_L: begin 
                ALUSrcA   <= 2'b10;
                ALUSrcB   <= 2'b01;
                immSrc    <= 3'b000;
                ALUOp     <= 2'b00;
            end

            `MemRead: begin
                resultSrc <= 2'b00;
                adrSrc    <= 1'b1;
            end

            `MemWB: begin
                resultSrc <= 2'b01;
                regWrite  <= 1'b1;
            end
            // R-type
            `EX_R: begin
                ALUSrcA   <= 2'b10;
                ALUSrcB   <= 2'b00;
                ALUOp     <= 2'b10;
            end
            // B-type
            `EX_B: begin
                ALUSrcA   <= 2'b10;
                ALUSrcB   <= 2'b00;
                ALUOp     <= 2'b01;
                resultSrc <= 2'b00;
                branch    <= 1'b1;
            end
            // J-type
            `EX_J: begin
                ALUSrcA   <= 2'b01;
                ALUSrcB   <= 2'b01;
                ALUOp     <= 2'b00;
                resultSrc <= 2'b00;
            end

            // S-type
            `EX_S: begin
                ALUSrcA   <= 2'b10;
                ALUSrcB   <= 2'b01;
                ALUOp     <= 2'b00;
                immSrc    <= 3'b001;
            end
        
            `MemWrite: begin
                resultSrc <= 2'b00;
                adrSrc    <= 1'b1;
                memWrite  <= 1'b1;
            end
            // U-type
            `MEM_U: begin
                resultSrc <= 2'b11;
                immSrc    <= 3'b100;
                regWrite  <= 1'b1;
            end
            `RegWrite: begin
                resultSrc <= 2'b00;
                regWrite  <= 1'b1;
            end
            `RejWrite: begin
                resultSrc <= 2'b00;
                regWrite  <= 1'b1;
                PCUpdate  <= 1'b1;

            end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst)
            pstate <= `Fetch;
        else
            pstate <= nstate;
    end

endmodule