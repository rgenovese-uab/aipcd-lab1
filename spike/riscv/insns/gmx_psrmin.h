require_extension(EXT_XGMX);
int64_t suma = 0;
int64_t min_suma = 0;
int64_t min_pos = 0;
uint64_t delta = RS1;
for (int i = 0; i < 64 ;i+=2) {
  suma += ((delta >> i) & 0x01) - ((delta >> (i+1)) & 0x01);
  if (suma < min_suma){
    min_suma = suma;
    min_pos = i;
  }
}

min_suma = (min_suma & 0x00000000FFFFFFFF) | (min_pos << 32);

WRITE_RD(min_suma);