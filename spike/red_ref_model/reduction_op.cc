#include "reduction_op.h"
#include "softfloat.h"

#include <iomanip>
#include <iostream>
#include <cmath>
#include <sstream>

string to_hex(uint64_t a, uint64_t size) {
    stringstream retc;
    retc << "0x" << hex << setw(size) << setfill('0') << a;
    return retc.str();
}

void reduction_op::v64_to_v8(const uint64_t *v64, uint8_t *v8, uint32_t vl, int sew) {
    uint64_t v8_count = 0;
    for (uint64_t i = 0; i < ((vl + (8 / sew) - 1) / (8 / sew)); ++i) {
        for (int j = 0; j < 8 and v8_count < vl * sew; ++j) {
            v8[v8_count] = ((v64[i] >> (j * 8)) % 256);
            ++v8_count;
        }
    }
}


void reduction_op::reduction_setup(uint8_t vsew, uint32_t vl, uint64_t scalar,
                                   const uint8_t *vs, const uint8_t *mask,
                                   const uint32_t ins, const uint32_t frm,
                                   int verb_lvl, int act_verb_lvl, char tree_merge_enable, const uint64_t pc) {
    this->vsew = vsew;
    this->b_vsew = (vsew / 8);
    this->vl = vl;
    this->vs = vector<uint8_t>(vs, vs + (vl * b_vsew));
    this->vmask = vector<uint8_t>(mask, mask + (vl * b_vsew));
    this->frm = frm;
    this->verb_lvl = verb_lvl;
    this->act_verb_lvl = act_verb_lvl;
    red_ins.is_masking = !(0x01 & (ins >> MASK_BIT));
    red_ins.is_widening = ((ins >> WIDEN_BITS) == 3);
    red_ins.funct3 = 0x7 & (ins >> FUNCT3);
    red_ins.funct6 = ins >> FUNCT6;
    red_ins.is_fp = red_ins.funct3 == 1;
    red_ins.is_unordered = not(red_ins.is_fp && (red_ins.funct6 == vfredosum or
                                                 red_ins.funct6 == vfwredosum));
    red_ins.is_unsigned =
        (not red_ins.is_fp and
         ((red_ins.is_widening and red_ins.funct6 == vwredsumu) or
          (not red_ins.is_widening and
           (red_ins.funct6 == vredmaxu or red_ins.funct6 == vredminu))));
    if (red_ins.is_widening) {
        this->scalar =
            (vsew == 32) ? scalar : (scalar % (uint64_t(1) << (vsew * 2)));
    } else {
        this->scalar = (vsew == 64) ? scalar : (scalar % (uint64_t(1) << vsew));
    }
    red_ins.pc = pc;
    red_log.add_ins_info(this->scalar, ins, red_ins, vl, vsew);
    red_log.set_vs(this->vs, b_vsew, vl);
    if (red_ins.is_masking) red_log.set_vmask(this->vmask, b_vsew, vl);

    fprintf(stderr, "[Reduction Reference Model] Widenning: %d ; Masked: %d ; SEW: %d ; VL: %d\n", red_ins.is_widening, red_ins.is_masking, vsew, vl);

    this->tree_merge_enable_intra = (tree_merge_enable & 0x1) && !red_ins.is_widening;
    this->tree_merge_enable_inter = (tree_merge_enable & 0x2) && !red_ins.is_masking;
}

uint64_t reduction_op::do_reduction() {
    uint64_t ret = 0;
    if (red_ins.is_fp) softfloat_exceptionFlags = 0;
    fflags = 0;
    if (red_ins.is_widening)
        accum_num = 1;
    else
        accum_num = red_ins.is_fp ? accum_num_fp : accum_num_int;
    if (red_ins.is_unordered) {
        ret = reduction_unord();
    } else {
        ret = reduction_ord();
    }
    if (act_verb_lvl == verb_lvl) {
        red_log.write_log();
    }
    
    return ret;
}

uint64_t reduction_op::reduction_ord() {
    elem ret;
    ret.val = scalar;
    for (uint64_t i = 0; i < vl * b_vsew; i += b_vsew) {
        if (red_ins.is_masking) {
            if (get_mask_bit(i / b_vsew, vmask)) {
                red_log.add_ord_log(get_elem(i, vs), b_vsew);
                ret.val =
                    reduction_operation(ret.val, get_elem(i, vs), true, false);
            }
        } else {
            red_log.add_ord_mask_log(get_elem(i, vs), b_vsew);
            ret.val =
                reduction_operation(ret.val, get_elem(i, vs), true, false);
        }
    }
    return ret.val;
}

