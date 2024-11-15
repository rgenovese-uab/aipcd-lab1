#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV64M
RVTEST_CODE_BEGIN

# Note that riscv_test has been modified to enable interrupts...

wfi_tag:
    addi x0, x0, 0
    beq x0, x0, wfi_tag

    RVTEST_PASS

    TEST_PASSFAIL

RVTEST_CODE_END

    .data
RVTEST_DATA_BEGIN
    TEST_DATA
RVTEST_DATA_END
