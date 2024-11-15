
    // Function: scalar_dest_reg
    // Returns 1 if instruction has scalar result, 0 otherwise
    // These instructions are vmfirst.m, vmpopc.m, vext.x.v/vmv.x.s, vfmv.f.s
    // In RVV-1.0, the instructions are renamed to vcpop.m, vfirst.m, vmv.x.s, vfmv.f.s (vext.x.v has disappeared from the ISA)
	//
    function bit scalar_dest_reg (logic [common_params_pkg::INSTR_WIDTH:0] inst, logic fp);
        logic [common_params_pkg::INSTR_FUNCT6_WIDTH:0] funct6;
        logic [common_params_pkg::INSTR_VSRC1_WIDTH:0] vs1;
        logic [common_params_pkg::INSTR_FUNCT3_WIDTH:0] funct3;
        logic [common_params_pkg::INSTR_OPCODE_WIDTH:0] opcode;

        funct6 = `funct6(inst);
        vs1 = `vs1(inst);
        funct3 = `funct3(inst);
        opcode = `opcode(inst);

/* RVV-0.7.1 encoding
        if (funct6 == 6'b010101 && funct3 == 3'b010 && opcode == 7'b1010111)
            return 1'b1;
        else if (funct6 == 6'b010100 && funct3 == 3'b010 && opcode == 7'b1010111)
            return 1'b1;
        else if (funct6 == 6'b001100 && funct3 == 3'b010 && opcode == 7'b1010111)
            return 1'b1;
        else if (funct6 == 6'b001100 && rs1 == 5'b00000 && funct3 == 3'b001 && opcode == 7'b1010111)
            return 1'b1;
*/
        if (!fp && funct6 == 6'b010000 && funct3 == 3'b010 && opcode == 7'b1010111) begin // VWXUNARY0 (vcpop.m, vfirst.m, vmv.x.s)
            return (vs1 inside {5'b00000, 5'b10000, 5'b10001});
        end else if (fp && funct6 == 6'b010000 && funct3 == 3'b001 && opcode == 7'b1010111) begin // VWFUNARY0 (vfmv.f.s)
            return (vs1 == 5'b00000);
        end
        return 1'b0;
    endfunction : scalar_dest_reg

    function bit vwfunary0_vrfunary0 (logic [common_params_pkg::INSTR_WIDTH:0] inst);
        logic [common_params_pkg::INSTR_FUNCT6_WIDTH:0] funct6;
        logic [common_params_pkg::INSTR_FUNCT3_WIDTH:0] funct3;
        logic [common_params_pkg::INSTR_OPCODE_WIDTH:0] opcode;

        funct6 = `funct6(inst);
        funct3 = `funct3(inst);
        opcode = `opcode(inst);

        if (funct6 == 6'b010000 && funct3 == 3'b001 && opcode == 7'b1010111)
            return 1'b1;
        else if (funct6 == 6'b010000 && funct3 == 3'b101 && opcode == 7'b1010111)
            return 1'b1;

        return 1'b0;
    endfunction : vwfunary0_vrfunary0

    // Function: reduction_instruction
    // Differs whether an instruction is a reduction instruction
    function bit reduction_instruction (logic [common_params_pkg::INSTR_WIDTH-1:0] inst);
        logic [common_params_pkg::INSTR_FUNCT6_WIDTH:0] funct6;
        logic [common_params_pkg::INSTR_VSRC1_WIDTH:0] rs1;
        logic [common_params_pkg::INSTR_FUNCT3_WIDTH:0] funct3;
        logic [common_params_pkg::INSTR_OPCODE_WIDTH:0] opcode;

        funct6 = `funct6(inst);
        rs1 = `rs1(inst);
        funct3 = `funct3(inst);
        opcode = `opcode(inst);

        if (opcode == 7'b1010111 && funct3 == 3'b001 && (funct6 == 6'b000001 || funct6 == 6'b110001 || funct6 == 6'b000011 || funct6 == 6'b000101 || funct6 == 6'b000111 || funct6 == 6'b110011))
            return 1'b1;
        else if (opcode == 7'b1010111 && funct3 == 3'b000 && (funct6 == 6'b110000 || funct6 == 6'b110001))
            return 1'b1;
        else if (opcode == 7'b1010111 && funct3 == 3'b010 && funct6[5:3] == 3'b000)
            return 1'b1;
        else if (funct6 == 6'b111001 && funct3 == 3'b001 && opcode == 7'b1010111)
            return 1'b1;

        return 1'b0;
    endfunction : reduction_instruction

    // Function: widening_instruction
    // Differs whether an instruction is a widening instruction
    function bit widening_instruction (logic [common_params_pkg::INSTR_WIDTH:0] inst);
        if ((`funct6(inst) ==? 6'b110000 || `funct6(inst) ==? 6'b110001) && `funct3(inst) ==? 3'b000 && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else if (`funct6(inst) ==? 6'b11ZZZZ && `funct3(inst) ==? 3'b110 && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else if (`funct6(inst) ==? 6'b11ZZZZ && `funct3(inst) ==? 3'b010 && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else if (`funct6(inst) != 6'b111001 && `funct6(inst) ==? 6'b11ZZZZ && `funct3(inst) ==? 3'bZ01 && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else if (`funct6(inst) ==? 6'b1111ZZ && `funct3(inst) ==? 3'b010 && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else if (`funct6(inst) ==? 6'b1111ZZ && `funct3(inst) ==? 3'b101 && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else if (`funct6(inst) ==? 6'b1111ZZ && `funct3(inst) ==? 3'b110 && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else if (`funct6(inst) ==? 6'b111111 && `funct3(inst) ==? 3'b110 && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else return 1'b0;
    endfunction : widening_instruction

    // Function: narrowing_instruction
    // Differs whether an instruction is a narrowing instruction
    function bit narrowing_instruction (logic [common_params_pkg::INSTR_WIDTH:0] inst);
        if ((`funct6(inst) ==? 6'b1011ZZ) && (`funct3(inst) ==? 3'b100 || `funct3(inst) ==? 3'b000 || `funct3(inst) ==? 3'b011) && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else if (`funct6(inst) ==? 6'b101Z11 && (`funct3(inst) ==? 3'b010 || `funct3(inst) ==? 3'b110)  && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else return 1'b0;
    endfunction : narrowing_instruction

    // Function: vset_instruction
    // Differs whether an instruction is a vsetvl/vsetvli 
    function bit vset_instruction (logic [common_params_pkg::INSTR_WIDTH:0] inst);
        if ((`funct3(inst) ==? 3'b111)  && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else return 1'b0;
    endfunction : vset_instruction

    // Function: fused_instruction
    // Differs whether an instruction is a fused instruction
    function bit fused_instruction (logic [common_params_pkg::INSTR_WIDTH-1:0] inst);
        if (`funct6(inst) ==? 6'b1111ZZ && (`funct3(inst) ==? 3'b101 || `funct3(inst) ==? 3'b010 || `funct3(inst) ==? 3'b110) && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else if (`funct6(inst) ==? 6'b1010ZZ && (`funct3(inst) ==? 3'b101 || `funct3(inst) ==? 3'b001) && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else if (`funct6(inst) ==? 6'b1011ZZ && (`funct3(inst) ==? 3'b101 || `funct3(inst) ==? 3'b001) && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else if (`funct6(inst) ==? 3'b101ZZZ && (`funct3(inst) ==? 3'b010 || `funct3(inst) ==? 3'b110) && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else if (`funct6(inst) != 6'b111001 && `funct6(inst) ==? 6'b11ZZZZ && `funct3(inst) ==? 3'b001 && `opcode(inst) ==? 7'b1010111) return 1'b1;
        else return 1'b0;
    endfunction : fused_instruction

    // Function: print_dvreg
    // Prints the content of the register passed as a parameter
    function automatic void print_dvreg(int vl, int sew, ref string vreg_error, core_uvm_types_pkg::vec_els_t vreg_result);
        int how_many;
        int line_break;
        int lb_counter;
        string spaces;
        vreg_error = "";
        how_many = sew/BYTE;
        line_break = 280/((sew/4)+1);
        lb_counter = 0;
        spaces = "    ";
        for(int i = 0; i < vl; i++)
        begin
            if (spaces.len() == 4 && i >= 10) spaces = "   ";
            if (spaces.len() == 3 && i >= 100) spaces = "  ";
            if (spaces.len() == 2 && i >= 1000) spaces = " ";
            for(int j = 0; j < how_many; j++)
            begin
                vreg_error = {$sformatf("%h", vreg_result[i*sew/common_params_pkg::ELEN][i*sew%common_params_pkg::ELEN + j*BYTE +: BYTE]), vreg_error};
            end
            ++lb_counter;
            if (lb_counter == line_break) begin
                lb_counter = 0;
                vreg_error = {$sformatf("\n%0d:%s", i, spaces), vreg_error};
            end
            else begin
                if ((i + 1) != vl) vreg_error = {" ", vreg_error};
            end
        end
        if (vl && lb_counter) begin
            vreg_error = {$sformatf("\n%0d:%s", vl-1, spaces), vreg_error, "\n"};
        end
    endfunction : print_dvreg

    function automatic void print_iss_mask(int vl, int sew, ref string vreg_error, core_uvm_types_pkg::vec_els_t vreg_result);
        int how_many;
        int line_break;
        int lb_counter;
        string spaces;
        vreg_error = "";
        how_many = sew/BYTE;
        line_break = 280/((sew/4)+1);
        lb_counter = 0;
        spaces = "    ";
        for(int i = 0; i < vl/sew; i++)
        begin
            if (spaces.len() == 4 && i >= 10) spaces = "   ";
            if (spaces.len() == 3 && i >= 100) spaces = "  ";
            if (spaces.len() == 2 && i >= 1000) spaces = " ";
            for(int j = 0; j < how_many; j++)
            begin
                vreg_error = {$sformatf("%h", vreg_result[i*sew/common_params_pkg::ELEN][i*sew%common_params_pkg::ELEN + j*BYTE +: BYTE]), vreg_error};
            end
            ++lb_counter;
            if (lb_counter == line_break) begin
                lb_counter = 0;
                vreg_error = {$sformatf("\n%0d:%s", i, spaces), vreg_error};
            end
            else begin
                if ((i + 1) != vl) vreg_error = {" ", vreg_error};
            end
        end
        if (vl && lb_counter) begin
            vreg_error = {$sformatf("\n%0d:%s", vl-1, spaces), vreg_error, "\n"};
        end
    endfunction : print_iss_mask

    function automatic print_src1(core_uvm_types_pkg::iss_state_t instr, ref string src_string);
        if (`opcode(instr.scalar_state.instr) == 7'b1010111) begin // OPV
            if (`funct3(instr.scalar_state.instr) inside {3'b100, 3'b110, 3'b111}) begin // OPIVX, OPMVX, OPCFG
                src_string = $sformatf("ireg src1 (%d): %x\n", `vs1(instr.scalar_state.instr), instr.scalar_state.src1_value);
            end else if (`funct3(instr.scalar_state.instr) == 3'b101) begin // OPFVF
                src_string = $sformatf("freg src1 (%d): %x\n", `vs1(instr.scalar_state.instr), instr.scalar_state.src1_value);
            end else if (`funct3(instr.scalar_state.instr) == 3'b011) begin // OPIVI
                src_string = $sformatf("immediate: %x\n", `simm5(instr.scalar_state.instr));
            end else begin // TODO exclude unary
                string aux = "";
                print_dvreg(instr.scalar_state.csr.vl, instr.scalar_state.csr.vsew, aux, instr.rvv_state.vs1);
                src_string = $sformatf("vreg src1 (%d): %s\n", `vs1(instr.scalar_state.instr), aux);
            end
        end else if (`opcode(instr.scalar_state.instr) inside {7'b0000111, 7'b0100111}) begin // VLD, VST
            src_string = $sformatf("ireg src1 (%d): %x\n", `vs1(instr.scalar_state.instr), instr.scalar_state.src1_value);
        end
    endfunction: print_src1

    function automatic print_src2(core_uvm_types_pkg::iss_state_t instr, ref string src_string);
        if (`opcode(instr.scalar_state.instr) == 7'b1010111) begin // OPV
            if (`funct3(instr.scalar_state.instr) == 3'b111) begin // OPCFG
                if (instr.scalar_state.instr[31] == 1'b1) begin // vsetvl
                    src_string = $sformatf("ireg src2 (%d): %x\n", `vs2(instr.scalar_state.instr), instr.scalar_state.src2_value);
                end
            end else begin
                string aux = "";
                print_dvreg(instr.scalar_state.csr.vl, instr.scalar_state.csr.vsew, aux, instr.rvv_state.vs2);
                src_string = $sformatf("vreg src2 (%d): %s\n", `vs2(instr.scalar_state.instr), aux);
            end
        end else if (`opcode(instr.scalar_state.instr) inside {7'b0000111, 7'b0100111}) begin // VLD, VST
            if (instr.scalar_state.instr[28:26] inside {3'b010, 3'b110}) begin // strided
                src_string = $sformatf("ireg src2 (%d): %x\n", `vs2(instr.scalar_state.instr), instr.scalar_state.src2_value);
            end else if (instr.scalar_state.instr[28:26] inside {3'b011, 3'b111}) begin // indexed
                string aux = "";
                print_dvreg(instr.scalar_state.csr.vl, instr.scalar_state.csr.vsew, aux, instr.rvv_state.vs2);
                src_string = $sformatf("vreg src2 (%d): %s\n", `vs2(instr.scalar_state.instr), aux);
            end
        end
    endfunction: print_src2

    function automatic print_src3(core_uvm_types_pkg::iss_state_t instr, ref string src_string);
        if (`opcode(instr.scalar_state.instr) == 7'b1010111) begin // OPV
            if (instr.scalar_state.instr[25] == 1'b0) begin // masked
                string aux = "";
                print_dvreg(instr.scalar_state.csr.vl, instr.scalar_state.csr.vsew, aux, instr.rvv_state.old_vd);
                src_string = $sformatf("vreg old_vd (%d): %s\n", `vdest(instr.scalar_state.instr), aux);
            end else if (instr.scalar_state.instr[31:29] == 3'b101) begin // All FMA variants encoded with 101xxx
                if (`funct3(instr.scalar_state.instr) inside {3'b010, 3'b110, 3'b001, 3'b101}) begin // OPMVV, OPMVX, OPFVV, OPFVF
                    string aux = "";
                    print_dvreg(instr.scalar_state.csr.vl, instr.scalar_state.csr.vsew, aux, instr.rvv_state.old_vd);
                    src_string = $sformatf("vreg old_vd (%d): %s\n", `vdest(instr.scalar_state.instr), aux);
                end
            end else if (instr.scalar_state.instr[31:28] == 4'b1111) begin // All widening FMA variants encoded with 101xxx
                if (`funct3(instr.scalar_state.instr) inside {3'b010, 3'b110, 3'b001, 3'b101}) begin // OPMVV, OPMVX, OPFVV, OPFVF
                    string aux = "";
                    print_dvreg(instr.scalar_state.csr.vl, instr.scalar_state.csr.vsew, aux, instr.rvv_state.old_vd);
                    src_string = $sformatf("vreg old_vd (%d): %s\n", `vdest(instr.scalar_state.instr), aux);
                end
            end else if (instr.scalar_state.instr[28:26] inside {3'b011, 3'b111}) begin // indexed
                string aux = "";
                print_dvreg(instr.scalar_state.csr.vl, instr.scalar_state.csr.vsew, aux, instr.rvv_state.vs2);
                src_string = $sformatf("vreg src3 (%d): %s\n", `vs2(instr.scalar_state.instr), aux);
            end
        end else if (`opcode(instr.scalar_state.instr) == 7'b0000111) begin // VLD
            if (instr.scalar_state.instr[25] == 1'b0) begin // masked
                string aux = "";
                print_dvreg(instr.scalar_state.csr.vl, instr.scalar_state.csr.vsew, aux, instr.rvv_state.old_vd);
                src_string = $sformatf("vreg old_vd (%d): %s\n", `vdest(instr.scalar_state.instr), aux);
            end
        end else if (`opcode(instr.scalar_state.instr) == 7'b0100111 ) begin //VST
            string aux = "";
            print_dvreg(instr.scalar_state.csr.vl, instr.scalar_state.csr.vsew, aux, instr.rvv_state.vs3);
            src_string = $sformatf("vreg src3 (%d): %s\n", `vs3(instr.scalar_state.instr), aux);
        end
    endfunction: print_src3

    function automatic print_mask(core_uvm_types_pkg::iss_state_t instr, ref string src_string);
        if (instr.scalar_state.instr[25] == 1'b0) begin // masked
            string aux = "";
            print_dvreg(instr.scalar_state.csr.vl, instr.scalar_state.csr.vsew, aux, instr.rvv_state.vmask);
            src_string = $sformatf("vreg mask (%d): %s\n", 0, aux);
        end else if (`opcode(instr.scalar_state.instr) == 7'b1010111) begin // OPV
            if (instr.scalar_state.instr[31:28] == 4'b0100) begin // All add/sub with carry/borrow (mask) encoded with 0100xx
                string aux = "";
                print_dvreg(instr.scalar_state.csr.vl, instr.scalar_state.csr.vsew, aux, instr.rvv_state.vmask);
                src_string = $sformatf("vreg mask (%d): %s\n", 0, aux);
            end
        end
    endfunction: print_mask

    // Function: print_sources
    // Returns the content of the source registers for an instruction
    function automatic void print_sources(core_uvm_types_pkg::iss_state_t instr, ref string sources);
        core_uvm_types_pkg::vec_els_t vs2 = instr.rvv_state.vs2;
        core_uvm_types_pkg::vec_els_t vs3 = instr.rvv_state.vs3;
        core_uvm_types_pkg::vec_els_t vmask = instr.rvv_state.vmask;
        string s1_string = "";
        string s2_string = "";
        string s3_string = "";
        string vmask_string = "";
        print_src1(instr, s1_string);
        print_src2(instr, s2_string);
        print_src3(instr, s3_string);
        print_mask(instr, vmask_string);
        sources = {"Source operands:\n", s1_string, s2_string, s3_string, vmask_string};
    endfunction : print_sources


