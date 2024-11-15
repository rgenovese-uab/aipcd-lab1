import core_uvm_pkg::*;

module boot_rom(
    input           i_clk,
    input           i_rsn,
    brom_if         brom_if,
    input [63:0]    i_rst_addr
);

    localparam ADDR_WIDTH = 64;
    localparam DATA_WIDTH = 128;

    typedef enum{
        wait_req,
        delay,
        send_resp
    } state_t;


    core_mem_model#(ADDR_WIDTH, DATA_WIDTH) mem;
    state_t         state, next_state;
    logic [3:0]     cnt, next_cnt;
    logic [23:0]    req_addr;

    always_ff @( posedge i_clk )
    if( ~i_rsn ) 
        state <= wait_req;
    else
        state <= next_state;

    always_ff @( posedge i_clk )
    if( ~i_rsn ) 
        req_addr <= '0;
    else if( brom_if.req.ready && brom_if.req.valid )
        req_addr <= brom_if.req.addr;

    always_ff @( posedge i_clk )
    if( ~i_rsn ) 
        cnt <= '0;
    else if( state==delay )
        cnt <= cnt - 1'b1;
    else
        cnt <= next_cnt;


    always_comb
    begin
        brom_if.req.ready       = 1'b0;
        brom_if.resp.valid      = 1'b0;
        brom_if.resp.bits_data  = '0;
        next_cnt                = '0;

        unique case( state )
            wait_req:
            begin
                brom_if.req.ready       = 1'b1;
                brom_if.resp.valid      = 1'b0;
                brom_if.resp.bits_data  = '0;
                if( brom_if.req.valid ) begin
                    next_state          = delay; 
                    next_cnt            = $urandom_range(0,5);
                end
                else begin
                    next_state          = wait_req;
                end
            end
            delay:
            begin
                brom_if.req.ready       = 1'b0;
                brom_if.resp.valid      = 1'b0;
                brom_if.resp.bits_data  = '0;
                if( cnt == '0 )
                    next_state          = send_resp;
                else
                    next_state          = delay;
            end
            send_resp:
            begin
                brom_if.req.ready       = 1'b0;
                brom_if.resp.valid      = 1'b1;
                brom_if.resp.bits_data  = mem.read32(req_addr);
                next_state              = wait_req;
            end
        endcase // state
    end

endmodule
