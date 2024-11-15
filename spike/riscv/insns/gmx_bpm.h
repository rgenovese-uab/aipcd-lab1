require_extension(EXT_XGMX);
uint64_t rs1_i = RS1;
uint64_t rs2_i = RS2;

int8_t dv_i[31], dv[31], dh;
uint64_t delta_o;

dh = ((rs1_i >> 62) & 0x01) - ((rs1_i >> 63) & 0x01);

for (uint64_t i = 0; i < 31; i++) 
{
  dv_i[i] = ((rs1_i >> (i*2)) & 0x01) - ((rs1_i >> (i*2+1)) & 0x01);
  dv[i]=0;
}

uint8_t eq[31];
uint64_t stop_pos = 64;

for (int64_t i = 31; i >= 0; i--)
{
  eq[i] = (rs2_i >> (2*i)) & 0x01;
  if ((rs2_i >> (2*i)) & 0x02) stop_pos = i;
}

#define MIN(a,b) (((a)<=(b))?(a):(b))

for (uint64_t i = 0; i < 31; i++)
{
  dv[i] = MIN(-eq[i],MIN(dv_i[i],dh))+1-dh;
  dh = MIN(-eq[i],MIN(dv_i[i],dh))+1-dv_i[i];
  if (i==stop_pos) break;
}

delta_o = 0;

for (uint64_t i = 0; i < 31; i++){
  if (dv[i]==1) delta_o |= 1ULL << (i*2);
  else if (dv[i]==-1) delta_o |= 1ULL << (i*2+1);
}

if (dh==1) delta_o |= 1ULL << 62;
else if (dh==-1) delta_o |= 1ULL << 63;

WRITE_RD(delta_o);