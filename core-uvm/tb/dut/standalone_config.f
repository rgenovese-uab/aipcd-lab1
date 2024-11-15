+define+CONF_HPDCACHE_REQ_WORDS=8
+define+CONF_HPDCACHE_WBUF_WORDS=1
+define+CONF_HPDCACHE_ACCESS_WORDS=8
+define+CONF_SARGANTANA_PHY_ADDR_SIZE=40
+define+CONF_HPDCACHE_PA_WIDTH=40


///////////FOR MEMORY WRAPPERS//////////////
+define+BIST_DEFINE_VH

// Specific to OpenPiton, width of the BIST.
// Data width from tap to individual ram.
+define+SRAM_WRAPPER_BUS_WIDTH=4

// data reg, specific to Cincoranch specs
+define+JTAG_DATA_REQ_WIDTH=192
+define+JTAG_DATA_RES_WIDTH=256

// generic BIST defines
+define+BIST_OP_WIDTH=4
+define+BIST_OP_READ=1
+define+BIST_OP_WRITE=2
+define+BIST_OP_WRITE_EFUSE=3
+define+BIST_OP_SHIFT_DATA=4
+define+BIST_OP_SHIFT_ADDRESS=5
+define+BIST_OP_SHIFT_ID=6
+define+BIST_OP_SHIFT_BSEL=7
///////////////////////////////////////////