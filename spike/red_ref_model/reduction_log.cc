#include "reduction_log.h"

#include <iomanip>
#include <iostream>
#include <sstream>

void reduction_log::set_path(string path) {
    this->path = path;
    if (this->path.size() <= 0) {
        this->path = "build/reduction.log";
    } else {
        if (this->path.back() == '/')
            this->path.append("reduction.log");
        else
            this->path.append("/reduction.log");
    }
    remove(this->path.c_str());
}

void reduction_log::add_ins_info(uint64_t scalar, uint64_t hex_ins, instr ins,
                                 uint32_t vl, uint32_t sew) {
    ins_info = "PC: " + to_hex(ins.pc, 8) +
                "\nInstruction: " + to_hex(hex_ins, 8) +
               "\nScalar: " + to_hex(scalar, sew / 4) +
               "\nVLEN: " + to_hex(vl, 8) + "\nSEW: " + to_hex(sew, 8);
    if (ins.is_fp) {
        if (ins.is_widening) {
            switch (ins.funct6) {
                case vfwredsum:
                    ins_info += "\nReduction name: vfwredusum";
                    break;
                case vfwredosum:
                    ins_info += "\nReduction name: vfwredosum";
                    break;

                default:
                    break;
            }
        } else {
            switch (ins.funct6) {
                case vfredsum:
                    ins_info += "\nReduction name: vfredusum";
                    break;
                case vfredosum:
                    ins_info += "\nReduction name: vfredosum";
                    break;
                case vfredmin:
                    ins_info += "\nReduction name: vfredmin";
                    break;
                case vfredmax:
                    ins_info += "\nReduction name: vfredmax";
                    break;
                default:
                    break;
            }
        }
    } else {
        if (ins.is_widening) {
            switch (ins.funct6) {
                case vwredsum:
                    ins_info += "\nReduction name: vwredsum";
                    break;
                case vwredsumu:
                    ins_info += "\nReduction name: vwredsumu";
                    break;
                default:
                    break;
            }
        } else {
            switch (ins.funct6) {
                case vredsum:
                    ins_info += "\nReduction name: vredsum";
                    break;
                case vredand:
                    ins_info += "\nReduction name: vredand";
                    break;
                case vredor:
                    ins_info += "\nReduction name: vredor";
                    break;
                case vredxor:
                    ins_info += "\nReduction name: vredor";
                    break;
                case vredminu:
                    ins_info += "\nReduction name: vredminu";
                    break;
                case vredmin:
                    ins_info += "\nReduction name: vredmin";
                    break;
                case vredmaxu:
                    ins_info += "\nReduction name: vredmaxu";
                    break;
                case vredmax:
                    ins_info += "\nReduction name: vredmax";
                    break;
                default:
                    break;
            }
        }
    }
    if (ins.is_masking) ins_info += " (masked)";
    else ins_info += " (unmasked)";
    cout << ins_info << endl;
}

string reduction_log::to_hex(uint64_t a, uint64_t size) {
    stringstream retc;
    retc << "0x" << hex << setw(size) << setfill('0') << a;
    return retc.str();
}

void reduction_log::set_vs(vector<uint8_t> &vs, uint32_t b_sew, uint32_t vl) {
    this->vs = "\n\nVS2: \n";
    for (int i = 0; i < vl * b_sew; i += b_sew) {
        this->vs += to_hex(get_elem(i, vs, b_sew), b_sew * 2) + " ";
    }
}

uint64_t reduction_log::get_elem(int start, const vector<uint8_t> &v,
                                 uint32_t sew) {
    uint64_t elem = 0;
    for (int i = 0; i < sew; ++i) {
        elem |= (uint64_t(v[i + start]) << (i * 8));
    }
    return elem;
}

void reduction_log::set_vmask(vector<uint8_t> &vmask, uint32_t b_sew,
                              uint32_t vl) {
    this->vmask = "\n\nVMASK: \n";
    for (int i = 0; i < vl * b_sew; i += b_sew) {
        this->vmask += to_hex(get_elem(i, vmask, b_sew), b_sew * 2) + " ";
    }
}

void reduction_log::add_lane_log(uint64_t res, int lane, uint32_t b_sew) {
    log += "\nLANE " + to_string(lane) + ": " + to_hex(res, b_sew * 2);
}

void reduction_log::add_ord_log(uint64_t val, uint32_t b_vsew) {
    log += to_hex(val, b_vsew * 2) + " ";
}

void reduction_log::write_log() {
    out.open(path, ios::app);
    if (out.is_open()) {
        out << ins_info << vs << endl << vmask << endl << log << "\n\n";
        for (int i = 0; i < unord_log_lane.size(); ++i) {
            out << "LANE " << i << ":\n" << unord_log_lane[i] << endl;
        }
        out << "\n";
        out << "Final accums per lane:\n";
        for (int i = 0; i < unord_log_lane_accum.size(); ++i) {
            out << "LANE " << i << ":\n" << unord_log_lane_accum[i] << endl;
        }
        out << "Final result: " << final_res << "\n";
        out << "----\n\n";

    }
    out.close();
    clear();
}

void reduction_log::add_ord_mask_log(uint64_t val, uint32_t b_vsew) {
    log += "(" + to_hex(val, b_vsew * 2) + ") ";
}

void reduction_log::add_unord_lane_log(uint64_t val, uint32_t b_vsew,
                                       uint64_t lane_num, bool masking) {
    if (lane_num + 1 > unord_log_lane.size())
        unord_log_lane.resize(lane_num + 1);
    if (masking)
        unord_log_lane[lane_num] += "(" + to_hex(val, b_vsew * 2) + ") ";
    else
        unord_log_lane[lane_num] += to_hex(val, b_vsew * 2) + " ";
}

void reduction_log::add_unord_lane_accum_log(uint64_t val, uint32_t b_vsew,
                                       uint64_t lane_num, uint64_t accum_num) {
    if (lane_num + 1 > unord_log_lane_accum.size())
        unord_log_lane_accum.resize(lane_num + 1);
    unord_log_lane_accum[lane_num] += "accum[" + to_hex(accum_num,1) + "]=" + to_hex(val, b_vsew * 2) + " ";
}

void reduction_log::add_final_res_log(uint64_t val, uint32_t b_vsew) {
    final_res = to_hex(val, b_vsew * 2);
}

void reduction_log::clear() {
    ins_info.clear();
    log.clear();
    vs.clear();
    vmask.clear();
    unord_log_lane.clear();
}
