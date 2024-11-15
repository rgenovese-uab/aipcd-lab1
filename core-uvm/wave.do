onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -subitemconfig {/top_tb/ka_th/dtlb/cache_tlb_comm_i.req -expand} /top_tb/ka_th/dtlb/cache_tlb_comm_i
add wave -noupdate /top_tb/ka_th/dtlb/cache_tlb_comm_i.req.vpn
add wave -noupdate -expand -subitemconfig {/top_tb/ka_th/dtlb/tlb_cache_comm_o.resp -expand /top_tb/ka_th/dtlb/tlb_cache_comm_o.resp.xcpt -expand} /top_tb/ka_th/dtlb/tlb_cache_comm_o
add wave -noupdate /top_tb/ka_th/dtlb/ptw_tlb_comm_i
add wave -noupdate /top_tb/ka_th/dtlb/tlb_ptw_comm_o
add wave -noupdate -expand /top_tb/ka_th/datapath_inst/resp_icache_cpu_i
add wave -noupdate -expand /top_tb/ka_th/datapath_inst/req_cpu_icache_o
add wave -noupdate /top_tb/ka_th/datapath_inst/clk_i
add wave -noupdate /top_tb/ka_th/datapath_inst/rstn_i
add wave -noupdate /top_tb/ka_th/datapath_inst/reset_addr_i
add wave -noupdate /top_tb/ka_th/datapath_inst/soft_rstn_i
add wave -noupdate /top_tb/ka_th/clock_if/clk
add wave -noupdate /top_tb/ka_th/clock_if/rsn
add wave -noupdate /top_tb/ka_th/clock_if/clk
add wave -noupdate /top_tb/ka_th/reset_if/rsn
add wave -noupdate /top_tb/ka_th/brom_req_address
add wave -noupdate /top_tb/ka_th/brom_req_valid
add wave -noupdate /top_tb/ka_th/brom_ready
add wave -noupdate /top_tb/ka_th/brom_resp_data
add wave -noupdate /top_tb/ka_th/brom_resp_valid
add wave -noupdate /top_tb/ka_th/icache_interface_inst/is_brom_access
add wave -noupdate /top_tb/ka_th/icache_interface_inst/en_translation_i
add wave -noupdate /top_tb/ka_th/icache_interface_inst/req_fetch_icache_i.vaddr
add wave -noupdate /top_tb/ka_th/icache_interface_inst/csr_spi_config_i
add wave -noupdate -expand /top_tb/ka_th/datapath_inst/commit_valid
add wave -noupdate -expand -subitemconfig {{/top_tb/ka_th/datapath_inst/commit_data[0]} -expand} /top_tb/ka_th/datapath_inst/commit_data
add wave -noupdate /top_tb/ka_th/datapath_inst/store_addr
add wave -noupdate /top_tb/ka_th/datapath_inst/store_data
add wave -noupdate /top_tb/ka_th/ic_if/icache_resp
add wave -noupdate /top_tb/ka_th/ic_if/lagarto_ireq
add wave -noupdate /top_tb/ka_th/ic_if/iflush
add wave -noupdate /top_tb/ka_th/ic_if/csr_en_translation
add wave -noupdate /top_tb/ka_th/ic_if/csr_status
add wave -noupdate /top_tb/ka_th/ic_if/csr_satp
add wave -noupdate /top_tb/ka_th/ic_if/csr_priv_lvl
add wave -noupdate -expand /top_tb/ka_th/dcache_interface_inst/req_cpu_dcache_i
add wave -noupdate /top_tb/ka_th/dcache_interface_inst/resp_dcache_cpu_o
add wave -noupdate /top_tb/ka_th/dcache_interface_inst/dcache_ready_i
add wave -noupdate /top_tb/ka_th/dcache_interface_inst/dcache_valid_i
add wave -noupdate /top_tb/ka_th/dcache_interface_inst/core_req_valid_o
add wave -noupdate -expand /top_tb/ka_th/dcache_interface_inst/req_dcache_o
add wave -noupdate /top_tb/ka_th/dcache_interface_inst/rsp_dcache_i
add wave -noupdate /top_tb/ka_th/dcache_interface_inst/wbuf_empty_i
add wave -noupdate -expand /top_tb/ka_th/dc_if/dcache_resp_valid
add wave -noupdate /top_tb/ka_th/dc_if/dcache_req_ready
add wave -noupdate -expand /top_tb/ka_th/dc_if/dc_mon_cb/dcache_req_valid
add wave -noupdate /top_tb/ka_th/dc_if/dc_mon_cb/dcache_req_ready
add wave -noupdate -expand -subitemconfig {{/top_tb/ka_th/dc_if/dc_mon_cb/dcache_req[1]} -expand} /top_tb/ka_th/dc_if/dc_mon_cb/dcache_req
add wave -noupdate /top_tb/ka_th/dc_if/dc_mon_cb/dcache_resp_valid
add wave -noupdate /top_tb/ka_th/dc_if/dc_mon_cb/dcache_resp
add wave -noupdate /top_tb/ka_th/dc_if/dc_mon_cb/wbuf_empty
add wave -noupdate /top_tb/ka_th/dtlb/bad_va
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {315182 ps} 0} {Trace {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 346
configure wave -valuecolwidth 132
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {312534 ps} {325466 ps}
