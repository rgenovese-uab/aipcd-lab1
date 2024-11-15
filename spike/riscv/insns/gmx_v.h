require_extension(EXT_XGMX);
uint64_t pat = p->get_csr( CSR_GMX_P );

uint64_t a_mask = 0;
uint64_t c_mask = 0;
uint64_t g_mask = 0;
uint64_t t_mask = 0;
for ( int i = 0; i < 32; i++ ) {
  uint64_t pat_char = ( pat >> ( i * 2 ) ) & 3;
  switch( pat_char ) {
    case 0 : a_mask = a_mask | ( 1ul << i ); break;
    case 1 : c_mask = c_mask | ( 1ul << i ); break;
    case 2 : g_mask = g_mask | ( 1ul << i ); break;
    case 3 : t_mask = t_mask | ( 1ul << i ); break;
  }
}

uint64_t txt = p->get_csr( CSR_GMX_T );

uint64_t delta_v = RS1;
uint64_t delta_h = RS2;

uint64_t ph_in_v = 0;
uint64_t mh_in_v = 0;
for ( int i = 0; i < 32; i++ ) {
  ph_in_v = ph_in_v | ( ( delta_h & 1 ) << i );
  delta_h = delta_h >> 1;
  mh_in_v = mh_in_v | ( ( delta_h & 1 ) << i );
  delta_h = delta_h >> 1;
}

uint64_t pv = 0;
uint64_t mv = 0;
for ( int i = 0; i < 32; i++ ) {
  pv = pv | ( ( delta_v & 1 ) << i );
  delta_v = delta_v >> 1;
  mv = mv | ( ( delta_v & 1 ) << i );
  delta_v = delta_v >> 1;
}

for ( int i = 0; i < 32; i++ ) {
  uint64_t txt_char = ( txt >> ( i * 2 ) ) & 3;
  uint64_t mask;
  switch( txt_char ) {
    case 0 : mask = a_mask; break;
    case 1 : mask = c_mask; break;
    case 2 : mask = g_mask; break;
    case 3 : mask = t_mask; break;
  }

  uint64_t ph_in = ( ph_in_v >> i ) & 1;
  uint64_t mh_in = ( mh_in_v >> i ) & 1;

  uint64_t xv = mask | mv;
  if ( mh_in == 1 ) {
    mask = mask | 1;
  }
  uint64_t xh = ( ( ( ( mask & pv ) + pv ) ^ pv ) | mask ) & 0x00000000FFFFFFFF;
  uint64_t ph = mv | ~( xh | pv );
  uint64_t mh = pv & xh;

  ph = ph << 1;
  mh = mh << 1;

  if ( mh_in == 1 ) {
    mh = mh | 1;
  }
  if ( ph_in == 1 ) {
    ph = ph | 1;
  }

  pv = mh | ~( xv | ph );
  mv = ph & xv;
}

delta_v = 0;
for ( int i = 0; i < 32; i++ ) {
  delta_v = delta_v << 1;
  delta_v = delta_v | ( ( mv >> ( 31 - i ) ) & 1ul );
  delta_v = delta_v << 1;
  delta_v = delta_v | ( ( pv >> ( 31 - i ) ) & 1ul );
}

WRITE_RD(sext_xlen(delta_v));