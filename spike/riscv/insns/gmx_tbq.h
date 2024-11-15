require_extension(EXT_XGMX);
uint64_t pos = p->get_csr( CSR_GMX_POS );

uint64_t encoded_pos = 0;
for(int i = 0; i < 32 ;i++){
  if ((pos >> i) & 0x01){
    encoded_pos = i;
    break;
  }
}

WRITE_RD(encoded_pos);