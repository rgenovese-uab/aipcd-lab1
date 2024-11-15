# See LICENSE for license details.

#*****************************************************************************
# rem2.S
#-----------------------------------------------------------------------------
#
# Test 2 div units with rem instructions
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64U
RVTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Arithmetic tests
  #-------------------------------------------------------------

  li ra, 20
  li sp, 6
  rem a4,ra,sp
  li ra, -20
  remu t0,ra,sp
  li ra, -20
  li sp, -6
  remuw t1,ra,sp
  li ra, 0xfffffffffffff897
  li sp, 0
  remw t4,ra,sp
  TEST_CASE(11, a4, 2, li t3, 0;);
  TEST_CASE(12, t0, 2, li t3, 0;);
  TEST_CASE(13, t1, -20, li t3, 0;);
  TEST_CASE(14, t4, 0xfffffffffffff897, li t3, 0;);

  TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
