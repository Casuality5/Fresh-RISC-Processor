class Packet;

    rand logic [6:0] op;
    logic [31:0] instruction;
    integer file;
    
    
    logic [6:0] op_values [9] = '{
        7'b0000011, // LOAD
        7'b0010011, // OP-IMM
        7'b0010111, // AUIPC
        7'b0100011, // STORE
        7'b0110011, // OP / R-Type
        7'b0110111, // LUI
        7'b1100011, // BRANCH
        7'b1100111, // JALR
        7'b1101111  // JAL
    };

    typedef struct packed {
        logic [6:0] funct7;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] rd;
    } r_instr_t;

    typedef struct packed {
        logic [11:0] imm;
        logic [4:0]  rs1;
        logic [2:0]  funct3;
        logic [4:0]  rd;
    } i_instr_t;

    typedef struct packed {
        logic [6:0] imm_11_5;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [4:0] imm_4_0;
    } s_instr_t;

    typedef struct packed {
        logic       imm_12;
        logic [5:0] imm_10_5;
        logic [4:0] rs2;
        logic [4:0] rs1;
        logic [2:0] funct3;
        logic [3:0] imm_4_1;
        logic       imm_11;
    } b_instr_t;

    typedef struct packed {
        logic [19:0] imm;
        logic [4:0]  rd;
    } u_instr_t;

    typedef struct packed {
        logic       imm_20;
        logic [9:0] imm_10_1;
        logic       imm_11;
        logic [7:0] imm_19_12;
        logic [4:0] rd;
    } j_instr_t;


    rand r_instr_t instr_r;
    rand i_instr_t instr_i;
    rand s_instr_t instr_s;
    rand b_instr_t instr_b;
    rand u_instr_t instr_u;
    rand j_instr_t instr_j;


    constraint op_range {
        op inside {7'b0000011, 7'b0010011, 7'b0110011};
        };


    constraint instruct {

        // LOAD
        if (op == 7'b0000011) {

            instr_i.funct3 inside {
                3'b000, // LB
                3'b001, // LH
                3'b010, // LW
                3'b100, // LBU
                3'b101  // LHU
            };

            instr_i.rd inside {[1:31]};
        }
        // OP-IMM
        else if (op == 7'b0010011){
            instr_i.funct3 inside {
                3'b000, // ADDI
                3'b010, // SLTI
                3'b011, // SLTIU
                3'b100, // XORI
                3'b110, // ORI
                3'b111, // ANDI
                3'b001, // SLLI
                3'b101  // SRLI / SRAI
            };

            instr_i.rd inside {[1:31]};

            if (instr_i.funct3 == 3'b001){
                instr_i.imm[11:5] == 7'b0000000;
            }

            else if (instr_i.funct3 == 3'b101){
                instr_i.imm[11:5] inside {
                    7'b0000000,
                    7'b0100000
                };
            }

        }


        // AUIPC
        else if (op == 7'b0010111){

            instr_u.rd inside {[1:31]};

        }


        // STORE
        else if (op == 7'b0100011){

            instr_s.funct3 inside {
                3'b000, // SB
                3'b001, // SH
                3'b010  // SW
            };

        }


        // R-Type
        else if (op == 7'b0110011){

            instr_r.rd inside {[1:31]};
            instr_r.rs1 inside {[0:31]};
            instr_r.rs2 inside {[0:31]};

            if (instr_r.funct3 == 3'b000){

                instr_r.funct7 inside {
                    7'b0000000, // ADD
                    7'b0100000  // SUB
                };

            }

            else if (instr_r.funct3 == 3'b001){
                instr_r.funct7 == 7'b0000000; // SLL
            }

            else if (instr_r.funct3 == 3'b010){
                instr_r.funct7 == 7'b0000000; // SLT
            }

            else if (instr_r.funct3 == 3'b011){
                instr_r.funct7 == 7'b0000000; // SLTU
            }

            else if (instr_r.funct3 == 3'b100){
                instr_r.funct7 == 7'b0000000; // XOR
            }

            else if (instr_r.funct3 == 3'b101){

                instr_r.funct7 inside {
                    7'b0000000, // SRL
                    7'b0100000  // SRA
                };

            }

            else if (instr_r.funct3 == 3'b110){
                instr_r.funct7 == 7'b0000000; // OR
            }

            else if (instr_r.funct3 == 3'b111){
                instr_r.funct7 == 7'b0000000; // AND
            }

            instr_r.funct3 inside {
                3'b000,
                3'b001,
                3'b010,
                3'b011,
                3'b100,
                3'b101,
                3'b110,
                3'b111
            };

        }


        // LUI
        else if (op == 7'b0110111){

            instr_u.rd inside {[1:31]};

        }


        // BRANCH
        else if (op == 7'b1100011){

            instr_b.funct3 inside {
                3'b000, // BEQ
                3'b001, // BNE
                3'b100, // BLT
                3'b101, // BGE
                3'b110, // BLTU
                3'b111  // BGEU
            };

        }


        // JALR
        else if (op == 7'b1100111){

            instr_i.funct3 == 3'b000;
            instr_i.rd inside {[1:31]};

        }


        // JAL
        else if (op == 7'b1101111){

            instr_j.rd inside {[1:31]};

        }

    }
    
    function void encode();

    case (op)

        // LOAD / I-Type
        7'b0000011,
        7'b0010011,
        7'b1100111: begin

            instruction = {instr_i,op};

        end

        // STORE / S-Type
        7'b0100011: begin

            instruction = {instr_s,op};

        end

        // R-Type
        7'b0110011: begin

            instruction = {instr_r,op};

        end

        // LUI / AUIPC / U-Type
        7'b0110111,
        7'b0010111: begin

            instruction = {instr_u,op};

        end

        // BRANCH / B-Type
        7'b1100011: begin

            instruction = {instr_b,op};

        end

        // JAL / J-Type
        7'b1101111: begin

            instruction = {instr_j,op};

        end

        default:
            instruction = 32'b0;

    endcase

    endfunction
    
    function void open();
        file = $fopen("D:/Fresh/Fresh.srcs/sim_1/new/Program.mem", "w");
        
        if (file == 0)
            $fatal("Cannot open Program.mem");
        
        $fclose(file);
        
    endfunction
    
    function void payload();
        
        file = $fopen("D:/Fresh/Fresh.srcs/sim_1/new/Program.mem","a");
        
        $fdisplay(file, "%08h", instruction);
    endfunction
endclass