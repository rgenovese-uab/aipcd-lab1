require_extension(EXT_XGMX);
int64_t suma = 0;
uint64_t delta = RS1;
for (int i = 0; i < 64 ; i = i + 2) {
  suma += (int64_t)((delta >> i) & 0x01) - (int64_t)((delta >> (i+1)) & 0x01);
}

WRITE_RD(suma);