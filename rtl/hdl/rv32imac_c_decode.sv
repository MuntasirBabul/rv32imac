
// 15  14  13  12  11  10  09  08  07  06  05  04  03  02  01  00
// {---funct4---}  {------rd/rs1----}  {-------rs2------}  {-op-}     CR-type
// {-funct3-}  imm {------rd/rs1----}  {-------imm------}  {-op-}     CI-type
// {-funct3-}  {--------imm---------}  {-------rs2------}  {-op-}     CSS-type
// {-funct3-}  {-------------imm------------}  {---rd’--}  {-op-}     CIW-type
// {-funct3-}  {---imm--}  {--rs1’--}  {-imm}  {---rd’--}  {-op-}     CL-type
// {-funct3-}  {---imm--}  {rd’/rs1’}  {-imm}  {--rs2’--}  {-op-}     CS-type
// {-funct3-}  {---imm--}  {--rs1’--} {-------imm-------}  {-op-}     CB-type
// {-funct3-}  {----------------offset------------------}  {-op-}     CJ-type

// Inst       Name                    FMT  OP   Funct        Description
// c.lwsp     Load Word from SP       CI   10   010          lw rd, (4*imm)(sp)
// c.swsp     Store Word to SP        CS   10   110          sw rs2, (4*imm)(sp)
// c.lw       Load Word               CS   00   010          lw rd', (4*imm)(rs1')
// c.sw       Store Word              CS   00   110          sw rs2', (4*imm)(rs1')
// c.j        Jump                    CJ   01   101          jal x0, 2*offset
// c.jal      Jump And Link           CJ   01   001          jal ra, 2*offset
// c.jr       Jump Reg                CR   10   1000         jalr x0, rs1, 0
// c.jalr     Jump And Link Reg       CR   10   1001         jalr ra, rs1, 0
// c.beqz     Branch == 0             CB   01   110          beq rs', x0, 2*imm
// c.bnez     Branch != 0             CB   01   111          bne rs', x0, 2*imm
// c.li       Load Immediate          CI   01   010          addi rd, x0, imm
// c.lui      Load Upper Imm          CI   01   011          lui rd, imm
// c.addi     ADD Immediate           CI   01   000          addi rd, rd, imm
// c.addi16sp ADD Imm * 16 to SP      CI   01   011          addi sp, sp, 16*imm
// c.addi4spn ADD Imm * 4 + SP        CI   00   000          addi rd', sp, 4*imm
// c.slli     Shift Left Logical Imm  CI   10   000          slli rd, rd, imm
// c.srli     Shift Right Logical Imm CB   01   1000x0       srli rd', rd', imm
// c.srai     Shift Right Arith Imm   CB   01   1000x1       srai rd', rd', imm
// c.andi     AND Imm                 CB   01   1001x0       andi rd', rd', imm
// c.mv       Move                    CR   10   1000          add rd, x0, rs2
// c.add      ADD                     CR   10   1001          add rd, rd, rs2
// c.and      AND                     CR   10   10001111     and rd', rd', rs2'
// c.or       OR                      CS   01   10001110     or rd', rd', rs2'
// c.xor      XOR                     CS   01   10001101     xor rd', rd', rs2'
// c.sub      SUB                     CS   01   10001100     sub rd', rd', rs2'
// c.nop      No Operation            CI   01   0000         addi x0, x0, 0
// c.ebreak   Environment BREAK       CR   10   1001         ebreak

module c_decode {

    input  logic [31:0] instr_raw,   // Raw instruction from I$
    output logic [31:0] instr_32,    // Decompressed 32-bit instruction
    output logic        compressed,  // 1 = was 16-bit compressed
    output logic        illegal_c    // 1 = illegal compressed instruction}

};

