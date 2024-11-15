This is BSC's UVM environment for verification of RISC-V cores. It supports Sargantana, Lagarto Ka & Lagarto Ox. To run a test you need to first setup the environment.

Verification plan: [TODO: Link to nextcloud document]
Core specs: [TODO: Link to documents]

# Set-Up guide:

## 0: System setup
The following is needed:
* EDA tools: currently supports questasim (Siemens), with verilator support WiP. questasim binaries should be set in the path and the license accesible. In epi\* servers it can be done with `source /eda/Siemens/siemens.sh && /eda/Siemens/lic_siemens_eda.sh`
* Risc-V toolchain (gcc, objdump, etc.). In epi\* servers, it can be done with `module load riscv/1.0.0`
* Device tree compiler (dtc)
* It is highly recommended to setup a gitlab access token https://gitlab.bsc.es/-/profile/personal_access_tokens here, and set the variable `GITLAB_PERSONAL_TOKEN` with the token. File mk/tools/package_download_tokens.mk can be used for that. Some steps below won't work out of the box without that.

## 1: Repo setup

* UVM repo (this repo): `git clone git@gitlab-internal.bsc.es:hwdesign/verification/core-uvm.git && cd core-uvm`. The rest of commands assume you are inside the cloned core-uvm
* RTL repo: `make clone_rtl CORE_TYPE={sargantana|lagarto_ka|lagarto_ox}`
* Spike package: `make clone_spike`
* Tests pacakges: `make clone_tests_all`

To update the content of the RTL repo, you need to run `make update_rtl CORE_TYPE={sargantana|lagarto_ka|lagarto_ox}`, while for Spike and tests you simply run the same command as above.

The following command shows the current commits and versions of the tests: `make show_all`

## 2: Compilation

The main command is: `make compile_all CORE_TYPE={sargantana|lagarto_ka|lagarto_ox}`

Additional common Makefile variables are:
* GUI={1|0} (to later have access to signals during simulation)
* COVERAGE={enable|disable}
* ASSERTS={enable|disable}
* INTERRUPTS={enable|disable} 

## 3: Simulation
The main command is: `make run CORE_TYPE={sargantana|lagarto_ka|lagarto_ox} TEST=path/to/binary`

Same flags as above apply, and also:
* `SEED=value`. Needed to reproduce runs from CI. It is ignored for compilation
+ `UVM_VERBOSITY={UVM_NONE|UVM_LOW|UVM_HIGH|UVM_DEBUG` indicates the verbosity of the simulation log. UVM_HIGH is typically useful for debugging a failing test.

## 4: Combined compilation and simulation
Steps 3 & 4 can be combined by ommitting the Makefile target (i.e. compile_all and run), so `make CORE_TYPE=... TEST=...` will compile and simulate.

## 5: Using run.py

run.py is a script used for running test regressions mostly in CI UVM verification environment. It simplifies executing test suites and managing simulation options.
Key Options

    -r, --regress
    Choose a regression file (YAML) defining tests to run. Example:
    python3 run.py -r selected_tests_sargantana.yaml

    -t, --test
    Run a specific test binary. Example:
    python3 run.py --test tests/build/isa_tests_verilator/rv64ua-v-lrsc

    --gui
    Run the test in graphical mode to interact with the simulation environment.

    --coverage
    Enable code coverage collection during test execution.

    --wave
    Save waveforms for debugging.

    --seed
    Specify a seed for test randomization or use "random" for a new seed each time.

    -v, --uvm-verbosity
    Set UVM log verbosity (UVM_LOW, UVM_DEBUG, etc.).

Example Usage

    Run a test with coverage and waveforms:
    python3 run.py --test path/to/test --coverage --wave

    Run a full regression:
    python3 run.py -r selected_tests.yaml --coverage


## 6: Output files
4. Result_database for UCDB and WLF files (Using run.py OR Makefile):-
```
For Waveforms => vsim path_to_binary/binary_name.wlf
         e.g. => vsim sim/build/rv64ua-v-lrsc.wlf

For UCDBs     => vcover report -html path_to_binary/binary_name.ucdb
         e.g. => vcover report -html sim/build/rv64ua-v-lrsc.ucdb
                 firefox covhtmlreport/index.html
              => vsim path_to_binary/binary_name.ucdb
         e.g. => vsim sim/build/rv64ua-v-lrsc.ucdb
```

## 7: Additional makefile variables
The following variables can be used to customize further the simulation, although the default value is typically what is needed:
 * ADDR_SPACE: In the format used by spike, comma-separated list of tuples: base_addr:sie
 * BOOTROM_BIN: Path to the bootrom binary
 * RESET_VECTOR: Initial address to fetch after reset
 * RTLDIR: Path to the RTL repo

## 8: Repo structure
```
├── bootrom: Bootrom source
│   └── build: Bootrom binary
├── env: UVM environment
│   ├── memory_model: Memory model
│   ├── ref_model: Reference model (i.e. connection with spike)
│   ├── utils: Misc files (e.g. types definition, etc).
│   ├── uvm_agents: UVM agents for the multiple interfaces
│   │   ├── dcache_uvc: Dcache
│   │   ├── icache_uvc: Icache
│   │   ├── im_uvc: Instruction management (tracks fetch, commit and ROB flushes)
│   │   └── int_uvc: Interrupts
│   └── vpu: VPU sub-environment
├── mk: Makefile support files
│   ├── targets: filelist. TODO: remove
│   ├── tools: Git, and others
│   └── uvmt: Setup for compiling and simulating the UVM
├── py_modules: Auxiliary python code (used by run.py)
├── regress: Yaml files that configure the regressions
│   └── results: Results from executing a regression
├── rtl: RTL repo is cloned here
├── script: Auxiliary scripts
│   └── py_modules: Auxiliary python scripts
├── sim/build: Output folder when not executing a regression
├── tb: UVM Testbench
│   ├── dut: DUT specific files (dut_pkg with parameters, filelists...)
│   │   └── checkers: Implementation of SV checkers with assertions and functional coverage
│   └── uvmt: UVM Testbench files
├── tests
│   ├── build: Pre-build binaries. Files downloaded with `make clone_tests*` are placed here
│   ├── src: C/Asm Source files for some binaries
│   └── verif_tests: SV tests
└── vendor: Pre-compiled libraries needed by the UVM
    ├── elfloader: elf loader
    └── spike: spike.so. Files downloaded with `make clone_spike` are placed here
        └── lib: Includes the dtb.dat, the device tree used in simulation by spike
```
