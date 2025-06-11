set_db  init_lib_search_path /path/to/pdk
set_db library /path/to/lib_file
set_db lef_library /path/to/lef_file
read_qrc /path/to/tch_file
set_db script_search_path proj_dir
set_db init_hdl_search_path proj_dir/picorv32
read_hdl picorv32.v
elaborate picorv32
check_design
write_netlist -lec > proj_dir/output/elab.v
write_do_lec -top picorv32 -golden_design rtl -revised_design proj_dir/output/elab.v -log_file proj_dir/output/rtl_elab.lec.log > proj_dir/output/rtl_elab.do
read_sdc initial.sdc
set_db / .use_scan_seqs_for_non_dft false
check_timing_intent
syn_generic
write_netlist -lec > proj_dir/output/generic.v
write_do_lec -top picorv32 -golden_design proj_dir/output/elab.v -revised_design proj_dir/output/generic.v -log_file proj_dir/output/elab_generic.lec.log > proj_dir/output/elab_generic.do
syn_map
write_do_lec -top picorv32 -golden_design proj_dir/output/generic.v -revised_design proj_dir/output/fv_map -log_file proj_dir/output/generic_fvmap.lec.log > proj_dir/output/generic_fvmap.do
syn_opt
report_area > proj_dir/output/reports/area_report.txt
report_gates > proj_dir/output/reports/gates_report.txt
report_timing > proj_dir/output/reports/timing_report.txt
report_power > proj_dir/output/reports/power_report.txt
write_hdl > proj_dir/output/design.v
write_script > proj_dir/output/constraints.g
write_sdc > proj_dir/output/constraints.sdc
write_design picorv32 -innovus
