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
set_db / .dft_scan_style muxed_scan
set_db / .dft_prefix DFT_
set_db / .dft_identify_top_level_test_clocks true
set_db / .dft_identify_test_signals true
set_db / .dft_identify_internal_test_clocks false
set_db / .use_scan_seqs_for_non_dft false
set_db "design: picorv32" .dft_scan_top_mode_tdrc_pass
set_db "design:picorv32" .dft_connect_shift_enable_during_mapping tie_off
set_db "design:picorv32" .dft_connect_scan_data_pins_during_mapping loopback
set_db "design:picorv32" .dft_scan_output_preference auto
set_db "design:picorv32" .dft_lockup_element_type_preferred_level sensitive
set_db "design:picorv32" .dft_mix_clock_edges_in_scan_chains true
define_test_clock -name scanclk -period 20000 clk
define_shift_enable -name se -active high -create_port se
define_test_mode -name test_mode -active high -create_port test_mode
define_scan_chain -name top_chain -sdi scan_in -sdo scan_out -shift_enable se -create_ports
check_dft_rules > proj_dir/output/dft/dft_check.txt
report_scan_registers > proj_dir/output/dft/scan_reg.txt
report_scan_setup > proj_dir/output/dft/scan_setup.txt
read_sdc initial.sdc
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
check_dft_rules -advanced > proj_dir/output/dft/dft_check_advanced.txt
connect_scan_chains -auto_create_chains
report_scan_chains > proj_dir/output/dft/scan_chains.txt
report_scan_setup > proj_dir/output/dft/scan_setup_after.txt
write_scandef -scanDEF
write_dft_abstract_model
write_hdl -abstract
write_script -analyze_all_scan_chains
write_design picorv32 -innovus
