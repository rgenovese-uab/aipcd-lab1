require_extension(EXT_XGMX);
uint64_t drs1 = RS1;
uint64_t drs2 = RS2;

uint64_t res = (RS1 & 0x3FFFFFFFFFFFFFFF) | RS2 << 62;

WRITE_RD(res);