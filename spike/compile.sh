#!/bin/bash
PROJECT_PATH="$PWD"
INFO_FILE=${PROJECT_PATH}/build/spike.info
COMMIT_URL="https://gitlab.bsc.es/hwdesign/verification/spike/-/commit/"
JOB_URL="https://gitlab.bsc.es/hwdesign/verification/spike/-/jobs/"

function suppress { /bin/rm --force /tmp/suppress.out 2> /dev/null; ${1+"$@"} > /tmp/suppress.out 2>&1 || cat /tmp/suppress.out; /bin/rm /tmp/suppress.out; }

usage() {
     echo "Usage:"
     echo "    ./compile.sh -h                      Display this help message."
     echo "    ./compile.sh -b BUILD                Sets the build type."
     echo "    ./compile.sh -v VLEN                Sets the default VLEN value."
     echo " "
     echo "             build types: debug dpi normal"
     exit 1
}

info() {    
    if [ -d ${PROJECT_PATH}/build ]; then
        if [ -f ${INFO_FILE} ]; then
            rm ${INFO_FILE}
        fi

        if [ -z "$CI_COMMIT_SHA" ]; then
            echo "Attention!! no CI_COMMIT_SHA to track"
            echo "  Attention!! no CI_COMMIT_SHA to track" >>${INFO_FILE}
        else
            echo "  Commit SHA: "${CI_COMMIT_SHA} >>${INFO_FILE}
            echo "  Commit url: "${COMMIT_URL}${CI_COMMIT_SHA} >>${INFO_FILE}
        fi

        if [ -z "$CI_JOB_ID" ]; then
            echo "Attention!! no CI_JOB_ID to track"
            echo "  Attention!! no CI_JOB_ID to track" >>${INFO_FILE}
        else
            echo "  Job url   : "${JOB_URL}${CI_JOB_ID} >>${INFO_FILE}
        fi

        echo "Sargantana Supported Vector Instructions: " >>${INFO_FILE}
        find ${PROJECT_PATH}/riscv/insns -type f -name 'v*' -exec grep -L "require(P.core_type != SARGANTANA);" {} + | xargs -I {} basename {} .h >>${INFO_FILE} 
        echo "Sargantana Unsupported Vector Instructions: " >>${INFO_FILE}
        find ${PROJECT_PATH}/riscv/insns -type f -name 'v*' -exec grep -l "require(P.core_type != SARGANTANA);" {} + | xargs -I {} basename {} .h >>${INFO_FILE}
    fi
}

old_build=$( cat build/build_type.log ) || true
target="epi"
vl_arg=16384

while getopts ":h:b:v:" opt; do
  case ${opt} in
    h )
        usage
        exit 0
        ;;
    b )
        build_type=$OPTARG
        ;;
    v )
        vl_arg=$OPTARG
        ;;
    \? )
        echo "Invalid Option: -$OPTARG" 1>&2
        usage
        exit 1
        ;;
    * )
        usage
        exit 0
        ;;
  esac
done

shift $((OPTIND -1))


varch="vlen:"${vl_arg}",elen:64"

echo "varch is ${vl_arg}"

if [[ "${build_type}" != "dpi" && "${build_type}" != "debug" && "${build_type}" != "normal" ]]; then
    usage
    exit 1
fi


if [[ ! -z $old_build ]]; then
    old_target=`echo "$old_build" | cut -d '/' -f 1 `
    old_build_type=`echo "$old_build" | cut -d '/' -f 2 `
fi

mkdir -p build
cd build

if [[ ! -e config.log ]];then
    vlen=$(echo "$varch" | cut -d ',' -f 1 | cut -d ':' -f 2)
    echo "../configure --with-isa=RV64IMAFD --with-varch=$varch --enable-commitlog --with-target=$vl_arg"
    ../configure --with-isa="RV64IMAFD" --with-varch=$varch --enable-commitlog --with-target=$vl_arg
    make clean
fi


if [[ "$old_build_type" != "$build_type" ]]; then
    make clean
fi


echo "################################"
echo "Target : $target"
echo "Build  : $build_type"
echo "################################"

if [[ "$build_type" == "dpi" ]] ; then
    export LD_FLAGS="-static"
    make -j 4 # $((`nproc`-1))
    FLAGS=" "
    obj_o=""
#    for i in ../spike_main/dpi/*
#    do
#        path_without_extension=$(echo "$i" | cut -d '.' -f 1)
#        g++ -fPIC -g -O3 -c $FLAGS $i -o ${path_without_extension}.o -I../spike_main -I. -I../riscv -I../softfloat -I../fesvr -I.. -I../vector_reductions/
#        obj_o="$obj_o ${path_without_extension}.o"
#    done

    g++ -std=c++17 -fPIC -g  -c $FLAGS ../spike_main/spike-dpi.cc -o spike-dpi.o -I../spike_main -I. -I../riscv -I../softfloat -I../fesvr -I.. -I../red_ref_model/
    g++ -std=c++17 -fPIC -g  -c $FLAGS ../spike_main/spike.cc -o spike.o -I../spike_main -I. -I../riscv -I../softfloat -I../fesvr -I.. -I../red_ref_model/
    g++ -std=c++17 -shared -static-libgcc -static-libstdc++ -fPIC -o spike.so \
        spike.o \
        disasm.o \
        regnames.o \
        fdt.o \
        fdt_strerror.o \
        fdt_ro.o \
        fdt_addresses.o \
        fdt_rw.o \
        fdt_wip.o \
        fdt_empty_tree.o \
        fdt_overlay.o \
        fdt_sw.o \
        spike-dpi.o \
        libspike_main.a libriscv.a libsoftfloat.a libred_ref_model.a libfesvr.a \
        $obj_o
    info
    exit
fi

if [[ "$build_type" == "debug" ]] ; then
    FLAGS="-DDEBUG"
    USER_CFLAGS="USER_CFLAGS=$FLAGS"
fi
make $USER_CFLAGS -j 4 # $((`nproc`-1)) 
# g++ -g -c ../spike_main/spike_main.cc -I. -I../riscv -I../softfloat -I../fesvr -I.. -I../vector_reductions/ $FLAGS
g++ -std=c++17 -L. -Wl,--export-dynamic -Wl,-rpath,/usr/local/lib -o spike  \
        spike.o \
        disasm.o \
        regnames.o \
        fdt.o \
        fdt_strerror.o \
        fdt_ro.o \
        fdt_addresses.o \
        fdt_rw.o \
        fdt_wip.o \
        fdt_empty_tree.o \
        fdt_overlay.o \
        fdt_sw.o \
        libspike_main.a libriscv.a libsoftfloat.a libred_ref_model.a libfesvr.a \
        $obj_o \
        -lpthread -ldl -lpthread #-lboost_regex
info
exit
