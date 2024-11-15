//----------------------------------------------------------------------
// Project       : MEEP
// Unit          : core_dcache_driver
// File          : core_dcache_driver.sv
//----------------------------------------------------------------------
// Created by    : Ivan Diaz (BSC)
// Creation Date : 22 Nov 2022
//----------------------------------------------------------------------
// Description   : This class is extended from uvm_object. This class
//                 basically emulates the behaviour of the dcache, and
//                 randomizes various aspects of the response to the core
//                 to hit several corner cases.
//----------------------------------------------------------------------
`ifndef CORE_DCACHE_REF_MODEL_SV
`define CORE_DCACHE_REF_MODEL_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
import sargantana_hpdc_pkg::*;
import hpdcache_pkg::*;


class core_dcache_ref_model extends uvm_object;
    `uvm_object_utils(core_dcache_ref_model)

    localparam  ADDR_WIDTH  = 64;
    localparam  NB_BYTE     = 8;
    localparam  HPDCACHE_WORD_WIDTH_LOG = 6;

    typedef bit [ADDR_WIDTH - 1:0] mem_addr_t;

    // *** Helper Functions ***
    function automatic hpdcache_word_t hpdcache_get_req_word(input hpdcache_req_addr_t addr);
        return addr[$clog2(HPDCACHE_WORD_WIDTH/8) +: HPDCACHE_WORD_IDX_WIDTH];
    endfunction

    function automatic hpdcache_req_addr_t hpdcache_req_addr(input hpdcache_req_t req);
        return {req.addr_tag, req.addr_offset};
    endfunction

    // Queue of requests to respond
    uvm_queue #(core_dcache_trans) req_queue;
    // Dcache virtual interface
    virtual interface dcache_if dc_dr_if;
    // Main memory model of the environment
    core_mem_model#(64, 128) m_mem_model;
    // Separate variable for data required for AMO operation, out data is read from aligned addr while amo_data is not
    logic signed [HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS-1:0] amo_data = 0;
    logic signed [HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS-1:0] req_amo_data = 0;
    // ISS wrapper for the translation functions
    core_iss_wrapper m_iss;
    // List of reserved addresses
    mem_addr_t reserved_addresses[$];
    //--------------------------------------------------
    // Ref Model Internal signals that will be
    // used to set the actual signals with drive_signals
    //--------------------------------------------------
    logic dcache_req_ready_q[HPDCACHE_NREQUESTERS-1:0];
    logic dcache_resp_valid_q;
    hpdcache_rsp_t dcache_resp_q;
    logic wbuf_empty_q;

    function new(string name="core_dcache_model");
        super.new(name);
        m_mem_model = core_mem_model#(64, 128)::create_instance();
        req_queue = new();
    endfunction : new

    // Adds a request to the request queue and sets the correct values to the transaction.
    task request(core_dcache_rand_trans rand_req, core_dcache_trans req);
        req.ttl = rand_req.ttl;
        //TODO: check if some forwarding logic can be introduced to have ttl>1 in store reuqests
        if (req.dcache_req.op != HPDCACHE_REQ_LOAD) // Only allow randomization of response time if its a load
            req.ttl = 0; // TODO: check if it should be 1 or 0
        req.error = rand_req.error;
        `uvm_info("DCACHE_REF_MODEL",
            $sformatf("Received request with addr: %h sid:%h tid:%h, adding it to queue with ttl %d and error %d.", 
            hpdcache_req_addr(req.dcache_req),
                req.dcache_req.sid,
                req.dcache_req.tid,
                req.ttl,
                req.error),
            UVM_DEBUG)
        serve_request(req);
        req_queue.push_back(req);
    endtask : request

    // Check the requests in the queue and if ready to be served, serve them
    task check_requests();
        core_dcache_trans req;
        int del_index = -1;
        bit responded = 0;
        `uvm_info("DCACHE_REF_MODEL",
            $sformatf("Requests on queue: %d", req_queue.size()),
            UVM_DEBUG)
        for (int i = req_queue.size() - 1; i >= 0; i--) begin
            req = req_queue.get(i);
            if (req.ttl == 0) begin // If we haven't responded to any request this cycle and the one we are looking is ready
                if (req.error) begin
                    `uvm_info("DCACHE_REF_MODEL", "Responding nack", UVM_DEBUG)
                    respond_error(req);
                    break;
                end
                if (responded == 0) begin
                    `uvm_info("DCACHE_REF_MODEL",
                        "Responding normal request, no request responded yet.",
                        UVM_DEBUG)
                    respond(req);
                    req_queue.delete(i);
                    responded = 1;
                end
            end else begin
                if (req.ttl > 0) begin
                    req.ttl = req.ttl - 1;
                end
            end
        end
    endtask : check_requests

    // Do the actual load or store operation
    task serve_request(core_dcache_trans req);
        if (req.dcache_req.op == HPDCACHE_REQ_LOAD) begin // It's a load
            load(req);
        end else if (req.dcache_req.op == HPDCACHE_REQ_STORE) begin // It's a store
            // TODO: confirm if store needs a response
            store(req);
        end else if (req.dcache_req.op == HPDCACHE_REQ_AMO_LR) begin // It's a load reserved
            load(req);
            `uvm_info("DCACHE_REF_MODEL",
                $sformatf("Pushing address 0x%h into reserved addresses list.",
                    hpdcache_req_addr(req.dcache_req)),
                UVM_DEBUG)
            reserved_addresses.push_back(hpdcache_req_addr(req.dcache_req));
        end else if (req.dcache_req.op == HPDCACHE_REQ_AMO_SC) begin // It's a store conditional
            logic signed [HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS-1:0] aux_line;
            hpdcache_req_addr_t aux_addr;
            aux_line = '0;
            aux_addr = hpdcache_req_addr(req.dcache_req);
            aux_line[aux_addr[0 +: $clog2(HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS/8)] * 8] = 1'b1; // Set the LSB of the byte indicated by the address
            req.dcache_resp.rdata[hpdcache_get_req_word(hpdcache_req_addr(req.dcache_req))]  = aux_line[hpdcache_get_req_word(hpdcache_req_addr(req.dcache_req)) * HPDCACHE_WORD_WIDTH];
            foreach (reserved_addresses[i]) begin
                if (reserved_addresses[i] == hpdcache_req_addr(req.dcache_req)) begin
                    `uvm_info("DCACHE_REF_MODEL",
                        "Found matching address for store conditional.",
                        UVM_DEBUG)
                    req.dcache_resp.rdata = 0;
                    store(req);
                    break;
                end
            end
            reserved_addresses.delete();
        end else if  (req.dcache_req.op inside {HPDCACHE_REQ_AMO_SWAP, HPDCACHE_REQ_AMO_AND,
                                                HPDCACHE_REQ_AMO_ADD, HPDCACHE_REQ_AMO_OR,
                                                HPDCACHE_REQ_AMO_XOR, HPDCACHE_REQ_AMO_MIN,
                                                HPDCACHE_REQ_AMO_MAX, HPDCACHE_REQ_AMO_MINU,
                                                HPDCACHE_REQ_AMO_MAXU}) begin // It's amo


            load_amo(req);
            get_req_amo_data(req);
            `uvm_info("debug_respond_amo",
                $sformatf("Before: req_amo_data: 0x%h, amo_data: 0x%h", req_amo_data, amo_data),
                UVM_DEBUG)
            case (req.dcache_req.op)
                HPDCACHE_REQ_AMO_SWAP: // AMOSWAP
                    begin
                        store_amo(req);
                    end
                HPDCACHE_REQ_AMO_ADD: // AMOADD
                    begin
                        amo_sign_extend(req);
                        req_amo_data = amo_data + req_amo_data;
                        store_amo(req);
                    end
                HPDCACHE_REQ_AMO_XOR: // AMOXOR
                    begin
                        amo_sign_extend(req);
                        req_amo_data = amo_data ^ req_amo_data;
                        store_amo(req);
                    end
                HPDCACHE_REQ_AMO_AND: // AMOAND
                    begin
                        amo_sign_extend(req);
                        req_amo_data = amo_data & req_amo_data;
                        store_amo(req);
                    end
                HPDCACHE_REQ_AMO_OR: // AMOOR
                    begin
                        amo_sign_extend(req);
                        req_amo_data = amo_data | req_amo_data;
                        store_amo(req);
                    end
                HPDCACHE_REQ_AMO_MIN: // AMOMIN
                    begin
                        amo_sign_extend(req);
                        req_amo_data = ((amo_data <= req_amo_data) ? amo_data : req_amo_data);
                        store_amo(req);
                    end
                HPDCACHE_REQ_AMO_MAX: // AMOMAX
                    begin
                        amo_sign_extend(req);
                        req_amo_data = ((amo_data >= req_amo_data) ? amo_data : req_amo_data);
                        store_amo(req);
                    end
                HPDCACHE_REQ_AMO_MINU: // AMOMINU
                    begin
                        amo_sign_extend(req);
                        req_amo_data = (($unsigned(amo_data) <= $unsigned(req_amo_data)) ? amo_data : req_amo_data);
                        store_amo(req);
                    end
                HPDCACHE_REQ_AMO_MAXU: // AMOMAXU
                    begin
                        amo_sign_extend(req);
                        req_amo_data = (($unsigned(amo_data) >= $unsigned(req_amo_data)) ? amo_data : req_amo_data);
                        store_amo(req);
                    end
                default:
                    `uvm_fatal("DCACHE_REF_MODEL",
                        $sformatf("Core sent invalid memory op: %d", req.dcache_req.op))
            endcase
            `uvm_info("debug_respond_amo", $sformatf("After: req_amo_data: 0x%h", req_amo_data), UVM_DEBUG)
        end
        else begin
            `uvm_fatal("DCACHE_REF_MODEL",
                $sformatf("Core sent invalid memory op: %d",
                req.dcache_req.op))
        end
    endtask : serve_request

    // Set the values of the output signals
    task respond(core_dcache_trans req);
        dcache_resp_valid_q = 1;
        dcache_resp_q.tid = req.dcache_req.tid;
        dcache_resp_q.sid = req.dcache_req.sid;
        `uvm_info("DCACHE_REF_MODEL",
            $sformatf("Responding to request with addr: %h sid:%h tid:%h",
                hpdcache_req_addr(req.dcache_req),
                req.dcache_req.sid,
                req.dcache_req.tid),
            UVM_DEBUG)
        dcache_resp_q.rdata = req.dcache_resp.rdata;
    endtask : respond

    // Drive the signals in case of error
    task respond_error(core_dcache_trans req);
        dcache_resp_valid_q = 0;
        dcache_resp_q.tid = req.dcache_req.tid;
        dcache_resp_q.sid = req.dcache_req.sid;
        dcache_resp_q.error = 1;
    endtask : respond_error

    // Set up the basic signals for the dcache interface
    task set_signals();
        if (dc_dr_if == null) begin
           `uvm_fatal("DCACHE_REF_MODEL", "Can't drive signals: no interface available.")
        end
        dcache_req_ready_q = '{1,1}; //TODO; implement ready decoupled logic if needed, for now ready array is all 1s or all 0s
        dcache_resp_valid_q = 0;
        wbuf_empty_q = 1; // TODO: for now always 1, randomize this, maybe add it in the rand_trans class, pending
        dcache_resp_q = '0;
    endtask : set_signals

    // Set up the basic signals for the dcache interface in case of reset
    task rst_signals();
        if (dc_dr_if == null) begin
           `uvm_fatal("DCACHE_REF_MODEL", "Can't drive signals: no interface available.")
        end
        dcache_req_ready_q = '{0,0};  //TODO; implement ready decoupled logic if needed, for now ready array is all 1s or all 0s
        dcache_resp_valid_q = 0;
        wbuf_empty_q = 0;
        dcache_resp_q = '0;
    endtask : rst_signals

    task drive_signals();
        if (dc_dr_if == null) begin
           `uvm_fatal("DCACHE_REF_MODEL", "Can't drive signal: no interface available.")
        end
        for (int i = 0; i < HPDCACHE_NREQUESTERS; ++i) begin
            if (dcache_resp_q.sid == i) begin
                dc_dr_if.dcache_resp_valid[i]   <= dcache_resp_valid_q;
                dc_dr_if.dcache_resp[i]         <= dcache_resp_q;
            end
            else begin
                dc_dr_if.dcache_resp_valid[i]   <= '0;
                dc_dr_if.dcache_resp[i]         <= '0;
            end
        end
        dc_dr_if.dcache_req_ready   <= dcache_req_ready_q;
        dc_dr_if.wbuf_empty         <= wbuf_empty_q;
    endtask : drive_signals

    task load(core_dcache_trans req);
        hpdcache_req_addr_t alignment = ~0; // Set to all 1
        hpdcache_req_addr_t addr;
        alignment = alignment << ($clog2(HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS/8));
        addr = hpdcache_req_addr(req.dcache_req) & alignment;
        for (int i = 0; i < HPDCACHE_REQ_WORDS; i++) begin
            for (int j = 0; j < HPDCACHE_WORD_WIDTH/8; j++) begin
                req.dcache_resp.rdata[i] >>= 8;
                req.dcache_resp.rdata[i][HPDCACHE_WORD_WIDTH-1:HPDCACHE_WORD_WIDTH-8] = m_mem_model.read_byte(addr + (j + (i*8)));
                `uvm_info("DCACHE_REF_MODEL",
                    $sformatf("Read: [0x%h] from address: [0x%h]",
                        req.dcache_resp.rdata[i][HPDCACHE_WORD_WIDTH-1:HPDCACHE_WORD_WIDTH-8],
                        (addr + (j + (i*8)))),
                    UVM_DEBUG)
            end
        end
    endtask : load

    task store(core_dcache_trans req);
        hpdcache_req_addr_t alignment = ~0; // Set to all 1
        hpdcache_req_addr_t addr;
        alignment = alignment << ($clog2(HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS/8));
        addr = hpdcache_req_addr(req.dcache_req) & alignment;
        for (int i = 0; i < HPDCACHE_REQ_WORDS; i++) begin
            for (int j = 0; j < HPDCACHE_WORD_WIDTH/8; ++j) begin
                if (req.dcache_req.be[i][j])
                    m_mem_model.write_byte(addr + (j + (i*8)),
                                           req.dcache_req.wdata[0][7:0]);
                `uvm_info("debug_store", $sformatf("i: %0d, j: %0d, Addr: 0x%0h, Data: 0x%0h, wdata: 0x%0h", i, j, addr + (j + (i * 8)), req.dcache_req.wdata[0][7:0], req.dcache_req.wdata), UVM_DEBUG)
                req.dcache_req.wdata >>= 8;
            end
        end
    endtask : store

    // Method to load in atomic instructions
    task load_amo(core_dcache_trans req);
        int size_b = 2 ** req.dcache_req.size;
        if (size_b > HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS) // If size is bigger than the maximum size
            `uvm_fatal("DCACHE_REF_MODEL",
                $sformatf("Core sent invalid load size: %d", req.dcache_req.size))
        for (int i = 0; i < size_b; ++i) begin // Save the actual data in amo_data temporal variable to then operate with it.
            amo_data >>= 8;
            amo_data[HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS-1:HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS-8] = m_mem_model.read_byte(hpdcache_req_addr(req.dcache_req) + i);
        end
        amo_data >>= (HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS - (size_b * 8));
        load(req); // Do the actual load
    endtask : load_amo

    // Method to store in atomic instructions
    task store_amo(core_dcache_trans req);
        int size_b = 2 ** req.dcache_req.size;
        for (int i = 0; i < size_b; ++i) begin
            m_mem_model.write_byte(hpdcache_req_addr(req.dcache_req) + i, req_amo_data[7:0]);
            req_amo_data >>= 8;
        end
    endtask : store_amo

    task amo_sign_extend(core_dcache_trans req);
        int size_b = 2 ** req.dcache_req.size;
        logic signed [HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS-1:0] mask = 0;
        mask[HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS-1] = 1;
        mask >>>= ((HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS) - (size_b * 8));
        if (req_amo_data[(size_b * 8) - 1])
            req_amo_data |= mask;
        if (amo_data[(size_b * 8) - 1])
            amo_data |= mask;
    endtask : amo_sign_extend

    task get_req_amo_data(core_dcache_trans req);
        logic break_i = 0;
        int size_bits = (2 ** req.dcache_req.size) * 8;
        logic signed [HPDCACHE_WORD_WIDTH*HPDCACHE_REQ_WORDS-1:0] mask = (2 ** size_bits) - 1;
        req_amo_data = req.dcache_req.wdata;
        for (int i = 0; i < HPDCACHE_REQ_WORDS; ++i) begin
            for (int j = 0; j < HPDCACHE_WORD_WIDTH/8; ++j) begin
                if (req.dcache_req.be[i][j]) begin
                    break_i = 1;
                    break;
                end
                else begin
                    req_amo_data >>= 8;
                end
            end
            if (break_i)
                break;
        end
        req_amo_data &= mask;
    endtask : get_req_amo_data

endclass : core_dcache_ref_model

`endif
