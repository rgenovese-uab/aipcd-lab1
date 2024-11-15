//----------------------------------------------------------------------
// Project       : standalone_core_dv_env
// Unit          : types
// File          : types.sv
//----------------------------------------------------------------------
// Created by    : Prashant Ahuja (BSC)
// Creation Date : 18 Nov 2022 
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_object. This class 
//                 provides dut_state and rf_state for scoreboard comparision. 
//----------------------------------------------------------------------
`ifndef TYPES_SV
`define TYPES_SV

package core_uvm_types_pkg;
import uvm_pkg::*;
`include "uvm_macros.svh"

typedef longint unsigned    uint64_t;
typedef int unsigned        uint32_t;
typedef byte unsigned       uint8_t;

//These parameters will be later defined in EPI_pkg
typedef longint unsigned vec_els_t [0:dut_pkg::MAX_64BIT_BLOCKS-1];
typedef longint unsigned mem_addrs_t [0:dut_pkg::MAX_VLEN/dut_pkg::MIN_SEW-1];
typedef longint unsigned mem_elements_t [0:dut_pkg::MAX_VLEN/dut_pkg::MIN_SEW-1];
typedef logic [dut_pkg::MAX_VLEN/dut_pkg::MIN_SEW-1:0] mask_els;


typedef struct {
    uint8_t  trap_illegal;
    uint64_t mcause;
    uint64_t scause;
    uint32_t vstart;
    uint32_t vl;
    uint8_t  vxrm;
    uint8_t  vlmul;
    uint8_t  vsew;
    uint8_t  vill;
    uint8_t  vxsat;
    uint8_t  vta;
    uint8_t  vma;
    uint8_t  frm;
    uint8_t  fflags;
    uint64_t mstatus;
    uint64_t misa;
} csr_t;

typedef struct {
    uint64_t core_id;
    uint64_t pc;
    uint32_t instr;
    string   disasm;
    uint8_t  dst_valid;
    uint8_t  dst_num;
    uint64_t dst_value;
    uint8_t  src1_valid;
    uint8_t  src1_num;
    uint64_t src1_value;
    uint8_t  src2_valid;
    uint8_t  src2_num;
    uint64_t src2_value;
    uint64_t vaddr;
    uint64_t paddr;
    uint64_t store_data;
    uint64_t store_mask;
    csr_t    csr;
    uint8_t  exc_bit;
} iss_scalar_state_t;

typedef struct {
    vec_els_t old_vd;
    vec_els_t vd;
    vec_els_t vs1;
    vec_els_t vs2;
    vec_els_t vs3;
    vec_els_t vmask;
    mem_elements_t      mem_elements;
    mem_addrs_t         mem_addrs;
} iss_rvv_state_t;


//[TODO] Merge with below
typedef struct {
    vec_els_t vd;
    logic [dut_pkg::MAX_VLEN/dut_pkg::MIN_SEW-1:0] mask_data;
    longint unsigned    scalar_dest;
    int                 ignore;
    bit                 illegal;
    logic [dut_pkg::FFLAG_WIDTH-1:0]      fflags;
    logic                                           vxsat;
    logic [dut_pkg::SB_WIDTH-1:0] sb_id;
} dut_rvv_state_t;

typedef struct
{
    uint64_t    core_id;
    uint64_t    pc;
    uint64_t    ins;
    uint64_t    dst_value;
    uint64_t    dst_valid;
    csr_t       csr;
    bit         exc_bit;
    uint64_t    exc_cause;
    uint64_t    mem_addr;
    uint64_t    stored_value;
} dut_scalar_state_t;

typedef struct {
    dut_scalar_state_t scalar_state;
    dut_rvv_state_t rvv_state;
} dut_state_t;

typedef struct {
    iss_scalar_state_t scalar_state;
    iss_rvv_state_t rvv_state;
} iss_state_t;

typedef struct{
    logic           ready;
    logic [23:0]    addr;
    logic           valid;
} brom_req_t;

typedef struct{
    logic           valid;
    logic [31:0]    bits_data;
} brom_resp_t;

typedef struct packed {
    bit [7:0][31:0] m_irq_enable;
    bit [7:0][31:0] s_irq_enable;
} plic_enable_t;


class scoreboard_results_t extends uvm_object;
`uvm_object_utils(scoreboard_results_t)

    dut_state_t dut_state;
    iss_state_t iss_state;

    function new(string name = "scoreboard_results_t");
        super.new(name);
    endfunction : new


endclass


endpackage
`endif