uint64_t reduction_op::reduction_unord() {
    vector<lane> lanes(lane_num);
    elem ret;
    uint64_t counter = 0;
    init_lanes(lanes);
    while (counter < vl * b_vsew) {
        for (int i = 0; i < lane_num and counter < vl * b_vsew; ++i) {
            int j = lanes[i].act_accum;
            for (int k = 0; k < (64 / vsew) and counter < vl * b_vsew; ++k) {
                int aux = (red_ins.is_widening) ? (k / 2) : k;
                if (red_ins.is_masking) {
                    if (get_mask_bit(counter / b_vsew, vmask)) {
                        red_log.add_unord_lane_log(get_elem(counter, vs),
                                                   b_vsew, i, false);
                        if (lanes[i].accums[j][aux].init) {
                            lanes[i].accums[j][aux].value.val =
                                reduction_operation(
                                    lanes[i].accums[j][aux].value.val,
                                    get_elem(counter, vs), true, false);
                        } else {
                            init_accum_part(lanes[i].accums[j][aux],
                                            get_elem(counter, vs));
                        }
                    } else {
                        red_log.add_unord_lane_log(get_elem(counter, vs),
                                                   b_vsew, i, true);
                    }
                } else {
                    red_log.add_unord_lane_log(get_elem(counter, vs), b_vsew, i,
                                               false);
                    if (lanes[i].accums[j][aux].init) {
                        lanes[i].accums[j][aux].value.val = reduction_operation(
                            lanes[i].accums[j][aux].value.val,
                            get_elem(counter, vs), true, false);
                    } else {
                        init_accum_part(lanes[i].accums[j][aux],
                                        get_elem(counter, vs));
                    }
                }
                counter += b_vsew;
            }
            lanes[i].act_accum = (lanes[i].act_accum + 1) % accum_num;
        }
    }
    for (int i = 0; i < lane_num; i++) {
        for (int j = 0; j < accum_num; ++j) {
            uint64_t aux_accum;
            aux_accum = 0;
            for (int k = 0; k < 8 / b_vsew; k++) {
                if (lanes[i].accums[j][k].init) {
                    aux_accum |= lanes[i].accums[j][k].value.val << k * 8;
                }
            }
            red_log.add_unord_lane_accum_log(aux_accum, b_vsew, i, j);
        }
    }
    merge_accums(lanes);
    red_log.add_final_res_log(adjust_to_sew(lanes[0].accums[0][0].value.val), b_vsew);
    return adjust_to_sew(lanes[0].accums[0][0].value.val);
}

uint64_t reduction_op::reduction_operation(uint64_t elem1, uint64_t elem2,
                                           bool accum1, bool accum2) {
    if (red_ins.is_fp) {
        elem ret, elem;
        ret.val = elem1;
        elem.val = elem2;
        softfloat_roundingMode = frm;
        if (red_ins.is_widening) {
            if (not accum1) ret.double_val = f32_to_f64(ret.float_val);
            if (not accum2) elem.double_val = f32_to_f64(elem.float_val);
            switch (red_ins.funct6) {
                case vfwredsum:
                    ret.double_val = f64_add(ret.double_val, elem.double_val);
                    break;
                case vfwredosum:
                    ret.double_val = f64_add(ret.double_val, elem.double_val);
                    break;
                default:
                    break;
            }
        } else {
            if (vsew == 32) {
                switch (red_ins.funct6) {
                    case vfredsum:
                        ret.float_val = f32_add(ret.float_val, elem.float_val);
                        break;
                    case vfredosum:
                        ret.float_val = f32_add(ret.float_val, elem.float_val);
                        break;
                    case vfredmin:
                        ret.float_val = f32_min(ret.float_val, elem.float_val);
                        break;
                    case vfredmax:
                        ret.float_val = f32_max(ret.float_val, elem.float_val);
                    default:
                        break;
                }
            }
            if (vsew == 64) {
                switch (red_ins.funct6) {
                    case vfredsum:
                        ret.double_val =
                            f64_add(ret.double_val, elem.double_val);
                        break;
                    case vfredosum:
                        ret.double_val =
                            f64_add(ret.double_val, elem.double_val);
                        break;
                    case vfredmin:
                        ret.double_val =
                            f64_min(ret.double_val, elem.double_val);
                        break;
                    case vfredmax:
                        ret.double_val =
                            f64_max(ret.double_val, elem.double_val);
                    default:
                        break;
                }
            }
        }
        fflags |= softfloat_exceptionFlags;
        return ret.val;
    } else {
        if (red_ins.is_widening) {
            switch (red_ins.funct6) {
                case vwredsum:
                    return (((accum1) ? elem1 : sign_extend(elem1, vsew)) +
                            ((accum2) ? elem2 : sign_extend(elem2, vsew)));
                case vwredsumu:
                    return elem1 + elem2;
            }
        } else {
            switch (red_ins.funct6) {
                case vredsum:
                    return adjust_to_sew(elem1 + elem2);
                case vredand:
                    return elem1 & elem2;
                case vredor:
                    return elem1 | elem2;
                case vredxor:
                    return elem1 ^ elem2;
                case vredminu:
                    return ((elem1 <= elem2) ? elem1 : elem2);
                case vredmin:
                    return adjust_to_sew((((long)sign_extend(elem1, vsew) <=
                                           (long)sign_extend(elem2, vsew))
                                              ? elem1
                                              : elem2));
                case vredmaxu:
                    return ((elem1 <= elem2) ? elem2 : elem1);
                case vredmax:
                    return adjust_to_sew((((long)sign_extend(elem1, vsew) <=
                                           (long)sign_extend(elem2, vsew))
                                              ? elem2
                                              : elem1));
            }
        }
    }
    return -1;
}

