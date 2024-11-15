set dut [find instances -recursive -bydu dut_wrapper -nodu]
log -r /*
if {$dut ne ""} {
#add wave -group "LANE1" $dut/multi_lane_instance[1]/VECTOR_LANE_inst/*
}
