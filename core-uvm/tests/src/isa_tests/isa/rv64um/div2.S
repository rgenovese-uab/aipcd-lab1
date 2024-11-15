# See LICENSE for license details.

#*****************************************************************************
# div2.S
#-----------------------------------------------------------------------------
#
# Test 2 div units
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64U
RVTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Arithmetic tests
  #-------------------------------------------------------------

  li ra, -20 << 32 >> 32
  li sp, 6
  divuw t1,ra,sp
  li ra, 20
  li sp, 6
  div a4,ra,sp
  li ra, -20
  divu t0,ra,sp
  li ra, -20
  li sp, -6
  divw t4,ra,sp
  TEST_CASE(11, a4, 3, li t3, 0;);
  TEST_CASE(12, t0, 3074457345618258599, li t3, 0;);
  TEST_CASE(13, t1, 715827879, li t3, 0;);
  TEST_CASE(14, t4, 3, li t3, 0;);

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