uint64_t reduction_op::get_elem(int start, const vector<uint8_t> &v) {
    uint64_t elem = 0;
    for (int i = 0; i < b_vsew; ++i) {
        elem |= (uint64_t(v[i + start]) << (i * 8));
    }
    return elem;
}

uint8_t reduction_op::get_mask_bit(int i, const vector<uint8_t> &v) {
    uint8_t mask = 0;
    mask = (v[i / 8] >> (i % 8)) & 1;
    return mask;
}

void reduction_op::init_lanes(vector<lane> &lanes) {
    int sew = get_dec_result_sew();
    for (int i = 0; i < lane_num; ++i) {
        lanes[i].accums = vector<accum>(accum_num, accum(64 / sew));
        lanes[i].act_accum = 0;
        for (int j = 0; j < accum_num; ++j) {
            for (int k = 0; k < (64 / sew); ++k) {
                lanes[i].accums[j][k].init = false;
                lanes[i].accums[j][k].value.val = 0;
            }
        }
    }
    lanes[0].accums[0][0].value.val = scalar;
    lanes[0].accums[0][0].init = true;
    red_log.add_unord_lane_log(scalar, b_vsew, 0, false);
}

uint64_t reduction_op::adjust_to_sew(uint64_t elem) {
    int size = red_ins.is_widening ? (2 * b_vsew) : b_vsew;
    uint64_t ret = 0xFFFFFFFFFFFFFFFF;
    ret >>= ((8 - size) * 8);
    ret &= elem;
    return ret;
}

uint64_t reduction_op::sign_extend(uint64_t a, int size) {
    if (vsew < 64) {
        uint64_t mask = 1;
        mask <<= (size - 1);
        if ((a & mask) != 0) {
            mask = -1;
            mask <<= size;
            return (a | mask);
        }
    }
    return a;
}

void reduction_op::intralane_merge(lane *lane) {
    if (tree_merge_enable_intra) {
        lane->accums[0] = *intralane_branch_op(0, accum_num - 1, lane);
    } else {
        for (int i = 1; i < accum_num; ++i) {
           operate_accums(&lane->accums[0], &lane->accums[i]);
        }
    }
}

accum* reduction_op::intralane_branch_op(int index_begin, int index_end, lane *lane_a) {
    if (index_begin == index_end) {
        // Base case for odd case
        return &(lane_a->accums[index_begin]);
    } else if (index_begin == (index_end - 1)) {
        operate_accums(&(lane_a->accums[index_begin]),
                       &(lane_a->accums[index_end]));
        return &(lane_a->accums[index_begin]);
    } else {
        accum* accum1 = intralane_branch_op(index_begin,
                                            index_begin + ((index_end - index_begin) / 2),
                                            lane_a);
        accum* accum2 = intralane_branch_op((index_begin + ((index_end - index_begin) / 2) + 1),
                                            index_end,
                                            lane_a);
        operate_accums(accum1, accum2);
        return accum1;
    }
}

void reduction_op::operate_accums(accum* accum1, accum* accum2) {
    int sew = get_dec_result_sew();
    for (int i = 0; i < (64 / sew); ++i) {
        if (accum1->at(i).init and accum2->at(i).init) {
            accum1->at(i).value.val =
                reduction_operation(
                    accum1->at(i).value.val,
                    accum2->at(i).value.val, true, true);
            accum1->at(i).init = true;
        } else if (accum1->at(i).init and !accum2->at(i).init) {
            accum1->at(i).value.val = accum1->at(i).value.val;
            accum1->at(i).init = true;
        } else if (!accum1->at(i).init and accum2->at(i).init) {
            accum1->at(i).value.val = accum2->at(i).value.val;
            accum1->at(i).init = true;
        }
    }
    return;
}

