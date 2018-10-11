#!/usr/bin/env python2
# -*- coding: utf-8 -*-

import toolbox as tb
import mp7patch

import argparse
import urllib
import shutil
import logging
from distutils.dir_util import copy_tree
import subprocess
import ConfigParser
import sys, os

EXIT_SUCCESS = 0
EXIT_FAILURE = 1

# Set correct FW_TYPE and BOARD_TYPE for each project!
FW_TYPE = 'ugt'
BOARD_TYPE = 'mp7'

BoardAliases = {
    'mp7_690es': 'r1',
    'mp7xe_690': 'xe',
}

DefaultBoardType = 'mp7xe_690'
"""Default board type to be used."""

DefaultFirmwareDir = os.path.expanduser("~/work_vivado_hls/fwdir")
"""Default output directory for firmware builds."""
DefaultMp7FwTag = 'mp7fw_v2_4_1'

# Some other paths.
scripts_dir = os.path.dirname(os.path.abspath(__file__))
firmware_dir = os.path.abspath(os.path.join(scripts_dir, '..', 'firmware'))

# Target VHDL package and it's template must be defined.
TARGET_PKG_TPL = os.path.join(firmware_dir, 'hdl', 'gt_mp7_top_pkg_tpl.vhd')
TARGET_PKG = os.path.join(firmware_dir, 'hdl', 'gt_mp7_top_pkg.vhd')

Tcl_addHlsIpCore = 'addHlsIpCore.tcl'

def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser()
    parser.add_argument('-t', '--tag', metavar='<tag>', default=DefaultMp7FwTag, help="mp7fw tag")
    parser.add_argument('--board', metavar='<type>', default=DefaultBoardType, choices=BoardAliases.keys(), help="set board type (default is {})".format(DefaultBoardType))
    parser.add_argument('-p', '--path', metavar='<path>', required=True, type=os.path.abspath, help="fw build path")
    parser.add_argument('-m', '--menu', metavar='<menu>', required=True, type=os.path.abspath, help="path to L1Menu_ directory")
    parser.add_argument('-b', '--build', metavar='<version>', required=True, type=tb.build_t, help='menu build version (eg. 0x1001)')
    parser.add_argument('--tclfile', default=Tcl_addHlsIpCore, help="file name tcl script for HLS IP core")
    parser.add_argument('--hls', metavar='<path>', required=True, help='path to HLS IP')
    return parser.parse_args()

