#include "spike.h"
#include <iostream>
#include <iomanip>

void print_core_state(core_state_t* core_state) {

    std::cout << std::hex << core_state->pc << " " <<
               std::hex << core_state->ins << " " <<
               std::hex << core_state->dst_value << " " <<
               std::hex << core_state->dst_num << " " <<
               std::hex << core_state->src1_value << " " <<
               std::hex << core_state->src1_num << " " <<
               std::hex << core_state->src2_value << " " <<
               std::hex << core_state->src2_num << " " <<
               std::hex << core_state->disasm << " " <<
               std::hex << core_state->exc_bit << " " <<
               std::hex << core_state->vaddr << " " <<
               std::hex << core_state->store_data << " " <<
               std::hex << core_state->csr.frm << " " <<
               std::hex << core_state->csr.fflags << " " <<
               std::hex << core_state->csr.trap_illegal << " " <<
            //   std::hex << core_state->csr.mcause << " " <<
            //   std::hex << core_state->csr.scause << " " <<
               std::endl;

}

int main(int argc, char **argv) {

    spike_wrapper* spike;

    int nargs = 2 + argc - 1;

    char** args = (char**)malloc((nargs)*sizeof(char*));

    spike = new spike_wrapper();
    spike->setup(argc, argv);
}
