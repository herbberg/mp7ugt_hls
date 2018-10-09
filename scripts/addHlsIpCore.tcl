open_project top/top.xpr
set_property ip_repo_paths /home/bergauer/work_vivado_hls/hls4gtl/solution1/impl/ip [current_project]
update_ip_catalog
create_ip -name algos -vendor HEPHY-CMS-L1GT -library hls -version 1.0 -module_name algos_0
generate_target {instantiation_template} [get_files top/top.srcs/sources_1/ip/algos_0/algos_0.xci]
generate_target all [get_files top/top.srcs/sources_1/ip/algos_0/algos_0.xci]
catch { config_ip_cache -export [get_ips -all algos_0] }
generate_target all [get_files top/top.srcs/sources_1/ip/algos_0/algos_0.xci] 
export_ip_user_files -of_objects [get_files top/top.srcs/sources_1/ip/algos_0/algos_0.xci] 
create_ip_run [get_files -of_objects [get_fileset sources_1] top/top.srcs/sources_1/ip/algos_0/algos_0.xci] 
launch_runs -jobs 14 algos_0_synth_1
exit