def main():
    """Main routine."""

    # Parse command line arguments.
    args = parse_args()

    # Setup console logging
    logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.DEBUG)

    # Compile build root directory
    project_type = "{}_{}".format(BOARD_TYPE, FW_TYPE)
    build_name = "0x{}".format(args.build)
    build_root = os.path.join(args.path, project_type, build_name)

    if os.path.isdir(build_root):
        raise RuntimeError("build area alredy exists: {}".format(build_root))

    # Fetch menu name from path.
    menu_name = os.path.basename(args.menu)

    if not menu_name.startswith('L1Menu_'):
        raise RuntimeError("Invalid menu name: {}".format(menu_name))

    # Fetch number of menu modules.
    modules = tb.count_modules(args.menu)

    if not modules:
        raise RuntimeError("Menu contains no modules")

    logging.info("Creating uGT build area...")
    logging.info("tag: %s (%s)", args.tag, "stable")
    #logging.info("user: %s", args.user)
    logging.info("path: %s", build_root)
    logging.info("menu file: %s", args.menu)
    logging.info("menu name: %s", menu_name)
    logging.info("menu modules: %s", modules)
    logging.info("build: 0x%s", args.build)
    logging.info("board type: %s", args.board)
    logging.info("tcl name: %s", args.tclfile)
    logging.info("HLS path: %s", args.hls)

    if not os.path.isdir(args.menu):
        raise RuntimeError("menu directory does not exist: {}".format(args.menu))

    # MP7 tag path inside build root directry.
    mp7path = os.path.join(build_root, args.tag)

    #
    # Create build area
    #
    logging.info("creating directory %s", mp7path)
    os.makedirs(mp7path)

    # Check out mp7fw
    os.chdir(mp7path)

    os.system('git clone https://github.com/herbberg/mp7fw_v2_4_1 {mp7path}'.format(**locals()))
    
    # Patching top VHDL
    
    logging.info("patch the target package with current UNIX timestamp/username/hostname...")
    subprocess.check_call(['python', os.path.join(scripts_dir, 'pkgpatch.py'), '--build', args.build ,TARGET_PKG_TPL, TARGET_PKG])

    #
    #  Creating build areas
    #
    logging.info("creating build areas...")
    build_area_dir = 'build'

    # Create build directory for fw synthesis...
    project_dir = os.path.abspath(os.path.join(build_area_dir, menu_name))
    os.makedirs(project_dir)

    # Do for every module of the menu...
    for module_id in range(modules):
        module_name = 'module_{}'.format(module_id)
        module_dir = os.path.join(project_dir, module_name)
        local_fw_dir = os.path.abspath(os.path.join(module_dir, 'mp7_ugt'))

        # Creat module build area
        os.makedirs(local_fw_dir)

        # Copy sources to module build area
        copy_tree(os.path.join(firmware_dir, 'cfg'), os.path.join(local_fw_dir, 'firmware', 'cfg'))
        copy_tree(os.path.join(firmware_dir, 'hdl'), os.path.join(local_fw_dir, 'firmware', 'hdl'))
        copy_tree(os.path.join(firmware_dir, 'ngc'), os.path.join(local_fw_dir, 'firmware', 'ngc'))
        copy_tree(os.path.join(firmware_dir, 'ucf'), os.path.join(local_fw_dir, 'firmware', 'ucf'))

        # Read generated VHDL snippets
        src_dir = os.path.join(args.menu, 'vhdl', module_name, 'src')

        gtl_fdl_wrapper_dir = os.path.join(local_fw_dir, 'firmware', 'hdl', 'gt_mp7_core', 'gtl_fdl_wrapper')
        gtl_dir = os.path.join(gtl_fdl_wrapper_dir, 'gtl')
        fdl_dir = os.path.join(gtl_fdl_wrapper_dir, 'fdl')

        # Copy constants_pkg.vhd from "menu" (HLS)
        shutil.copyfile(os.path.join(src_dir, 'constants_pkg.vhd'), os.path.join(gtl_dir, 'constants_pkg.vhd'))

        # Run project manager
        subprocess.check_call(['python', 'ProjectManager.py', 'vivado', local_fw_dir, '-w', module_dir])

        #
        # Create TCL file for adding HLS IP core into Vivado IP catalog
        #
        os.chdir(module_dir)
        #set_prop = "set_property ip_repo_paths %s", args.hls, "[current_project]\n"
        hls_ip_file = open(args.tclfile,"w")
        hls_ip_file.write("open_project top/top.xpr\n")
        hls_ip_file.write("set_property ip_repo_paths ")
        hls_ip_file.write(args.hls)
        hls_ip_file.write(" [current_project]\n")
        hls_ip_file.write("update_ip_catalog\n")
        hls_ip_file.write("create_ip -name algos -library hls -version 1.0 -module_name algos_0\n")
        hls_ip_file.write("generate_target {instantiation_template} [get_files top/top.srcs/sources_1/ip/algos_0/algos_0.xci]\n")
        hls_ip_file.write("generate_target all [get_files top/top.srcs/sources_1/ip/algos_0/algos_0.xci]\n")
        hls_ip_file.write("catch { config_ip_cache -export [get_ips -all algos_0] }\n")
        hls_ip_file.write("generate_target all [get_files top/top.srcs/sources_1/ip/algos_0/algos_0.xci] \n")
        hls_ip_file.write("export_ip_user_files -of_objects [get_files top/top.srcs/sources_1/ip/algos_0/algos_0.xci] \n")
        hls_ip_file.write("create_ip_run [get_files -of_objects [get_fileset sources_1] top/top.srcs/sources_1/ip/algos_0/algos_0.xci] \n")
        hls_ip_file.write("launch_runs -jobs 14 algos_0_synth_1\n")
        hls_ip_file.write("exit\n")
        hls_ip_file.close()
        
    # Go to build area root directory.
    os.chdir(mp7path)
    os.chdir(build_area_dir)

    # Creating configuration file.
    config = ConfigParser.RawConfigParser()
    config.add_section('environment')
    config.set('environment', 'timestamp', tb.timestamp())
    config.set('environment', 'hostname', tb.hostname())
    config.set('environment', 'username', tb.username())

    config.add_section('menu')
    config.set('menu', 'build', args.build)
    config.set('menu', 'name', menu_name)
    config.set('menu', 'location', args.menu)
    config.set('menu', 'modules', modules)

    config.add_section('firmware')
    config.set('firmware', 'tag', args.tag)
    #config.set('firmware', 'stable', str(not args.unstable))
    config.set('firmware', 'type', FW_TYPE)
    config.set('firmware', 'buildarea', os.path.join(mp7path, build_area_dir, menu_name))

    config.add_section('device')
    config.set('device', 'type', args.board)
    config.set('device', 'name', BOARD_TYPE)
    config.set('device', 'alias', BoardAliases[args.board])

    # Writing our configuration file to 'example.cfg'
    with open('build_0x{}.cfg'.format(args.build), 'wb') as fp:
        config.write(fp)

    logging.info("finished with success.")

if __name__ == '__main__':
    try:
        main()
    except RuntimeError, message:
        logging.error(message)
        sys.exit(EXIT_FAILURE)
    sys.exit(EXIT_SUCCESS)
