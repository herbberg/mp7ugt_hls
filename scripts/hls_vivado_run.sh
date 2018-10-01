#!/bin/bash
if [ "$1" == "-h" ]; then
  echo "Usage: `basename $0` l1menu_path l1menu_name vivado_version build_dir build_nr nr_modules"
  exit 0
fi
l1menu_path="$1"
echo $l1menu_path
l1menu_name="$2"
echo $l1menu_name
vivado_version="$3"
echo $vivado_version
build_dir="$4"
echo $build_dir
build="$5"
echo $build
nr_modules="$6"
echo $nr_modules
echo ""
echo "------------------"
cd
git clone https://github.com/herbberg/hls4gtl ~/$build_dir/$l1menu_name/hls4gtl
cd ~/$build_dir/$l1menu_name/hls4gtl
python manage.py init ~/$l1menu_path/$l1menu_name $nr_modules
python manage.py export
cd
git clone https://github.com/herbberg/mp7ugt_hls ~/$build_dir/$l1menu_name/mp7ugt_hls
python ~/$build_dir/$l1menu_name/mp7ugt_hls/scripts/makeProject.py -t mp7fw_v2_4_1 -u hbergaue -b 0x$build -m ~/$l1menu_path/$l1menu_name --hls ~/$build_dir/$l1menu_name/hls4gtl/hls_impl/solution1/impl/ip -p ~/$build_dir/$l1menu_name/work
cd ~/$build_dir/$l1menu_name/hls4gtl
vivado_hls -f run_hls.tcl
python ~/$build_dir/$l1menu_name/mp7ugt_hls/scripts/startSynth.py $vivado_version ~/$build_dir/$l1menu_name/work/mp7_ugt/0x$build/mp7fw_v2_4_1/build/build_0x$build.cfg --vivado_base_dir /opt/Xilinx/Vivado
