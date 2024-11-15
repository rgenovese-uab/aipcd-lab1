require_extension(EXT_XGMX);
uint64_t p_i = p->get_csr( CSR_GMX_P );
uint64_t t_i = p->get_csr( CSR_GMX_T );
uint64_t dv_i = RS1;
uint64_t dh_i = RS2;
uint64_t tb_pos_i = p->get_csr( CSR_GMX_POS );

uint64_t dvp[33], dvn[33], dhp[33], dhn[33];
uint64_t eq[33];

for (uint64_t i = 0; i <= 32; i++)
{
    dvn[i] = 0;
    dvp[i] = 0;
    dhn[i] = 0;
    dhp[i] = 0;
    eq[i] = 0;
}

for (uint64_t i = 1; i <= 32; i++){
    for (uint64_t j = 1; j <= 32; j++){
    eq[i] |= ((((p_i >> 2*(i-1)) & 3ULL) == ((t_i >> 2*(j-1)) & 3ULL)) & 1ULL) << j; 
    }
}

for (uint64_t i = 1; i <= 32; i++)
{
    dhn[0] |= (( dh_i >> (2*(i-1)+1)) & 1ULL) << i;
    dhp[0] |= (( dh_i >> (2*(i-1))) & 1ULL) << i;
    dvn[i] |= (( dv_i >> (2*(i-1)+1)) & 1ULL);
    dvp[i] |= (( dv_i >> (2*(i-1))) & 1ULL);
}

for (uint64_t i = 1; i <= 32; i++)
{
    for (uint64_t j = 1; j <= 32; j++)
    {
        dvn[i] |= (((((dvn[i] >> (j-1) ) & 1ULL) | (eq[i] >> j & 1ULL)) & ((dhp[i-1] >> j) & 1ULL)) & 1ULL) << j;
        dvp[i] |= ((((dhn[i-1] >> j) & 1ULL) | (!(((dvn[i] >> (j-1) ) & 1ULL) || (eq[i] >> j & 1ULL)) & !((dhp[i-1] >> j) & 1ULL)) ) & 1ULL) << j;
        dhn[i] |= (((((dhn[i-1] >> j) & 1ULL)  | (eq[i] >> j & 1ULL)) & ((dvp[i] >> (j-1) ) & 1ULL)) & 1ULL) << j;
        dhp[i] |= ((((dvn[i] >> (j-1) ) & 1ULL) | (!(((dhn[i-1] >> j) & 1ULL)  | (eq[i] >> j & 1ULL)) & !((dvp[i] >> (j-1) ) & 1ULL)) ) & 1ULL) << j;
    }
}

uint64_t v;
uint64_t h;
uint64_t init_pos = 0;
uint64_t char_pos;
uint64_t alig_hi = 0;
uint64_t alig_lo = 0;
uint64_t tb_pos_o = 0;

for(int i = 0; i < 32; i++){
    if ((tb_pos_i >> i) & 1) init_pos = i;
}
if (tb_pos_i >> 32){
    v = 32;
    h = init_pos + 1;
}else{
    v = init_pos + 1;
    h = 32;
}

char_pos = init_pos + 31;

while(v > 0 && h > 0){
    if((dhp[v]>>h) & 1){
        // insertion
        if (char_pos >= 32){
            alig_hi |= 2ULL << (2*(char_pos - 32));
        }else{
            alig_lo |= 2ULL << (2*char_pos);
        }
        h--;
        char_pos--;
    }else if((dvp[v]>>h) & 1){
        // Deletion
        if (char_pos >= 32){
            alig_hi |= 3ULL << (2*(char_pos - 32));
        }else{
            alig_lo |= 3ULL << (2*char_pos);
        }
        v--;
        char_pos--;
    }else if((eq[v]>>h) & 1){
        // match
        if (char_pos >= 32){
            alig_hi |= 1ULL << (2*(char_pos - 32));
        }else{
            alig_lo |= 1ULL << (2*char_pos);
        }
        h--; v--;
        char_pos-=2;
    } else {  // mismatch
        h--; v--;
        char_pos-=2;
    } 
}
if (v == 0 && h == 0){
    tb_pos_o |= 1ULL << 31;
    alig_hi |= 2ULL << 62;
}else if(v == 0){
    tb_pos_o |= 1ULL << (h-1);
    tb_pos_o |= 1ULL << 32;
    alig_hi |= 1ULL << 62;
}else{
    tb_pos_o |= 1ULL << (v-1);
}

p->put_csr( CSR_GMX_POS, tb_pos_o );
p->put_csr( CSR_GMX_TB_LO, alig_lo );
p->put_csr( CSR_GMX_TB_HI, alig_hi );

WRITE_RD( alig_hi );