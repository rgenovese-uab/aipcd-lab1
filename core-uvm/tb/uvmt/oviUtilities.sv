
    function int find_infl_sb_id (logic [SB_WIDTH-1:0] sb_id);

        foreach (infl_instr[i]) if (infl_instr[i].sb_id == sb_id) return i;
        return -1;

    endfunction : find_infl_sb_id

    // Function: encode_vlmul
    // Returns the encoding of vlmul
    function logic [CSR_VLMUL_WIDTH-1:0] encode_vlmul (int vlmul);
        case (vlmul)
            1: return 3'b000;
            2: return 3'b001;
            4: return 3'b010;
            8: return 3'b011;
            default:
                `uvm_fatal("oviProtocol", $sformatf("VLMUL %h is not implemented.", vlmul))
        endcase
    endfunction : encode_vlmul

    // Function: encode_sew
    // Returns the encoding of vsew
    function logic [CSR_VSEW_WIDTH-1:0] encode_sew (int sew);
        case (sew)
            8: return 3'b000;
            16: return 3'b001;
            32: return 3'b010;
            64: return 3'b011;
            128: return 3'b100;
            256: return 3'b101;
            default:
                `uvm_fatal("oviProtocol", $sformatf("SEW %h is not implemented.", sew))
        endcase
    endfunction : encode_sew