void reduction_op::merge_accums(vector<lane> &lane) {
    if (!tree_merge_enable_inter) {
        interlane_merge(lane);
    } else {
        uint32_t necessary_lanes = (vl / (64/vsew)) + ((vl % (64/vsew)) != 0);
        if (necessary_lanes < lane_num) {
            interlane_merge(lane);
        } else {
            tree_interlane_merge(lane);
        }
    }
}

void reduction_op::interlane_merge(vector<lane> &lane_a) {
    for (int i = 0; i < lane_num; i++) {
        intralane_merge(&lane_a[i]);
        fold(lane_a[i].accums[0], get_dec_result_sew());
        red_log.add_lane_log(lane_a[i].accums[0][0].value.val, i, b_vsew);
        if (i != 0) {
            if (lane_a[i].accums[0][0].init) {
                if (lane_a[0].accums[0][0].init) {
                    lane_a[0].accums[0][0].value.val = reduction_operation(
                        lane_a[0].accums[0][0].value.val,
                        lane_a[i].accums[0][0].value.val, true, true);
                }
            }
        }

    }
}

void reduction_op::tree_interlane_merge(vector<lane> &lane_a) {
    lane_a[0].accums[0][0].value.val = tree_merge(0, lane_num - 1, lane_a)->accums[0][0].value.val;
}

lane* reduction_op::tree_merge(int index_begin, int index_end, vector<lane> &lane_a) {
    if (index_begin == index_end) {
        // Base case for odd case
        intralane_merge(&lane_a[index_begin]);
        fold(lane_a[index_begin].accums[0], get_dec_result_sew());
        return &lane_a[index_begin];
    } else if (index_begin == (index_end - 1)) {
        intralane_merge(&lane_a[index_begin]);
        intralane_merge(&lane_a[index_end]);
        fold(lane_a[index_begin].accums[0], get_dec_result_sew());
        fold(lane_a[index_end].accums[0], get_dec_result_sew());
        if (lane_a[index_begin].accums[0][0].init) {
            if (lane_a[index_end].accums[0][0].init) {
                lane_a[index_begin].accums[0][0].value.val =
                    reduction_operation(lane_a[index_begin].accums[0][0].value.val,
                                        lane_a[index_end].accums[0][0].value.val,
                                        true, true);
            }
        } else {
            if (lane_a[index_end].accums[0][0].init) {
                lane_a[index_begin].accums[0][0].value.val =
                    lane_a[index_end].accums[0][0].value.val;
                lane_a[index_begin].accums[0][0].init = true;
            }
        }
        return &lane_a[index_begin];
    } else {
        lane* lane1 = tree_merge(index_begin,
                                 index_begin + ((index_end - index_begin) / 2),
                                 lane_a);
        lane* lane2 = tree_merge(index_begin + ((index_end - index_begin) / 2) + 1,
                                 index_end,
                                 lane_a);
        if (lane1->accums[0][0].init) {
            if (lane2->accums[0][0].init) {
                lane1->accums[0][0].value.val =
                    reduction_operation(lane1->accums[0][0].value.val,
                                        lane2->accums[0][0].value.val,
                                        true, true);
            }
        } else {
            if (lane2->accums[0][0].init) {
                lane1->accums[0][0].value.val =
                    lane2->accums[0][0].value.val;
                    lane1->accums[0][0].init = true;
            }
        }
        return lane1;
    }
}

void reduction_op::fold(accum &a, int sew) {
    int size = 64 / sew;
    while (size > 1) {
        for (int i = 0; i < size / 2; i++) {
            if (a[i].init and a[i + (size / 2)].init) {
                a[i].value.val = reduction_operation(
                    a[i].value.val, a[i + (size / 2)].value.val, true, true);
            } else if (not a[i].init and a[i + (size / 2)].init) {
                a[i].value.val = a[i + (size / 2)].value.val;
                a[i].init = true;
            }
        }
        size >>= 1;
    }
}

void reduction_op::set_up_log(string path) { red_log.set_path(path); }

void reduction_op::init_accum_part(accum_part &a, uint64_t val) {
    elem aux;
    aux.val = val;
    if ((red_ins.is_widening and (not red_ins.is_unsigned))) {
        if (red_ins.is_fp) {
            a.value.double_val = f32_to_f64(aux.float_val);
        } else {
            a.value.val = sign_extend(aux.val, vsew);
        }
    } else {
        a.value.val = aux.val;
    }
    a.init = true;
}

int reduction_op::get_dec_result_sew() {
    return red_ins.is_widening ? (vsew * 2) : vsew;
}
