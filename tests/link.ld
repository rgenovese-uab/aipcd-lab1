/* Copyright 2018 Google LLC
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http:*www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
  . = 0x80000000;           /* Program starts at 0x80000000 */
  .text.init : { *(.text.init) }
  _start = .;
  ._start : { *(.text._start) }
  . = ALIGN(0x1000);
  .text : { *(.text) }
  .page_table : { *(.page_table) }
  . = ALIGN(0x1000);
  .main : { *(.main) }
  . = ALIGN(0x1000);
  .tohost : { *(.tohost) }
  .fromhost : { *(.fromhost) }
  . = ALIGN(0x1000);
  .data :
  {
    __DATA_BEGIN__ = .;
    *(.data .data.* .gnu.linkonce.d.*)
    SORT(CONSTRUCTORS)
  }
  . = ALIGN(0x1000);
  .user_stack : { *(.user_stack) }
  .kernel_data : { *(.kernel_data) }
  .kernel_stack : { *(.kernel_stack) }
  . = ALIGN(0x1000);
  .sdata :
  {
    __SDATA_BEGIN__ = .;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata .srodata.*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  }
  . = ALIGN(0x1000);
  __bss_start = .;
  .bss : { *(.bss) }
  __BSS_END__ = .;
  
  /* Define a stack section */
  . = ALIGN(0x1000);
  __stack_start = .;
  .stack : {
    . += 0x10000; /* Define a 64KB stack */
  }
  __stack_end = .;

  /* Define global pointer and end */
  __global_pointer$ = MIN(__SDATA_BEGIN__ + 0x800,
                          MAX(__DATA_BEGIN__ + 0x800, __BSS_END__ - 0x800));
  _end = .;
  PROVIDE(end = .);
}