always_comb begin
  // Default: pass through 32-bit instruction unchanged
  instr_32     = instr_raw;
  compressed   = 1'b0;
  illegal_c    = 1'b0;

  if (instr_raw[1:0] != 2'b11) begin                    // 16-bit instruction
    compressed = 1'b1;
    case (instr_raw[1:0])
      
      2'b00: begin                                     // Quadrant 0
        case (instr_raw[15:13])
          3'b000: begin                              // c.addi4spn
            if (instr_raw[12:5] == 8'b0) 
              illegal_c = 1'b1;
            else 
              instr_32 = {5'b0,instr_raw[10:7],instr_raw[12:11],instr_raw[5],instr_raw[6],2'b00,5'd2,3'b000,instr_raw[4:2],2'b01};
          end
          3'b010: begin 
            instr_32 = {4'b0,instr_raw[8:7],instr_raw[12:10],instr_raw[6],2'b00,instr_raw[4:2],3'b010,instr_raw[9:7],7'b0000011}; // c.lw
          end
          3'b110: begin 
            instr_32 = {4'b0,instr_raw[8:7],instr_raw[12:10],instr_raw[6],2'b00,instr_raw[11:9],instr_raw[4:2],3'b010,instr_raw[9:7],7'b0100011}; // c.sw
          end
          default: illegal_c = 1'b1;
        endcase
      end

      2'b01: begin                                     // Quadrant 1
        case (instr_raw[15:13])
          3'b000: begin                              // c.addi / c.nop
            instr_32 = {{7{instr_raw[12]}},instr_raw[6:2],instr_raw[11:7],3'b000,instr_raw[11:7],7'b0010011};
          end
          3'b001, 3'b101: begin                      // c.jal / c.j
            instr_32 = {{12{instr_raw[12]}},instr_raw[8],instr_raw[10:9],instr_raw[6],instr_raw[7],instr_raw[2],instr_raw[11],instr_raw[5:3],{9{instr_raw[12]}},4'b0,
                        (instr_raw[15:13]==3'b001)?5'd1:5'd0,7'b1101111};
          end
          3'b010: begin 
            instr_32 = {{7{instr_raw[12]}},instr_raw[6:2],5'd0,3'b000,instr_raw[11:7],7'b0010011}; // c.li
          end
          3'b011: begin
            if (instr_raw[11:7] == 5'd2)              // c.addi16sp
              instr_32 = {{3{instr_raw[12]}},instr_raw[4:3],instr_raw[5],instr_raw[2],instr_raw[6],4'b0,5'd2,3'b000,5'd2,7'b0010011};
            else                                      // c.lui
              instr_32 = {{15{instr_raw[12]}},instr_raw[6:2],instr_raw[11:7],7'b0110111};
          end
          3'b100: begin
            case (instr_raw[11:10])
              2'b00, 2'b01:                          // c.srli / c.srai
                instr_32 = {7'b0000000,instr_raw[12],instr_raw[6:2],instr_raw[9:7],3'b101,instr_raw[9:7],7'b0010011};
              2'b10:                                   // c.andi
                instr_32 = {{7{instr_raw[12]}},instr_raw[6:2],instr_raw[9:7],3'b111,instr_raw[9:7],7'b0010011};
              2'b11: begin
                case (instr_raw[12:10])
                  3'b011: instr_32 = {12'b0,instr_raw[11:7],instr_raw[6:2],instr_raw[9:7],3'b111,instr_raw[9:7],7'b0110011}; // c.and
                  3'b010: instr_32 = {12'b0,instr_raw[11:7],instr_raw[6:2],instr_raw[9:7],3'b110,instr_raw[9:7],7'b0110011}; // c.or
                  3'b001: instr_32 = {12'b0,instr_raw[11:7],instr_raw[6:2],instr_raw[9:7],3'b100,instr_raw[9:7],7'b0110011}; // c.xor
                  3'b000: instr_32 = {7'b0100000,instr_raw[6:2],instr_raw[11:7],instr_raw[9:7],3'b000,instr_raw[9:7],7'b0110011}; // c.sub
                  default: illegal_c = 1'b1;
                endcase
              end
              default: illegal_c = 1'b1;
            endcase
          end
          3'b110, 3'b111: begin                      // c.beqz / c.bnez
            instr_32 = {{4{instr_raw[12]}},instr_raw[6:5],instr_raw[2],instr_raw[11:10],instr_raw[4:3],instr_raw[9:7],
                        (instr_raw[15:13]==3'b110)?3'b000:3'b001,instr_raw[9:7],7'b1100011};
          end
          default: illegal_c = 1'b1;
        endcase
      end

      2'b10: begin                                     // Quadrant 2
        case (instr_raw[15:13])
          3'b000: begin                              // c.slli
            if (instr_raw[12]) 
              illegal_c = 1'b1;
            else 
              instr_32 = {7'b0000000,instr_raw[6:2],instr_raw[11:7],3'b001,instr_raw[11:7],7'b0010011};
          end
          3'b010: begin 
            instr_32 = {4'b0,instr_raw[3:2],instr_raw[12],instr_raw[6:4],2'b00,5'd2,3'b010,instr_raw[11:7],7'b0000011}; // c.lwsp
          end
          3'b100: begin
            if (instr_raw[12] == 1'b0) begin
              if (instr_raw[6:2] == 5'b0)           // c.jr
                instr_32 = {12'b0,instr_raw[11:7],5'b0,3'b000,5'd1,7'b1100111};
              else                                   // c.mv
                instr_32 = {7'b0,instr_raw[6:2],5'b0,3'b000,instr_raw[11:7],7'b0110011};
            end else begin
              if (instr_raw[6:2] == 5'b0)           // c.jalr
                instr_32 = {12'b0,instr_raw[11:7],5'b0,3'b000,5'd1,7'b1100111};
              else                                   // C.ADD
                instr_32 = {7'b0,instr_raw[6:2],instr_raw[11:7],3'b000,instr_raw[11:7],7'b0110011};
            end
          end
          3'b110: begin 
            instr_32 = {4'b0,instr_raw[8:7],instr_raw[12],instr_raw[6:2],5'd2,3'b010,instr_raw[11:9],2'b00,7'b0100011}; // c.swsp
          end
          default: illegal_c = 1'b1;
        endcase
      end

      default: illegal_c = 1'b1;
    endcase
  end

  // Final illegal if hint/reserved
  if (compressed && instr_32 == 32'b0) illegal_c = 1'b1;
end

endmodule : c_decode
