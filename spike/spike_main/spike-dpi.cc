#include "spike.h"
#include <iostream>
#include <fstream>
#include "svdpi.h"

spike_wrapper *spike;

extern "C" void spike_setup(int argc, char* argv) {
    int nargs = 1 + argc;

    char** args = (char**)malloc((nargs)*sizeof(char*));

    if (args == NULL){
        std::cout << "Not enough memory, malloc failed" << std::endl;
        throw 12; // ENOMEM
    }

    if (argc < 1) {
        printf("[SPIKE-DPI] Introduce at least a path to your binary.\n");
        return;
    }

    char* tmp = strtok(argv, " ");
    int i = 1;
    do {
     args[i] = tmp;
     std::cout << i << " " << tmp << std::endl;
     tmp = strtok(NULL, " ");
     ++i;
    }
    while (tmp != NULL);

    args[0] = (char*)"./spike";

    spike = new spike_wrapper();
    spike->setup(nargs, (const char**)args);
    setup_reduction("sim/build", spike->reduction_lanes, spike->reduction_fp_accums, spike->reduction_int_accums);

}

extern "C" void stop_execution() {
    free(spike);
}

extern "C" void start_execution() {
    spike->start_execution();
}

extern "C" void step(core_state_t* core_state) {
    spike->step(core_state);
}

extern "C" int run_and_inject(uint32_t instr, core_state_t* core_state){
    int error = 0;
    int exit_code;

    exit_code = spike->run_and_inject(instr, core_state);

    return exit_code;
}

extern "C" int exit_code(){
    return spike->s->exit_code();
}

extern "C" void set_tohost_addr(addr_t tohost_addr, addr_t fromhost_addr){
    return spike->s->set_tohost_addr(tohost_addr, fromhost_addr);
}

extern "C" void set_clearmip_addr(addr_t clearmip_addr){
    return spike->s->set_clearmip_addr(clearmip_addr);
}

extern "C" int get_memory_data(uint64_t* data, uint64_t address){
    return spike->load_uint(data, address);
}

extern "C" int set_memory_data(uint64_t address, long long unsigned int data, size_t size){
    processor_t* core = spike->s->get_core(0);
    try {
        auto prev_data = core->get_mmu()->load<uint8_t>( (addr_t) address);
        if (prev_data) // If it has smthg don't do anything
            return 0;
        switch(size){
            case  8:
                core->get_mmu()->store<uint8_t>( (addr_t) address, data);
            case 16:
                core->get_mmu()->store<uint16_t>( (addr_t) address, data);
            case 32:
                core->get_mmu()->store<uint32_t>( (addr_t) address, data);
            case 64:
                core->get_mmu()->store<uint64_t>( (addr_t) address, data);
            default:
                std::cout << "The size provided (" << size << ") is not valid" << std::endl;
        }
    }
    catch (...) { }
}

 extern "C" const char* disassemble_insn_str(uint64_t insn) {
     char* out;
     out = (char*) malloc(sizeof(char)*128);
     strcpy(out, spike->s->get_core(0)->get_disassembler()->disassemble(insn).c_str());
     return out;

}

extern "C" const void do_step(uint64_t n) {
     spike->s->step(n);
}

// From Andres interrupt support implementation
extern "C" void spike_set_external_interrupt(uint64_t mip_val) {
    spike->set_mip_ei(mip_val);
}

extern "C" uint64_t spike_get_csr(int csr){
    return spike->get_csr(csr);
}

extern "C" int spike_run_until_vector_ins(core_state_t* core_state){
    auto tmp = spike->run_until_vector_ins(core_state);
    return tmp;
}

extern "C" reg_t address_translate(reg_t addr, reg_t len, access_type type, reg_t satp, reg_t priv_lvl, reg_t mstatus, reg_t* exc_error){
    return spike->address_translate(addr, len, type, satp, priv_lvl, mstatus, exc_error);
}

extern "C" void get_src_vreg(const int reg_id, const svOpenArrayHandle vreg) {
    int count = svSize(vreg, 1);
    uint64_t *reg_base_addr;
    reg_base_addr = &((uint64_t*)spike->vector_reg_file)[reg_id*count];
    memcpy(svGetArrayPtr(vreg), reg_base_addr, svSizeOfArray(vreg));
}
extern "C" void get_dst_vreg(const int reg_id, const svOpenArrayHandle vreg) {
    int count = svSize(vreg, 1);
    uint64_t *reg_base_addr;
    processor_t* core = spike->s->get_core(0);
    reg_base_addr = &((uint64_t*)core->VU.reg_file)[reg_id*count];
    memcpy(svGetArrayPtr(vreg), reg_base_addr, svSizeOfArray(vreg));
}

extern "C" uint32_t spike_get_prv_lvl(){
    return spike->get_prv_lvl();
}

extern "C" void spike_set_csr_fflags(reg_t val){
    spike->set_csr_fflags(val);
}

extern "C" void spike_set_dest_reg_value(int reg_dst, reg_t value){
    fprintf(stderr, "Going Into Spike Set Timer Reg Function"  "\n\n");
    spike->set_dest_reg(reg_dst, value);
    fprintf(stderr, "Going Out from Spike Set Timer Reg Function" "\n\n");
}

extern "C" void spike_set_fp_reg_value(int reg_dst, reg_t value){
    spike->set_fp_reg(reg_dst, value);
}


extern "C" int get_mem_addr(const svOpenArrayHandle array) {
    processor_t* core = spike->s->get_core(0);
    memcpy(svGetArrayPtr(array), core->VU.mem_addr_array, svSizeOfArray(array));
    return svSizeOfArray(array);
}

extern "C" int get_mem_elem(const svOpenArrayHandle array) {
    processor_t* core = spike->s->get_core(0);
    memcpy(svGetArrayPtr(array), core->VU.mem_data_array, svSizeOfArray(array));
    return svSizeOfArray(array);
}

extern "C" bool is_vector(uint64_t instr) {
    return spike->is_vector(instr);
}

extern "C" reg_t spike_get_mstatus(){
    processor_t* core = spike->s->get_core(0);
    return core->get_state()->mstatus->read();
}

extern "C" reg_t spike_get_satp(){
    processor_t* core = spike->s->get_core(0);
    return core->get_state()->satp->read();
}

extern "C" void spike_plic_set_interrupt_level(int id, int level){
    if( spike->s->plic ){
        fprintf(stdout, "SETTING PLIC INTERRUPT LEVEL ID %d LEVEL %d\n", id, level );
        spike->s->plic->set_interrupt_level(id,level);
    }
}

extern "C" void spike_get_plic_enable(int context, const svOpenArrayHandle enable){
    if( spike->s->plic ){
        spike->s->plic->get_plic_enable( context, (uint32_t*)svGetArrayPtr(enable)) ;
    }
}

extern "C" void spike_clint_set_increment(int val){
    if( spike->s->clint ){
        fprintf(stdout, "INCREMENTING CLINT - VAL  %d\n", val );
        spike->s->clint->increment(val);
    }
}
